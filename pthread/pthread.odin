package pthread


handle :: distinct rawptr;
attrs :: distinct rawptr;

foreign import pthread "system:pthread"

@(link_prefix="pthread_")
foreign pthread {
    create :: proc(th: ^handle, attrs: ^attrs, routine: proc(rawptr) -> rawptr, data: rawptr) -> i32 ---;
    join :: proc(th: handle, ret: ^rawptr) -> i32 ---;
}