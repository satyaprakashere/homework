(define (list . x) x);; nil
(list 1 2 3) ;; => (1 2 3)
(define (head-rest x . y) y);; nil
(head-rest 1 2 3 4) ;; => (2 3 4)
(head-rest 1) ;; => ()
