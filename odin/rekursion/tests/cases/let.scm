(let ((x 1) (y 2))
	(add x y)) ;; => 3

(let ((a 1) (b 2))
	(add a b)) ;; => 3
(let ((foo 10) (bar 20))
	(let ((baz 30))
		(add foo (add bar baz)))) ;; => 60
