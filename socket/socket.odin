package socket

using import "../csocket"

import "core:os"

handle :: distinct i32;
address :: sockaddr_in;
address6 :: sockaddr_in6;
addressbase :: sockaddr_base;
host_to_network :: hton;
network_to_host :: ntoh;

socket_is_valid :: proc(fd: handle) -> bool {
    return fd >= 0;
}

make_socket :: proc(domain: i32, typ: i32, protocol: i32) -> (handle, os.Errno) {
    socket := handle(socket(domain, typ, protocol));
    if !socket_is_valid(socket) {
        return socket, os.get_last_error();
    } else {
        return socket, 0;
    }
}

make_tcp_socket :: proc() -> (handle, os.Errno) {
    return make_socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
}

make_tcp_socket_v6 :: proc() -> (handle, os.Errno) {
    return make_socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);
}

make_address :: proc(port: u16 = 0) -> address {
    server: address;
    server.family = AF_INET;
    server.port = host_to_network(port);
    return server;
}

make_address_v6 :: proc(port: u16 = 0) -> address6 {
    server: address6;
    server.family = AF_INET6;
    server.port = host_to_network(port);
    return server;
}

set_option_int :: proc(fd: handle, option_name: i32, val: int) -> os.Errno {
    res := setsockopt(i32(fd), SOL_SOCKET, option_name, &val, size_of(val));
    if res == -1 {
        return os.get_last_error();
    } else {
        return 0;
    }
}

set_option :: proc{set_option_int};

// TODO: a version for buffers
get_option :: proc(fd: handle, option_name: i32) -> (int, os.Errno) {
    val: int;
    size := u32(size_of(val));
    res := getsockopt(i32(fd), SOL_SOCKET, option_name, &val, &size);
    if res == -1 {
        return 0, os.get_last_error();
    } else {
        return val, 0;
    }
}


socket_set_flag :: proc(fd: handle, flag: int) -> os.Errno {
    res := fcntl(i32(fd), F_SETFL, flag);
    if res == -1 {
        return os.get_last_error();
    } else {
        return 0;
    }
}

set_option_reuse_address :: proc(fd: handle, reuse: bool) -> os.Errno {
    return set_option(fd, SO_REUSEADDR, int(reuse));
}

get_recv_buffer_size :: proc(fd: handle) -> (int, os.Errno) {
    return get_option(fd, SO_RCVBUF);
}

// TODO: this probably won't work on windows!!
set_flag_nonblock :: proc(fd: handle) -> os.Errno {
    return socket_set_flag(fd, O_NONBLOCK);
}

bind :: proc(fd: handle, addr: ^$T) -> bool {
    #assert(type_of(addr.base) == addressbase);
    return bind(i32(fd), cast(^sockaddr) addr, size_of(addr^)) == 0;
}

listen :: proc(fd: handle, backlog: int) -> bool {
    return listen(i32(fd), i32(backlog)) == 0;
}

is_would_block :: proc(errno: os.Errno) -> bool {
    return errno == EAGAIN || errno == EWOULDBLOCK;
}

accept :: proc(fd: handle, client_addr: ^$T) -> (handle, os.Errno) {
    #assert(type_of(client_addr.base) == addressbase);
    len : u32 = size_of(client_addr^);
    sock := accept(i32(fd), cast(^sockaddr) client_addr, &len);
    if sock > 0 {
        return handle(sock), 0;
    } else {
        return 0, os.get_last_error();
    }
}

_sock_io_result :: proc(count: int) -> (int, os.Errno) {
    if count == -1 {
        return -1, os.get_last_error();
    } else {
        return count, 0;
    }
}

// returns bytes read and socket state. errors ignored for now!!
recv :: proc(fd: handle, buffer: []byte) -> (int, os.Errno) {
    return _sock_io_result(csocket.recv(i32(fd), &buffer[0], uint(len(buffer)), 0));
}

send_bytes :: proc(fd: handle, buffer: []byte) -> (int, os.Errno) {
    return _sock_io_result(csocket.send(i32(fd), &buffer[0], uint(len(buffer)), MSG_NOSIGNAL));
}

sendall :: proc(fd: handle, buffer: []byte) -> os.Errno {
    sent := 0;
    for sent < len(buffer) {
        count, err := send_bytes(fd, buffer[sent:]);
        sent += count;
        if err != 0 {
            return err;
        }
    }
    return 0;
}

send :: proc{send_bytes};

shutdown :: proc(fd: handle, how: i32) -> os.Errno {
    res := csocket.shutdown(i32(fd), how);
    if res == -1 {
        return os.get_last_error();
    } else {
        return 0;
    }
}

close :: proc(fd: handle) {
    os.close(os.Handle(fd));
}