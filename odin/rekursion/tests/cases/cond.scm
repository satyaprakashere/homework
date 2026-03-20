(cond (false 1) (true 2)); => 2
(cond (false 1)
    (false 2)
    (else 3)) ;; => 3
(cond (true 1)
    (false 2)
    (else 3)) ;; => 1
(cond (false 1)
    (true 2)
    (else 3)) ;; => 2
(cond (false 1)
    ((< 1 2)  (add  1 3))
    (else 5)) ;; => 4
