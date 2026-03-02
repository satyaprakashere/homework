package main

import "core:nbio"
import "core:time"
import "core:fmt"

main :: proc() {
	err := nbio.acquire_thread_event_loop()
	assert(err == nil)
	defer nbio.release_thread_event_loop()

	nbio.timeout(time.Second, proc(_: ^nbio.Operation) {
		fmt.println("Hellope after 1 second!")
	})

	err = nbio.run()
	assert(err == nil)
}