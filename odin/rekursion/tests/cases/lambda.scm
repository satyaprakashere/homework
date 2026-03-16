(define + (lambda (a b) (add a b))) ;; => add
(+ 1 2) ;; => 3
(define fact (lambda (n)
	(if (eq? n 0)
	    1
	    (mul n (fact (sub n 1)))))) ;; => fact
(define factorial fact) ;; => factorial
(factorial 5) ;; => 120