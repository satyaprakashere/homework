(define g add) ;; => g
(g 1 2) ;; => 3

(define f (lambda (x) (mul x 2))) ;; => f
(define h f) ;; => h
(h 5) ;; => 10

(define x 100) ;; => x
(define y x) ;; => y
y ;; => 100

(define is-num? is-number) ;; => is-num?
(is-num? 42) ;; => true
(is-num? "foo") ;; => false
