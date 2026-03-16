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
