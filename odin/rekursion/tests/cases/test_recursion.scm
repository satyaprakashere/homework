(define (fib a b n)
  (if (less_than n 1)
      a
      (fib b (add a b) (sub n 1))))

(fib 0 1 5) ;; => 5
