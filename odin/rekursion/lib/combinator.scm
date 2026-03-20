;; Combinators (from Combinatory Logic)

;; I (Identity): I x = x
(define I (lambda (x) x))

;; K (Constant): K x y = x
(define K (lambda (x) (lambda (y) x)))

;; S (Substitution): S x y z = (x z) (y z)
(define S (lambda (x) (lambda (y) (lambda (z) ((x z) (y z))))))

;; B (Composition): B x y z = x (y z)
(define B (lambda (x) (lambda (y) (lambda (z) (x (y z))))))

;; C (Exchange): C x y z = x z y
(define C (lambda (x) (lambda (y) (lambda (z) ((x z) y)))))

;; W (Duplication): W x y = x y y
(define W (lambda (x) (lambda (y) ((x y) y))))

;; Y (Fixed-point combinator for lazy/call-by-name)
(define Y
  (lambda (f)
    ((lambda (x) (f (lambda args (apply (x x) args))))
     (lambda (x) (f (lambda args (apply (x x) args)))))))

;; Z (Fixed-point combinator for strict/call-by-value)
(define Z
  (lambda (f)
    ((lambda (x) (f (lambda args (apply (x x) args))))
     (lambda (x) (f (lambda args (apply (x x) args)))))))
