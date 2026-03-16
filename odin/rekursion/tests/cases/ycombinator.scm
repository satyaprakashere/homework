(define (factH r)
  (lambda (n)
    (if (less_than n 2)
        1
        (mul n (r (sub n 1)))))) ;; => factH

(define factorial (lambda (n) ((Y factH) n))) ;; => factorial

(factorial 0) ;; => 1
(factorial 1) ;; => 1
(factorial 5) ;; => 120

(define (sumH r)
  (lambda (lst)
    (if (is-null lst)
        0
        (add (first lst) (r (rest lst)))))) ;; => sumH

(define sum (Y sumH)) ;; => sum

(sum (list 1 2 3 4 5)) ;; => 15
(sum (quote ())) ;; => 0

(define (powH r)
  (lambda (base exp)
    (if (less_than exp 1)
        1
        (mul base (r base (sub exp 1)))))) ;; => powH

(define (pow base exp) ((Y powH) base exp)) ;; => pow

(pow 2 0) ;; => 1
(pow 2 3) ;; => 8
(pow 3 2) ;; => 9
