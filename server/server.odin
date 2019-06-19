package server

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:sync"
import "../socket"
import "../thread"

Request_Buffer :: struct {
    buffer: [dynamic]byte,
    cursor: int,
    header_end: int,
    header: HTTP_Request,
}

concurrent_count := 0;

recv_http_header :: proc(using r: ^Request_Buffer, s: socket.handle) -> bool {
    for {
        count, err := socket.recv(s, buffer[cursor:]);
        if err != 0 {
            return false;
        }
        if count == 0 {
            return false;
        }
        prev := cursor;
        cursor += count;
        // fmt.println("recv: ", count);
        // fmt.println(buffer[:cursor]);
        end_token :: "\r\n\r\n";
        // TODO: this has a logical bug, if the end token gets split into two recv chunks we will never find it!
        index := strings.index(string(buffer[prev:cursor]), end_token);
        // fmt.println("find index:", index);
        if index != -1 {
            header_end = prev + index + len(end_token);
            return true;
        }
        if cursor >= len(buffer) {
            return false; // could not fit request header in 4kb
        }
    }
    return false;
}

respond :: proc(s: socket.handle) -> int {
    t1 := time.now_monotonic(); // osx only!!

    sync.atomic_add(&concurrent_count, 1, .Relaxed);
    fmt.println("concurrent_count:", concurrent_count);
    // fmt.println("started thread to respond");
    defer {
        socket.close(s);
        sync.atomic_sub(&concurrent_count, 1, .Relaxed);
        t2 := time.now_monotonic();
        dur := time.diff(t1, t2);
        fmt.println("response time:", dur/1000, "us");
    }

    os.nanosleep(1000);

    // TODO: set this up!!
    // socket.set_options(s, .RECVTIMEO, 100)

    // get the data
    buffer: Request_Buffer;
    buffer.buffer = make([dynamic]byte, 4 * 1024);
    if !recv_http_header(&buffer, s) {
        fmt.println("recieve header failed");
        return 1;
    }
    ok: bool;
    buffer.header, ok = parse_http_request(string(buffer.buffer[:buffer.header_end]));
    if !ok {
        fmt.println("http parse failed");
        return 1;
    }

	fmt.println(buffer.header);

	socket.sendall(s, cast([]byte)("HTTP/1.1 200 OK\n" +
    "Content-Length: 16\n" + // HACK! hard-coded!
    "Connection: close\n" +
    "\n" +
    "Hello from odin!"));
    try("socket-shutdown", socket.shutdown(s, .RDWR));
	return 0;
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

    for {
        client_addr: socket.address;
        client_sock, err := socket.accept(sock, &client_addr);
        if err != 0 {
            fmt.println("error acceping connection", os.strerror(err));
            continue;
        }
        // fmt.println("accepted connection!!");
        thread.detach(thread.go(respond, client_sock));
    }

	return 0;
}
