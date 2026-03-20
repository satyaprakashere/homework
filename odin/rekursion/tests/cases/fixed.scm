;; Advanced Fixed-Point Tests

;; Theta fact
(let ((fact (Theta (lambda (f)
                     (lambda (n)
                       (if (eq n 0)
                           1
                            (mul  n (f (sub n 1)))))))))
    (fact 5)) ;; => 120

;; Omega (Just check existence, calling Omega-proc would infinite loop)
(is_null Omega-proc)
 ;; => false
