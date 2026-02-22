(+ 1 2) ;; => 3
(define x 10) ;; => x
x ;; => 10
(+ x 5) ;; => 15
(cons 1 2) ;; => (1 . 2)
(first (cons 1 2)) ;; => 1
(rest (cons 1 2)) ;; => 2
(array 1 2 3) ;; => (1 2 3)
<<<<<<< HEAD
(define (add a b) (+ a b)) ;; => add
(add 11 8) ;; => 19
=======
(define add (lambda (a b) (+ a b))) ;; => add
(add 11 8) ;; => 19
(add x 8) ;; => 18
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
