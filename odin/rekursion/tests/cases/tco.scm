(define (sum-n n acc)
  (if (less_than n 1)
      acc
      (recur (sub n 1) (add n acc))))

(sum-n 100 0) ;; => 5050

;; Verify TCO doesn't blow frames stack
(define (count-down n)
  (if (less_than n 1)
      (quote done)
      (recur (sub n 1))))

(count-down 2000) ;; => done

;; tco fibonacci
(define (fib a b n)
  (if (less_than n 1)
      a 
      (recur b (add a b) (sub n 1)))) ;; fib

(fib 0 1 10) ;; => 55