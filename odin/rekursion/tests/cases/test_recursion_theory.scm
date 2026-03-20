;; Mu-Recursion Theory Tests

(zero 10 20) ;; => 0
(succ 5) ;; => 6
((proj 3 2) 10 20 30) ;; => 20

;; Composition
((compose succ (proj 1 1)) 5) ;; => 6

;; Primitive Recursion (Addition)
(let ((my-add (prim-rec (proj 1 1) (compose succ (proj 3 2)))))
  (my-add 3 5)) ;; => 8

;; Mu-operator (Minimization)
;; smallest n s.t. n - 5 = 0
(let ((my-mu (mu-operator (lambda (n) (sub n 5)))))
  (my-mu)) ;; => 5
