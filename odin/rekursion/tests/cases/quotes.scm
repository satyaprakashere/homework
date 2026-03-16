(define x 10) ;; => x
(define y (quote (2 3))) ;; => y

(quote (1 2 3)) ;; => (1 2 3)
(quasiquote (1 (comma x) 3)) ;; => (1 10 3)
(quasiquote (1 (comma-at y) 4)) ;; => (1 2 3 4)
(quasiquote (1 (2 (comma x)) 3)) ;; => (1 (2 10) 3)

;; Verified bug: quote should NOT expand commas
(quote (1 (comma x) 3)) ;; => (1 (comma x) 3)
(quote (1 (comma-at y) 4)) ;; => (1 (comma-at y) 4)
