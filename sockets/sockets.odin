package server

using import "csock"

import "core:os"

Socket :: distinct int;
Address_V4 :: sockaddr_in;
Address_V6 :: sockaddr_in6;
AddressBase :: sockaddr_base;
host_to_network :: hton;
network_to_host :: ntoh;

socket_is_valid :: proc(fd: Socket) -> bool {
    return fd >= 0;
}

make_socket :: proc(domain: int, typ: int, protocol: int) -> (Socket, os.Errno) {
    socket := Socket(socket(domain, typ, protocol));
    if !socket_is_valid(socket) {
        return socket, os.get_last_error()
    } else {
        return socket, 0
    }
}

make_socket_tcp_v4 :: proc() -> (Socket, os.Errno) {
    return make_socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
}

make_socket_tcp_v6 :: proc() -> (Socket, os.Errno) {
    return make_socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP);
}

make_address_v4 :: proc(port: u16) -> Address_V4 {
    server: Address_V4;
    server.family = AF_INET;
    server.port = host_to_network(port);
    return server;
}

make_address_v6 :: proc(port: u16) -> Address_V6 {
    server: Address_V6;
    server.family = AF_INET6;
    server.port = host_to_network(port);
    return server;
}

socket_set_option_int :: proc(fd: Socket, option_name: int, val: int) -> os.Errno {
    res := setsockopt(int(fd), SOL_SOCKET, option_name, &val, size_of(val));
    if res == -1 {
        return os.get_last_error();
    } else {
        return 0;
    }
}

// TODO: a version for buffers
socket_get_option :: proc(fd: Socket, option_name: int) -> (int, os.Errno) {
    val: int;
    size := size_of(val);
    res := getsockopt(int(fd), SOL_SOCKET, option_name, &val, &size);
    if res == -1 {
        return 0, os.get_last_error();
    } else {
        return val, 0;
    }
}

socket_set_flag :: proc(fd: Socket, flag: int) -> os.Errno {
    res := fcntl(int(fd), F_SETFL, flag);
    if res == -1 {
        return os.get_last_error();
    } else {
        return 0;
    }
}

socket_set_option_reuse_address :: proc(fd: Socket, reuse: bool) -> os.Errno {
    return socket_set_option(fd, SO_REUSEADDR, int(reuse));
}

socket_get_recv_buffer_size :: proc(fd: Socket) -> (int, os.Errno) {
    return socket_get_option(fd, SO_RCVBUF);
}

// TODO: this probably won't work on windows!!
socket_set_flag_nonblock :: proc(fd: Socket) -> os.Errno {
    return socket_set_flag(fd, O_NONBLOCK);
}

bind_socket_address:: proc(fd: Socket, addr: ^$T) -> bool {
    #assert(type_of(addr.base) == AddressBase);
    return bind(int(fd), cast(^sockaddr) addr, size_of(addr^)) == 0;
}

listen :: proc(fd: Socket, backlog: int) -> bool {
    return listen(int(fd), int(backlog)) == 0;
}

is_would_block :: proc(errno: os.Errno) -> bool {
    return errno == EGAIN || errno == EWOULDBLOCK;
}

Accept_Result :: struct {
    socket: Socket,
    accepted: bool,
    errno: int,
}

accept :: proc(fd: Socket, client_addr: ^$T) -> (Socket, os.Errno) {
    #assert(type_of(client_addr.base) == AddressBase);
    len : u32 = size_of(client_addr^);
    sock := accept(int(fd), cast(^sockaddr) client_addr, &len);
    if sock > 0 {
        return sock, 0;
    } else {
        return 0, os.get_last_error();
    }
}

// returns bytes read and socket state. errors ignored for now!!
recv :: proc(fd: Socket, buffer: []byte) -> (int, os.Errno) {
    return _sock_io_result(csock.recv(int(fd), raw_data(buffer), len(buffer), 0));
}

send :: proc(fd: Socket, buffer: []byte) -> (int, os.Errno) {
    return _sock_io_result(csock.send(int(fd), raw_data(buffer), len(buffer), MSG_NOSIGNAL));
}
