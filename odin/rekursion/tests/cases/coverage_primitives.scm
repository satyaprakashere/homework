;; coverage_primitives.scm

;; Arithmetic Edge Cases
(add) ;; => 0
(add 1.5 2.5) ;; => 4
(sub 0) ;; => 0
(sub 10 2.5) ;; => 7.5
(mul) ;; => 1
(mul 2 3.5) ;; => 7
(div 1) ;; => 1
(div 10 2) ;; => 5
(div 10 0.0) ;; => nil
(div 10.0 2 0 5) ;; => nil

;; List Errors
(first 10) ;; => nil
(rest "string") ;; => nil
(set_first (quote x) 10) ;; => nil
(set_rest true 20) ;; => nil
(cons 1 2 3) ;; => nil
(first) ;; => nil
(rest (quote (1 2)) (quote (3 4))) ;; => nil

;; Predicates
(is_null (quote ())) ;; => true
(is_null 10) ;; => false
(is_pair (cons 1 2)) ;; => true
(is_pair (array 1 2)) ;; => true
(is_number 1) ;; => true
(is_number 1.5) ;; => true
(is_number "1") ;; => false
(is_symbol (quote x)) ;; => true
(is_symbol "x") ;; => false
(is_boolean true) ;; => true
(is_boolean 0) ;; => false
(is_string "hi") ;; => true
(is_string (quote hi)) ;; => false
(is_procedure add) ;; => true
(is_procedure (lambda (x) x)) ;; => true
(is_procedure (quote x)) ;; => false

;; Converters
(number_to_string 123) ;; => "123"
(number_to_string 1.25) ;; => "1.250"
(number_to_string (quote x)) ;; => nil
(symbol_to_string (quote hello)) ;; => "hello"
(symbol_to_string 123) ;; => nil
(string_append "a" "b" "c") ;; => "abc"
(string_append "x" 10) ;; => "x10"
(string_append) ;; => ""

;; Equality
(eq (quote ()) (quote ()))
 ;; => true
(eq 1 1)
 ;; => true
(eq 1 1.0)
 ;; => false
(eq (cons 1 2) (cons 1 2))
 ;; => false
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
