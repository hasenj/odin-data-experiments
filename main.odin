package main

import "core:fmt"
import "core:os"
import "pthread"

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

main :: proc() {
    fmt.println("hello odin threads");

    th1: pthread.handle;
    pthread.create(&th1, nil, th1_proc, nil);

    th2: pthread.handle;
    pthread.create(&th2, nil, th2_proc, nil);

    pthread.join(th1, nil);
    pthread.join(th2, nil);
}

/*

#include <stdio.h>
#include <pthread.h>
#include <stdatomic.h>

struct ring_buffer {
    int[100] buffer;
    int header;
    int tail;
};

void* processor_thread(void *data) {
    printf("hello, I'm the other thread\n");
    return 0;
}

struct pusher_data {
    pthread_t *processor;
    ring_buffer *items;
};

void* pusher_thread(void *vdata) {
    pusher_data_t *data = (pusher_data_t *)vdata;
    printf("hello, I'm the pusher thread\n");
    return 0;
}

int main() {
    printf("welcome to threads\n");
    pthread_t th1;
    pthread_t th2;
    pthread_create(&th1, 0, pusher_thread, 0);
    pthread_create(&th2, 0, processor_thread, 0);
    pthread_join(th1, 0);
    pthread_join(th2, 0);
}
 */
