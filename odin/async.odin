package main

import "core:fmt"
import "core:nbio"
import "core:time"

main :: proc() {
	err := nbio.acquire_thread_event_loop()
	assert(err == nil)
	defer nbio.release_thread_event_loop()

	nbio.timeout(time.Second, proc(_: ^nbio.Operation) {
		fmt.println("Hellope after 1 second!")
	})

	fmt.println("Hello from main")
	err = nbio.run()
	assert(err == nil)
	fmt.println("second Hello from Main fn")
}
