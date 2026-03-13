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
      (print "Ping finished")))) ;; => ping-actor

(define pong-actor
  (spawn
    (lambda ()
      (print "Pong started")
      (let ((msg (receive)))
        (print "Pong got message: " msg)
        (if (eq msg 'ping)
            (print "Pong received ping!")
            (print "Pong received unexpected message")))
      (print "Pong finished")))) ;; => pong-actor

(send ping-actor 'start) ;; => ok
(run-scheduler) ;; => all-actors-finished
