package server

import "core:fmt"

start :: proc(port: int) -> int {
	fmt.println("Starting server! Make sure to start this as a thread");
	return 0;
}