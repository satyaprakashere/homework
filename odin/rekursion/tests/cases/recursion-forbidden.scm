(define (bad-fib n)
  (if (less_than n 2)
      n
      (add (bad-fib (sub n 1)) (bad-fib (sub n 2)))))

(bad-fib 5) ;; => nil
