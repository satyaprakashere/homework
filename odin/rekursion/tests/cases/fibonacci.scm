(define (fib a b n)
  (if (less_than n 1)
      a
      (fib b (add a b) (sub n 1))))

(define (fib-iter n) (fib 0 1 n))
(define fib fib-iter)

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
