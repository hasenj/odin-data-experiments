package csocket

// reference: https://beej.us/guide/bgnet/html/multi/sockaddr_inman.html

// poor man's polymorphism
sockaddr_base :: struct {
    len: u8,    // doesn't need to be filled actually!
    family: u8, // AF_INET or AF_INET6 (this is like a union flag)
    port: u16,  // in network byte order
}

// A thing that can represent either sockaddr_in or sockaddr_in6
sockaddr :: struct {
    using base: sockaddr_base,
    sa_data: [12]byte, // actually could be more!!
}

// IPv4
sockaddr_in :: struct {
    using base: sockaddr_base,
    addr: u32,      // IP Address (v4)
    zero: [8]byte,  // padding
}

// IPv6
sockaddr_in6 :: struct {
    using base: sockaddr_base,
    flowinfo: u32,  // No idea what this is for; probably obsolete
    addr: [16]byte, // IP Address (v6)
    scope_id: u32,  // No idea what this is for!
}

foreign import libc "system:c";
@(default_calling_convention="c")
foreign libc {
    socket :: proc(domain: i32, type_: i32, protocol: i32) -> i32 ---;
    bind :: proc(sockfd: i32, addr: ^sockaddr, addrlen: u32) -> i32 ---;
    accept :: proc(sockfd: i32, addr: ^sockaddr, addrlen: ^u32) -> i32 ---;
    listen :: proc(sockfd: i32, backlog: i32) -> i32 ---;
    shutdown :: proc(sockfd: i32, how: i32) -> i32 ---;

    // https://beej.us/guide/bgnet/html/multi/setsockoptman.html
    getsockopt :: proc (sockfd: i32, level: i32, optname: i32, optval: rawptr, optlen: ^u32) -> i32 ---;
    setsockopt :: proc (sockfd: i32, level: i32, optname: i32, optval: rawptr, optlen: u32) -> i32 ---;

    htonl :: proc(hostlong: u32) -> u32 ---;
    htons :: proc(hostshort: u16) -> u16 ---;
    ntohl :: proc(netlong: u32) -> u32 ---;
    ntohs :: proc(netshort: u16) -> u16 ---;

    recv :: proc(s: i32, buf: rawptr, len: uint, flags: i32) -> int ---;
    recvfrom :: proc(s: i32, buf: rawptr, len: uint, flags: i32, addr: ^sockaddr, addrlen: ^u32) -> int ---;

    send :: proc(s: i32, msg: rawptr, len: uint, flags: i32) -> int ---;
    sendto :: proc(s: i32, msg: rawptr, len: i32, flags: i32,  addr: ^sockaddr, addrlen: ^u32) -> int ---;

    // int fcntl(int fd, int cmd, ... /* arg */ );
    fcntl :: proc(fd: i32, cmd: i32, args: ..any) -> i32 ---;

    // posix signals
    signal :: proc(sig: i32, handler: proc(sig: i32)) -> i32 ---;
}

hton :: proc {htonl, htons};
ntoh :: proc {ntohl, ntohs};
