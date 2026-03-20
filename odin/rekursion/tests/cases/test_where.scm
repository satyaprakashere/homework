(define (f1 x y)
  (add x y)
  (where (x 10) (y 20)))

(f1 0 0) ;; => 30

(define (f2 a b)
  (add a (f3 b))
  (where 
    (f3 (lambda (x) (mul x 3)))))

(f2 1 2) ;; => 7
