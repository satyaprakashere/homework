package main

import "core:nbio"
import "core:net"
import "core:thread"
import "core:time"

Connection :: struct {
	loop:   ^nbio.Event_Loop,
	socket: net.TCP_Socket,
}

main :: proc() {
	workers: thread.Pool
	thread.pool_init(&workers, context.allocator, 2)
	thread.pool_start(&workers)

	err := nbio.acquire_thread_event_loop()
	defer nbio.release_thread_event_loop()
	assert(err == nil)

	server, listen_err := nbio.listen_tcp({nbio.IP4_Any, 1234})
	assert(listen_err == nil)
	nbio.accept_poly(server, &workers, on_accept)

	err = nbio.run()
	assert(err == nil)

	on_accept :: proc(op: ^nbio.Operation, workers: ^thread.Pool) {
		assert(op.accept.err == nil)

		nbio.accept_poly(op.accept.socket, workers, on_accept)

		thread.pool_add_task(workers, context.allocator, do_work, new_clone(Connection{
			loop   = op.l,
			socket = op.accept.client,
		}))
	}

	do_work :: proc(t: thread.Task) {
		connection := (^Connection)(t.data)

		// Imagine CPU intensive work that's been ofloaded to a worker thread.
		time.sleep(time.Second * 1)

		nbio.send_poly(connection.socket, {transmute([]byte)string("Hellope!\n")}, connection, on_sent, l=connection.loop)
	}

	on_sent :: proc(op: ^nbio.Operation, connection: ^Connection) {
		assert(op.send.err == nil)
		// Client got our message, clean up.
		nbio.close(connection.socket)
		free(connection)
	}
}