(define (fib n)
    (if (lt n 2)
        n
        (add (fib (sub n 1)) (fib (sub n 2))))) ;; => fib

(fib 10) ;; => 55