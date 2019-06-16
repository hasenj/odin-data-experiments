package server

import "core:fmt"
import "core:os"
import "../socket"
import "../thread"

respond :: proc(s: socket.handle) -> int {
    // fmt.println("started thread to respond");

	// header_bytes := recv_http_header(s);
	// request := parse_http_request(header_bytes);
	// fmt.println(request);

	socket.sendall(s, cast([]byte)("HTTP/1.1 200 OK\n" +
    "Connection: close\n\n" +
    "Hello from odin!"));
    try("socket-shutdown", socket.shutdown(s, .RDWR));
    socket.close(s);
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
