(define g +) (g 1 2) ;; => 3
(define f (lambda (x) (* x 2))) (define h f) (h 5) ;; => 10
(define x 100) (define y x) y ;; => 100
(define my-list list) (my-list 1 2 3) ;; => (1 2 3)
(define (fact n) (if (eq? n 0) 1 (* n (fact (- n 1))))) (define factorial fact) (factorial 5) ;; => 120
(define is-num? is-number) (is-num? 42) ;; => true
(is-num? "foo") ;; => false
