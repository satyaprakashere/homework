;; Standard Primitives of mu-recursion theory

;; 1. Zero function: Z(x) = 0
(define (zero . x) 0)

;; 2. Successor function: S(x) = x + 1
(define (succ x) (add x 1))

;; 3. Projection function: P^n_i(x1, ..., xn) = xi
;; Returns a function of n arguments that returns the i-th argument.
;; Indices are 1-based.
(define (proj n i)
  (lambda args
    (define (nth lst k)
       (if (eq k 1)
           (first lst)
           (recur (rest lst) (sub k 1))))
    (nth args i)))

;; 4. Composition: f(g1(x...), g2(x...), ..., gm(x...))
;; (compose f g1 g2 ...) returns a function h s.t. h(x...) = f(g1(x...), ...)
(define (compose f . gs)
  (lambda args
    (apply f (fmap (lambda (g) (apply g args)) gs))))

;; 5. Primitive Recursion
;; (prim-rec f g) returns h s.t.
;; h(0, x...) = f(x...)
;; h(S(n), x...) = g(n, h(n, x...), x...)
(define (prim-rec f g)
  (lambda (n . x)
    (define (helper m current-val)
       (if (eq m n)
           current-val
           (recur (add m 1) (apply g (cons m (cons current-val x))))))
    (helper 0 (apply f x))))

;; 6. Mu-operator (Minimization)
;; (mu-operator pred) returns the smallest n such that (pred n x...) = 0
(define (mu-operator pred)
  (lambda args
    (define (helper n)
       (if (eq 0 (apply pred (cons n args)))
           n
           (recur (add n 1))))
    (helper 0)))
