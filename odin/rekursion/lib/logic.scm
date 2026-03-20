;; Extended Boolean Logic

;; Standard logical operations beyond NOT, AND, OR
(define (xor p q)
  (if p (if q false true) q))

(define (nand p q)
  (if p (if q false true) true))

(define (nor p q)
  (if p false (if q false true)))

(define (implies p q)
  (if p q true))

(define (iff p q)
  (if p q (if q false true)))
