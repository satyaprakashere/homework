(print "Running Macro Tests...") ;; => nil

(defmacro when (condition body) `(if ,condition ,body '())) ;; => nil
(defmacro unless (condition body) `(if ,condition '() ,body)) ;; => nil

(define x 10) ;; => x
(when (< x 20) (print "x is less than 20")) ;; => nil
(unless (> x 20) (print "x is not greater than 20")) ;; => nil

;; Test 'let' macro
(let ((a 1) (b 2)) (+ a b)) ;; => 3
(let ((foo 10) (bar 20)) (let ((baz 30)) (+ foo (+ bar baz)))) ;; => 60

;; Test 'and' macro
(and) ;; => true
(and true true) ;; => true
(and true false) ;; => false
(and true true 10) ;; => 10

;; Test 'or' macro
(or) ;; => false
(or false true) ;; => true
(or true false) ;; => true
(or false false 20) ;; => 20

;; Test 'cond' macro
(cond (false 1) (false 2) (else 3)) ;; => 3
(cond (true 1) (false 2) (else 3)) ;; => 1
(cond (false 1) (true 2) (else 3)) ;; => 2
(cond (false 1) ((< 1 2) (+ 1 3)) (else 5)) ;; => 4
