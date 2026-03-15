(define (fibH r)
  (lambda (n)
    (if (less_than n 2)
        n
        (add (r (sub n 1)) (r (sub n 2)))))) ;; => fibH

(define fib (lambda (n) ((Y fibH) n))) ;; => fib

(fib 3) ;; => 2
