;; Verification of mu-recursion theory primitives

(define (test-recursion)
  (define (check label actual expected)
    (if (eq? actual expected)
        (print label " OK")
        (print label " FAIL: expected " expected " got " actual)))

  ;; Primitives
  (check "zero" (zero 10 20) 0)
  (check "succ" (succ 5) 6)
  (check "proj" ((proj 3 2) 10 20 30) 20)

  ;; Composition
  (check "compose" ((compose succ (proj 1 1)) 5) 6)

  ;; Primitive Recursion (Addition)
  ;; h(0, y) = y  => f = (proj 1 1)
  ;; h(S(x), y) = S(h(x, y))  => g(x, prev, y) = S(prev)
  ;; g = (compose succ (proj 3 2))
  (let ((my-add (prim-rec (proj 1 1) (compose succ (proj 3 2)))))
    (check "prim-rec add" (my-add 3 5) 8))

  ;; Mu-operator (Minimization)
  ;; Find smallest n s.t. n - 5 = 0  => n = 5
  (let ((my-mu (mu-operator (lambda (n) (sub n 5)))))
     (check "mu-operator" (my-mu) 5))
)

(test-recursion)
