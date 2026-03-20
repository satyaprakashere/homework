(define g add) ;; => g
(g 1 2) ;; => 3

(define f (lambda (x) (mul x 2))) ;; => f
(define h f) ;; => h
(h 5) ;; => 10

(define x 100) ;; => x
(define y x) ;; => y
y ;; => 100

(define is_num is_number) ;; => is_num
(is_num 42) ;; => true
(is_num "foo") ;; => false
