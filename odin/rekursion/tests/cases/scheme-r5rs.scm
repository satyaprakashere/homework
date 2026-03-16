(not #t) ;; => false
(not #f) ;; => true
(and #t #t) ;; => true
(or #f #t) ;; => true
(and #t #f) ;; => false
(or #f #f) ;; => false

(eq? (quote a) (quote a)) ;; => true
(eq? (quote ()) (quote ())) ;; => true

(cons (quote a) (quote ())) ;; => (a)
(car (cons (quote a) (quote b))) ;; => a
(cdr (cons (quote a) (quote b))) ;; => b
(list 1 2 3) ;; => (1 2 3)
(length (list 1 2 3)) ;; => 3
(append (list 1 2) (list 3 4)) ;; => (1 2 3 4)
(reverse (list 1 2 3)) ;; => (3 2 1)

((lambda (x) (+ x x)) 4) ;; => 8

(if #t (quote yes) (quote no)) ;; => yes
(if #f (quote yes) (quote no)) ;; => no
(cond (#f 1) (#t 2) (else 3)) ;; => 2
(cond (#f 1) (#f 2) (else 3)) ;; => 3

(let ((x 2) (y 3)) (* x y)) ;; => 6

(fmap (lambda (x) (+ x 1)) (list 1 2 3)) ;; => (2 3 4)
(foldl (lambda (acc x) (+ acc x)) 0 (list 1 2 3 4)) ;; => 10
(foldr (lambda (x acc) (+ acc x)) 0 (list 1 2 3 4)) ;; => 10

(caar (quote ((1 2) 3))) ;; => 1
(cadr (quote (1 2 3))) ;; => 2