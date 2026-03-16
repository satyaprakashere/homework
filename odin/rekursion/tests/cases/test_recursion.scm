(define (fib n)
  (if (less_than n 2)
      n
      (add (fib (sub n 1)) (fib (sub n 2)))))

(fib 5) ;; => 5
