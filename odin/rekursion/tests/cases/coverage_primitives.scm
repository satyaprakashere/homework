;; coverage_primitives.scm

;; Arithmetic Edge Cases
(add) ;; => 0
(add 1.5 2.5) ;; => 3
(sub) ;; => 0
(sub 10 2.5) ;; => 8
(mul) ;; => 1
(mul 2 3.5) ;; => 6
(div) ;; => 1
(div 10 2) ;; => 5
(div 10 0) ;; => nil
(div 10 2 0 5) ;; => nil

;; List Errors
(first 10) ;; => nil
(rest "string") ;; => nil
(set-first! (quote x) 10) ;; => nil
(set-rest! true 20) ;; => nil
(cons 1 2 3) ;; => nil
(first) ;; => nil
(rest (quote (1 2)) (quote (3 4))) ;; => nil

;; Predicates
(is-null (quote ())) ;; => true
(is-null 10) ;; => false
(is-pair (cons 1 2)) ;; => true
(is-pair (array 1 2)) ;; => true
(is-number 1) ;; => true
(is-number 1.5) ;; => true
(is-number "1") ;; => false
(is-symbol (quote x)) ;; => true
(is-symbol "x") ;; => false
(is-boolean true) ;; => true
(is-boolean 0) ;; => false
(is-string "hi") ;; => true
(is-string (quote hi)) ;; => false
(is-procedure add) ;; => true
(is-procedure (lambda (x) x)) ;; => true
(is-procedure (quote x)) ;; => false

;; Converters
(number-to-string 123) ;; => "123"
(number-to-string 1.25) ;; => "1.250"
(number-to-string (quote x)) ;; => nil
(symbol-to-string (quote hello)) ;; => "hello"
(symbol-to-string 123) ;; => nil
(string-append "a" "b" "c") ;; => "abc"
(string-append "x" 10) ;; => "x10"
(string-append) ;; => ""

;; Equality
(eq? (quote ()) (quote ())) ;; => true
(eq? 1 1) ;; => true
(eq? 1 1.0) ;; => false
(eq? (cons 1 2) (cons 1 2)) ;; => false
(equal (cons 1 (cons 2 3)) (cons 1 (cons 2 3))) ;; => true
(equal (array 1 2) (array 1 2)) ;; => true
(equal (array 1 2) (array 1 3)) ;; => false
(numeq 1 1.0 1) ;; => true
(numeq 1 2) ;; => false
(numeq 1) ;; => true
(less_than 1 2 3) ;; => true
(less_than 1 1) ;; => false
(greater_than 3 2 1) ;; => true
(greater_than 1 2) ;; => false
