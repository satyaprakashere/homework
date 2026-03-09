;; actor_test.scm
;; Testing Elixir-style actor model using shift/reset

(define ping-actor
  (spawn 
    (lambda ()
      (print "Ping started")
      (let ((msg (receive)))
        (print "Ping got message: " msg)
        (if (eq msg 'start)
            (begin
              (print "Ping responding with pong")
              (send pong-actor 'ping)
              'done)
            (print "Ping received unexpected message")))
      (print "Ping finished"))))

(define pong-actor
  (spawn
    (lambda ()
      (print "Pong started")
      (let ((msg (receive)))
        (print "Pong got message: " msg)
        (if (eq msg 'ping)
            (print "Pong received ping!")
            (print "Pong received unexpected message")))
      (print "Pong finished"))))

(print "Starting actor test...")
(send ping-actor 'start)
(print "Running scheduler...")
(run-scheduler)
(print "Test complete.")
