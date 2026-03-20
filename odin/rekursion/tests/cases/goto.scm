(define (is-zero n) (eq n 0))

(define (even n)
  (if (is-zero n) true (goto odd (sub n 1))))

(define (odd n)
  (if (is-zero n) false (goto even (sub n 1))))

(even 100) ;; => true
(odd 100)  ;; => false
(even 101) ;; => false
(odd 101)  ;; => true
