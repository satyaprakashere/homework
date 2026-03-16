(define factH (lambda (r)
  (lambda (n)
    (if (less_than n 2)
        1
        (mul n (r (sub n 1))))))) ;; => factH

(define factorial (Z factH)) ;; => factorial

(factorial 0) ;; => 1
(factorial 1) ;; => 1
(factorial 4) ;; => 24

(define fibH (lambda (r)
  (lambda (n)
    (if (less_than n 2)
        n
        (add (r (sub n 1)) (r (sub n 2))))))) ;; => fibH

(define fib (Z fibH)) ;; => fib

(fib 0) ;; => 0
(fib 1) ;; => 1
(fib 5) ;; => 5

(define ackH (lambda (r)
  (lambda (m n)
    (cond ((numeq m 0) (add n 1))
          ((numeq n 0) (r (sub m 1) 1))
          (else (r (sub m 1) (r m (sub n 1)))))))) ;; => ackH

(define ack (Z ackH)) ;; => ack

(ack 1 1) ;; => 3
(ack 2 1) ;; => 5
