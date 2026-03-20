;; Combinator Tests

(I 10) ;; => 10
((K 10) 20) ;; => 10
(((S K) K) 5) ;; => 5
(((B succ) succ) 5) ;; => 7
(((C K) 10) 20) ;; => 20
((W K) 10) ;; => 10

(let ((fact (Z (lambda (f)
                 (lambda (n)
                   (if (eq n 0)
                       1
                        (mul  n (f (sub n 1)))))))))
    (fact 5)) ;; => 120
