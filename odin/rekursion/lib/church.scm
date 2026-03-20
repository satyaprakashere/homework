;; Church Encodings (Numerals & Booleans)

;; Church Numerals
;; A numeral n is a higher-order function that applies a function f, n times to an initial value x.
(define church0 (lambda (f) (lambda (x) x)))
(define church1 (lambda (f) (lambda (x) (f x))))
(define church2 (lambda (f) (lambda (x) (f (f x)))))
(define church3 (lambda (f) (lambda (x) (f (f (f x))))))

;; Successor: S n = f(n f x)
(define (church-succ n)
  (lambda (f) (lambda (x) (f ((n f) x)))))

;; Addition: n + m = n S m
(define (church-add n m)
  (lambda (f) (lambda (x) ((n f) ((m f) x)))))

;; Multiplication: n * m = n (m f) x
(define (church-mul n m)
  (lambda (f) (n (m f))))

;; Exponentiation: b^e = e b
(define (church-pow b e)
  (e b))

;; Church Booleans
(define church-true  (lambda (t) (lambda (f) t)))
(define church-false (lambda (t) (lambda (f) f)))

;; Logical Operations
(define (church-if p t f) ((p t) f))
(define (church-and p q)  ((p q) p))
(define (church-or p q)   ((p p) q))
(define (church-not p)    ((p church-false) church-true))

;; Conversion to/from standard types
(define (church->int n)
  ((n (lambda (x) (add x 1))) 0))

;; Iterative conversion from int to church
(define (int->church n)
  (define (helper m acc)
    (if (eq? m 0)
        acc
        (recur (sub m 1) (church-succ acc))))
  (helper n church0))
