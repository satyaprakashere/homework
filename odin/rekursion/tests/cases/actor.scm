(define ping-actor
  (spawn 
    (lambda ()
      (print "Ping started")
      (let ((msg (receive)))
        (print "Ping got message: " msg)
        (if (eq msg (quote start))
            (begin
              (print "Ping responding with pong")
              (send pong-actor (quote ping))
              (quote done))
            (print "Ping received unexpected message")))
      (print "Ping finished")))) ;; => ping-actor

(define pong-actor
  (spawn
    (lambda ()
      (print "Pong started")
      (let ((msg (receive)))
        (print "Pong got message: " msg)
        (if (eq msg (quote ping))
            (print "Pong received ping!")
            (print "Pong received unexpected message")))
      (print "Pong finished")))) ;; => pong-actor

(send ping-actor (quote start)) ;; => ok
(run-scheduler) ;; => all-actors-finished
