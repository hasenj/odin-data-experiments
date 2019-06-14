package main

import "core:fmt"
import "core:os"
import "pthread"
import "server"

ring_buffer :: struct(T: typeid, N: int) {
    cond: pthread.cond,
    buffer: [N]T,
    write: int,
    read: int,
}

shared_buffer: ring_buffer(int, 30);

th1_proc :: proc "cdecl" (data: rawptr) -> rawptr {
    fmt.println("hello, from thread1");
    os.nanosleep(100);
    for i in 0..<10 {
        os.nanosleep(100);
        fmt.println("th[1]: ", i);
    }
    return nil;
}

th2_proc :: proc "cdecl" (data: rawptr) -> rawptr {
    fmt.println("hello from thread2!!");
    for i in 0..<10 {
        os.nanosleep(100);
        fmt.println("th[2]: ", i);
    }
    return nil;
}

th3_proc :: proc(start: int) -> int {
    fmt.println("hello from thread3");
    end := start + 10;
    for i in start..<end {
        os.nanosleep(100);
        fmt.println("th[3]: ", i);
    }
    return end;
}

main :: proc() {
    fmt.println("hello odin threads");

    th_server := go(server.start, 3040);

    pthread.cond_init(&shared_buffer.cond, nil);

    th1: pthread.handle;
    pthread.create(&th1, nil, th1_proc, nil);

    th2: pthread.handle;
    pthread.create(&th2, nil, th2_proc, nil);

    th3 := go(th3_proc, 112);

    pthread.join(th1, nil);
    pthread.join(th2, nil);
    th3_result := come(&th3);

    fmt.println("\n\nth3 value:", th3_result);

    come(&th_server);
    fmt.println("server came!");
}

// custom thread launching

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
