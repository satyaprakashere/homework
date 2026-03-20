(define (fib-helper a b n)
  (if (less_than n 1)
      a
      (recur b (add a b) (sub n 1))))

(define (fib n) (fib-helper 0 1 n))

(fib 0) ;; => 0
(fib 1) ;; => 1
(fib 2) ;; => 1
(fib 3) ;; => 2
(fib 4) ;; => 3
(fib 5) ;; => 5
(fib 6) ;; => 8
(fib 7) ;; => 13
(fib 8) ;; => 21
(fib 9) ;; => 34
(fib 10) ;; => 55
(fib 15) ;; => 610
