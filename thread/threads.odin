package thread

import "../pthread"

start_info :: struct(T, S: typeid) {
    ctx: type_of(context),
    start: proc(i: T) -> S,
    data: T,
    output: ^S,
}

thread_handle :: struct(T, S: typeid) {
    handle: pthread.handle,
    props: ^start_info(T, S), // to be freed when done
    // start: proc(i: T) -> S, // hack to carry around the type information
}

go :: proc(start: proc(i: $T) -> $S, data: T) -> thread_handle(T, S) {
    spawner :: proc "cdecl" (rparams: rawptr) -> rawptr {
        params := cast(^start_info(T, S))(rparams);
        context = params.ctx;
        params.output^ = params.start(params.data);
        return params.output;
    }
    h: pthread.handle;
    props := new(start_info(T, S));
    props.ctx = context;
    props.start = start;
    props.data = data;
    props.output = new(S);
    pthread.create(&h, nil, spawner, props);
    return thread_handle(T, S){
        handle = h,
        props = props,
    };
}

come :: proc(handle: ^thread_handle($T, $S)) -> S {
    pthread.join(handle.handle, cast(^rawptr)&handle.props.output);
    ret := handle.props.output^;
    free(handle.props.output);
    free(handle.props);
    return ret;
}