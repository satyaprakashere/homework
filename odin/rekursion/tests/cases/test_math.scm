;; Numerical and Set Utility Tests

;; 1. Numbers
(abs -5) ;; => 5
(abs 10) ;; => 10
(max 10 20) ;; => 20
(min 10 20) ;; => 10
(gcd 48 18) ;; => 6
(lcm 12 15) ;; => 60
(prime? 7) ;; => true
(prime? 9) ;; => false

;; 2. Sets
(is-member 1 (list 1 2 3)) ;; => true
(is-member 4 (list 1 2 3)) ;; => false
(length (union (list 1 2) (list 2 3))) ;; => 3
(length (intersection (list 1 2) (list 2 3))) ;; => 1
(length (difference (list 1 2) (list 2 3))) ;; => 1
(subset? (list 1 2) (list 1 2 3)) ;; => true
(subset? (list 1 4) (list 1 2 3)) ;; => false
