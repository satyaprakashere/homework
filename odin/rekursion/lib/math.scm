;; Numerical & Set Utilities

;; 1. Numerical Constants & Basic Functions
(define (abs n)
  (if (less_than n 0) (sub 0 n) n))

(define (max a b)
  (if (greater_than a b) a b))

(define (min a b)
  (if (less_than a b) a b))

;; 2. Number Theory
(define (gcd a b)
  (if (eq? b 0)
      (abs a)
      (recur b (rem a b))))

(define (lcm a b)
  (if (or (eq? a 0) (eq? b 0))
      0
      (abs (div (mul a b) (gcd a b)))))

(define (prime? n)
  (if (less_than n 2)
      false
      (let ((helper (lambda (i)
                     (if (greater_than (mul i i) n)
                         true
                         (if (eq? (rem n i) 0)
                             false
                             (recur (add i 1)))))))
        (helper 2))))

;; 3. Set Operations (represented as lists)
(define (is-member x lst)
  (if (is-null lst)
      false
      (if (eq? x (first lst))
          true
          (recur x (rest lst)))))

(define (adjoin x lst)
  (if (is-member x lst)
      lst
      (cons x lst)))

(define (union lst1 lst2)
  (if (is-null lst1)
      lst2
      (recur (rest lst1) (adjoin (first lst1) lst2))))

(define (intersection lst1 lst2)
  (define (helper l acc)
    (if (is-null l)
        acc
        (if (is-member (first l) lst2)
            (recur (rest l) (cons (first l) acc))
            (recur (rest l) acc))))
  (helper lst1 (quote ())))

(define (difference lst1 lst2)
  (define (helper l acc)
    (if (is-null l)
        acc
        (if (is-member (first l) lst2)
            (recur (rest l) acc)
            (recur (rest l) (cons (first l) acc)))))
  (helper lst1 (quote ())))

(define (subset? lst1 lst2)
  (if (is-null lst1)
      true
      (if (is-member (first lst1) lst2)
          (recur (rest lst1) lst2)
          false)))
