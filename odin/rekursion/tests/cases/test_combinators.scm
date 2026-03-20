;; Verification of combinator primitives

(define (test-combinators)
  (define (check label actual expected)
    (if (eq? actual expected)
        (print label " OK")
        (print label " FAIL: expected " expected " got " actual)))

  ;; I (Identity)
  (check "I" (I 10) 10)

  ;; K (Constant)
  (check "K" ((K 10) 20) 10)

  ;; S (Substitution)
  ;; SKK = I
  (check "SKK" (((S K) K) 5) 5)

  ;; B (Composition)
  (check "B" (((B succ) succ) 5) 7)

  ;; C (Exchange)
  ;; C K x y = K y x = y
  (check "C" (((C K) 10) 20) 20)

  ;; W (Duplication)
  ;; W K x = K x x = x
  (check "W" ((W K) 10) 10)

  ;; Y/Z Combinators (Fixed-point)
  ;; Simplified fact using Z
  (let ((fact (Z (lambda (f)
                   (lambda (n)
                     (if (eq? n 0)
                         1
                         (* n (f (sub n 1)))))))))
    (check "Z fact" (fact 5) 120))
)

(test-combinators)
