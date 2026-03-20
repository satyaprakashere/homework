;; Peano Arithmetic (Axiomatic Numerals)

;; A Peano numeral is represented as a tagged list:
;; 0 is (quote (peano-zero))
;; S(n) is (cons (quote peano-succ) (cons n (quote ())))

(define peano-zero (list (quote peano-zero)))

(define (peano-succ n)
  (list (quote peano-succ) n))

(define (is-peano-zero n)
  (eq? (first n) (quote peano-zero)))

;; Comparison
(define (peano-eq? n m)
  (if (is-peano-zero n)
      (is-peano-zero m)
      (if (is-peano-zero m)
          false
          (recur (first (rest n)) (first (rest m))))))

;; Addition: n + m
(define (peano-add n m)
  (define (helper a b)
    (if (is-peano-zero a)
        b
        (recur (first (rest a)) (peano-succ b))))
  (helper n m))

;; Multiplication: n * m
(define (peano-mul n m)
  (define (helper a b acc)
    (if (is-peano-zero a)
        acc
        (recur (first (rest a)) b (peano-add acc b))))
  (helper n m (quote (peano-zero))))

;; Utility to/from int
(define (peano->int n)
  (define (helper m acc)
    (if (is-peano-zero m)
        acc
        (recur (first (rest m)) (add acc 1))))
  (helper n 0))

(define (int->peano n)
  (define (helper m acc)
    (if (eq? m 0)
        acc
        (recur (sub m 1) (peano-succ acc))))
  (helper n peano-zero))
