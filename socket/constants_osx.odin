package socket

address_family :: enum i32 {
    INET  = 2,
    INET6 = 30,
}

MSG_NOSIGNAL :: 0x20000;

EWOULDBLOCK :: 35;
EAGAIN  :: 35;

options :: enum i32 {
    REUSEADDR = 0x0004,
    RCVBUF = 0x1002, // TODO: find windows and linux values
}