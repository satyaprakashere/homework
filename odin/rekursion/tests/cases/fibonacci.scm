(define (fibH r)
  (lambda (n)
    (if (less_than n 2)
        n
        (add (r (sub n 1)) (r (sub n 2)))))) ;; => fibH

(define fib (lambda (n) ((Z fibH) n))) ;; => fib

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
