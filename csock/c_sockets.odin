package csock

import "core:C"

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
    socket :: proc(domain: c.int, type_: c.int, protocol: c.int) -> c.int ---;
    bind :: proc(sockfd: c.int, addr: ^sockaddr, addrlen: c.uint) -> c.int ---;
    accept :: proc(sockfd: c.int, addr: ^sockaddr, addrlen: ^c.uint) -> c.int ---;
    listen :: proc(sockfd: c.int, backlog: c.int) -> c.int ---;

    // https://beej.us/guide/bgnet/html/multi/setsockoptman.html
    getsockopt :: proc (sockfd: c.int, level: c.int, optname: c.int, optval: rawptr, optlen: ^c.uint) -> c.int ---;
    setsockopt :: proc (sockfd: c.int, level: c.int, optname: c.int, optval: rawptr, optlen: c.uint) -> c.int ---;

    htonl :: proc(hostlong: u32) -> u32 ---;
    htons :: proc(hostshort: u16) -> u16 ---;
    ntohl :: proc(netlong: u32) -> u32 ---;
    ntohs :: proc(netshort: u16) -> u16 ---;

    recv :: proc(s: c.int, buf: rawptr, len: c.size_t, flags: c.int) -> c.ssize_t ---;
    recvfrom :: proc(s: c.int, buf: rawptr, len: c.size_t, flags: c.int, addr: ^sockaddr, addrlen: ^c.uint) -> c.ssize_t ---;

    send :: proc(s: c.int, msg: rawptr, len: c.int, flags: c.int) -> c.ssize_t ---;
    sendto :: proc(s: c.int, msg: rawptr, len: c.int, flags: c.int,  addr: ^sockaddr, addrlen: ^c.uint) -> c.ssize_t ---;

    // int fcntl(int fd, int cmd, ... /* arg */ );
    fcntl :: proc(fd: c.int, cmd: c.int, args: ..any) -> c.int ---;

    // posix signals
    signal :: proc(sig: c.int, handler: proc(sig: c.int)) -> c.int ---;
}

hton :: proc {htonl, htons};
ntoh :: proc {ntohl, ntohs};
