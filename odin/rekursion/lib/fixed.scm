;; Advanced Fixed-Point Combinators

;; Turing's Fixed-point Combinator (Theta)
;; Theta = (λx. λy. y (x x y)) (λx. λy. y (x x y))
(define Theta
  ((lambda (x) (lambda (y) (y (lambda args (apply ((x x) y) args)))))
   (lambda (x) (lambda (y) (y (lambda args (apply ((x x) y) args)))))))

;; Omega Combinator (Self-application)
;; This will loop infinitely if evaluated: ((lambda (x) (x x)) (lambda (x) (x x)))
(define Omega-proc (lambda (x) (x x)))

;; Y and Z are already in combinator.scm, but sometimes variants are useful.
;; This file can be expanded with more exotic fixed-point operators.
