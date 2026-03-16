(define (sum-to n)
  (let loop ((i n) (acc 0))
    (if (less_than i 1)
        acc
        (loop (sub i 1) (add i acc)))))

(sum-to 10) ;; => 55
(sum-to 100) ;; => 5050

(define (count-down-named n)
  (let count ((i n))
    (if (less_than i 1)
        (quote done)
        (count (sub i 1)))))

(count-down-named 2000) ;; => done
