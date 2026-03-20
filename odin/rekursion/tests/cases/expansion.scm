;; Verification of Expanded Mathematical and Theoretical Libraries

(define (test-expansion)
  (define (check label actual expected)
    (if (eq? actual expected)
        (print label " OK")
        (print label " FAIL: expected " expected " got " actual)))

  ;; 1. Church Encodings
  (check "church numeral add" (church->int (church-add church2 church3)) 5)
  (check "church numeral mul" (church->int (church-mul church2 church3)) 6)
  (check "int->church conversion" (church->int (int->church 10)) 10)
  (check "church boolean if" (church-if church-true 1 0) 1)

  ;; 2. Extended Logic
  (check "xor true true" (xor true true) false)
  (check "xor true false" (xor true false) true)
  (check "nand true true" (nand true true) false)
  (check "implies true false" (implies true false) false)

  ;; 3. Peano Arithmetic
  (check "peano add" (peano->int (peano-add (int->peano 3) (int->peano 4))) 7)
  (check "peano mul" (peano->int (peano-mul (int->peano 3) (int->peano 4))) 12)

  ;; 4. Math Utilities
  (check "gcd" (gcd 48 18) 6)
  (check "lcm" (lcm 12 15) 60)
  (check "prime? 7" (prime? 7) true)
  (check "prime? 9" (prime? 9) false)

  ;; 5. Set Utilities
  (let ((s1 (list 1 2 3))
        (s2 (list 3 4 5)))
    (check "union size" (length (union s1 s2)) 5)
    (check "intersection" (first (intersection s1 s2)) 3)
    (check "subset?" (subset? (list 1 2) s1) true))

  ;; 6. Fixed-Point (Theta)
  (let ((fact (Theta (lambda (f)
                       (lambda (n)
                         (if (eq? n 0)
                             1
                              (mul  n (f (sub n 1)))))))))
    (check "Theta fact" (fact 5) 120))
)

(test-expansion)
