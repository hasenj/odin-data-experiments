package server

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:sync"
import "../socket"
import "../thread"

Server :: struct {
	socket: socket.handle,
    startedAt: time.Time,
    queue: [dynamic]^ClientConnection,
    connectionsCount: int,
    aio: aioList,
}


ClientConnection :: struct {
    server: ^Server,
	socket: socket.handle,
    startedAt: time.Time,
	incoming: [dynamic]byte,
	incomingCursor: int,
	header_end: int,
	header: HTTP_Request,
    header_valid: bool,

	outgoing: [dynamic]byte,
	outgoingCursor: int,

    processingDone: bool,
}

RemoveConnection :: proc(server: ^Server, conn: ^ClientConnection) {
    // maybe we should also put the index into the conn?
    for c, index in server.queue {
        if c == conn {
            unordered_remove(&server.queue, index);
            break;
        }
    }
    delete(conn.incoming);
    delete(conn.outgoing);
    aioRemoveReading(&conn.server.aio, conn.socket);
    aioRemoveWriting(&conn.server.aio, conn.socket);

    socket.shutdown(conn.socket, .RDWR);
    socket.close(conn.socket);

    sync.atomic_sub(&conn.server.connectionsCount, 1, .Relaxed);

    // this should be everything needed to remove it and clean the memory!
    // if we forgot anything here there could be a memory leak!
}


IsHeaderReceived :: proc(using conn: ^ClientConnection) -> bool {
	end_token :: "\r\n\r\n";
	index := strings.index(string(incoming[:incomingCursor]), end_token);
	if index != -1 {
		header_end = index + len(end_token);
		return true;
	}
	return false;
}

ParseHeader :: proc(using conn: ^ClientConnection) {
    header, header_valid = parse_http_request(string(conn.incoming[:conn.incomingCursor]));
}


try :: proc(msg: string, e: os.Errno) {
    if e != 0 {
        fmt.printf("[%d] %s: %s\n", context.thread_id, msg, os.strerror(e));
    }
}

panic_on :: proc(e: os.Errno) {
    if e != 0 {
        fmt.println(os.strerror(e));
        panic(fmt.aprint("[%d] system error: ", context.thread_id, os.strerror(e)));
    }
}

must :: proc(a: $T, b: os.Errno) -> T {
    panic_on(b);
    return a;
}

start :: proc(port: u16) -> int {
	fmt.println("Starting server on port", port);

    time.debug_timebase_info();

	sock := must(socket.socket());
    socket.set_option(sock, .REUSEADDR, 1);

    addr := socket.make_address(port);
	socket.bind(sock, &addr);

    socket.listen(sock, 10000);

    server := Server {
        socket = sock,
        startedAt = time.now_monotonic(),
    };
    reserve(&server.queue, 512);

    aioInit(&server.aio);
    aioAddReading(&server.aio, sock, &server);

    frameAccept :: proc(sock: socket.handle, udata: rawptr) {
        server := cast(^Server) udata;
        assert(server.socket == sock);
        clientAddr: socket.address;
        client_sock, err := socket.accept(sock, &clientAddr);
        if err != 0 {
            fmt.println("accept:", os.strerror(err));
            return;
        }
        conn := new(ClientConnection); // in the future, we can make a pool or something
        conn.server = server;
        conn.socket = client_sock;
        conn.incoming = make([dynamic]byte, 4 * 1024);
        conn.startedAt = time.now_monotonic();

        append(&server.queue, conn);
        aioAddReading(&server.aio, client_sock, conn);

        sync.atomic_add(&server.connectionsCount, 1, .Relaxed);
    }

    sever_socket := sock;

    frameRead :: proc(sock: socket.handle, udata: rawptr) {
        conn := cast(^ClientConnection) udata;
        assert(conn.socket == sock);
        received, err := socket.recv(conn.socket, conn.incoming[conn.incomingCursor:]);
        if err != 0 {
            // assume socket is closed or invalid, etc.
            RemoveConnection(conn.server, conn);
        }
        conn.incomingCursor += received;
    }

    frameWrite :: proc(sock: socket.handle, udata: rawptr) {
        conn := cast(^ClientConnection) udata;
        assert(conn.socket == sock);
        buf := conn.outgoing[conn.outgoingCursor:];
        if len(buf) > 0 {
            sent, err := socket.send(conn.socket, buf);
            if err != 0 {
                // assume socket is closed or invalid, etc.
                RemoveConnection(conn.server, conn);
            }
            conn.outgoingCursor += int(sent);
        } else {
            if conn.processingDone {
                RemoveConnection(conn.server, conn);
            }
        }
    }

    for {
        aioFrame(list = &server.aio, serverSocket = server.socket, acceptFn = frameAccept, readFn = frameRead, writeFn = frameWrite);
        // first, run the IO process
        // once IO is completed, do the processing!
        for conn in server.queue {
            if IsHeaderReceived(conn) {
                ParseHeader(conn);
                // for now there isn't any real processing once we parse the header, so let's not pretend otherwise
                content := "hello from odin with queues!!";
                conn.outgoing = make([dynamic]byte, 1024);
                b := strings.builder_from_slice(conn.outgoing[:]);
                fmt.sbprint(&b, "HTTP/1.1 200 OK\n");
                fmt.sbprintf(&b, "Content-Length: %d\n", len(content));
                fmt.sbprint(&b, "Connection: close\n");
                fmt.sbprint(&b, "\n");
                fmt.sbprint(&b, content);
                aioAddWriting(&server.aio, conn.socket, conn);
                conn.processingDone = true; // shut down connection once everything is written
            }
        }
    }

	return 0;
}
