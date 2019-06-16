package socket

address_family :: enum i32 {
    INET :: 2,
    INET6 :: 10,
}

options :: enum i32 {
    REUSEADDR = 0x0004,
    RCVBUF = 0x1002, // TODO: verify this value on linux!
}

MSG_NOSIGNAL :: 0x4000;

EWOULDBLOCK :: 11;
EAGAIN  :: 11;
