;; 6.1 Booleans
(not #t) ;; => false
(not #f) ;; => true
(and #t #t) ;; => true
(or #f #t) ;; => true
(and #t #f) ;; => false
(or #f #f) ;; => false

;; 6.2 Equivalence predicates
(eq? 'a 'a) ;; => true
(eq? '() '()) ;; => true

;; 6.3 Pairs and lists
(cons 'a '()) ;; => (a)
(car (cons 'a 'b)) ;; => a
(cdr (cons 'a 'b)) ;; => b
(list 1 2 3) ;; => (1 2 3)
(length (list 1 2 3)) ;; => 3
(append (list 1 2) (list 3 4)) ;; => (1 2 3 4)
(reverse (list 1 2 3)) ;; => (3 2 1)

;; 4.1.4 Procedures
((lambda (x) (+ x x)) 4) ;; => 8

;; 4.1.5 Conditionals
(if #t 'yes 'no) ;; => yes
(if #f 'yes 'no) ;; => no
(cond (#f 1) (#t 2) (else 3)) ;; => 2
(cond (#f 1) (#f 2) (else 3)) ;; => 3

;; 4.2.2 Binding constructs
(let ((x 2) (y 3)) (* x y)) ;; => 6

;; 6.3.2.1 Higher-order functions
(map (lambda (x) (+ x 1)) (list 1 2 3)) ;; => (2 3 4)
(foldl (lambda (acc x) (+ acc x)) 0 (list 1 2 3 4)) ;; => 10
(foldr (lambda (x acc) (+ acc x)) 0 (list 1 2 3 4)) ;; => 10
