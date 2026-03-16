(define (sum-n n acc)
  (if (less_than n 1)
      acc
      (sum-n (sub n 1) (add n acc))))

(sum-n 100 0) ;; => 5050

;; Verify TCO doesn't blow frames stack
(define (count-down n)
  (if (less_than n 1)
      (quote done)
      (count-down (sub n 1))))

(count-down 2000) ;; => done

;; tco fibonacci
(define (fib n a b)
  (if (less_than n 1)
      a
      (fib (sub n 1) b (add a b)))) ;; fib

(fib 98 0 1) ;; => 6174643828739884737