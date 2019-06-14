package server

import "core:fmt"
import "core:os"
import "../socket"
import "../thread"

respond :: proc(s: socket.handle) -> int {
    fmt.println("started thread to respond");
	socket.sendall(s, cast([]byte)`HTTP/1.1 200 OK

    Hello World!!!!! FROM ODIN!
    `);
    try(socket.shutdown(s, 2));
	return 0;
}

try :: proc(e: os.Errno) {
    if e != 0 {
        fmt.println(os.strerror(e));
    }
}

panic_on :: proc(e: os.Errno) {
    if e != 0 {
        fmt.println(os.strerror(e));
        panic(fmt.aprint("system error: ", os.strerror(e)));
    }
}

must :: proc(a: $T, b: os.Errno) -> T {
    panic_on(b);
    return a;
}

start :: proc(port: u16) -> int {
	fmt.println("Starting server! Make sure to start this as a thread");

	sock := must(socket.make_tcp_socket());
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
        fmt.println("accepted connection!!");
        thread.go(respond, client_sock);
    }

	return 0;
}