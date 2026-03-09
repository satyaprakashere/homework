(true); => true
(define x 10) ;; => x
x ;; => 10
(+ 1 2) ;; => 3
(+ x 5) ;; => 15
(cons 1 2) ;; => (1 . 2)
(first (cons 1 2)) ;; => 1
(rest (cons 1 2)) ;; => 2
(array 1 2 3) ;; => (1 2 3)
(define (add a b) (+ a b)) ;; => add
(add 11 8) ;; => 19
(add x 8) ;; => 18
(define arr (array 1 2 3)) ;; => arr
arr ;; => (1 2 3)
(+ x 1) ;; => 11
(define (list . x) x);; nil
(array 1 2 4 3) ;; => (1 2 4 3)
; (define (head-rest x . y) y);; nil
; (head-rest 1 2 3 4) ;; => (2 3 4)
; (head-rest 1) ;; => ()
(define t (table)) ;; => t
(set t 'x 10) ;; => 10
(get t 'x) ;; => 10
(define child (table)) ;; => child
(set-parent child t) ;; => |table|
(get child 'x) ;; => 10
(set child 'x 20) ;; => 20
(get child 'x) ;; => 20
(get t 'x) ;; => 10
(define (all . args) (and args));; => all
; (all true false) ;; => false
(define (test name expected actual) (if (eq? expected actual) (print (string-append "PASS: " name)) (print (string-append "FAIL: " name " expected " (number->string expected) " got " (number->string actual)))));; => test
test ;; => |procedure|
(test "Simple reset" 1 (reset 1)) ;; => nil
(test "Reset calc" 3 (reset (+ 1 2))) ;; => nil
(test "Shift discard" 5 (reset (+ 1 (shift k 5)))) ;; => nil
(test "Shift use once" 3 (reset (+ 1 (shift k (k 2))))) ;; => nil
(test "Shift use twice manual check" 6 (reset (+ 1 (shift k (+ (k 2) (k 2)))))) ;; => nil

(test "not #t" false (not true)) ;; => nil
(test "not #f" true (not false)) ;; => nil

(test "caar" 1 (caar '((1 2) 3))) ;; => nil
(test "cadr" 2 (cadr '(1 2 3))) ;; => nil

(test "list" '(1 2 3) (list 1 2 3)) ;; => nil
(test "length empty" 0 (length '())) ;; => nil
(test "length non-empty" 3 (length '(a b c))) ;; => nil

(test "append" '(1 2 3 4) (append '(1 2) '(3 4))) ;; => nil
(test "reverse" '(3 2 1) (reverse '(1 2 3))) ;; => nil

(test "map" '(2 3 4) (map (lambda (x) (+ x 1)) '(1 2 3))) ;; => nil
; (test "filter" '(2 4) (filter (lambda (x) (= 0 (modulo x 2))) '(1 2 3 4 5))) ;; => nil
(test "foldl" 10 (foldl (lambda (acc x) (+ acc x)) 0 '(1 2 3 4))) ;; => nil
(test "foldr" 10 (foldr (lambda (x acc) (+ x acc)) 0 '(1 2 3 4))) ;; => nil

(test "let" 3 (let ((x 1) (y 2)) (+ x y))) ;; => nil
(test "and true" 3 (and true 3)) ;; => nil
(test "and false" false (and false 3)) ;; => nil
(test "or true" 1 (or false 1 false)) ;; => nil
(test "or false" false (or false false)) ;; => nil

; (test "cond 1" 2 (cond (false 1) (true 2) (else 3))) ;; => nil
; (test "cond else" 3 (cond (false 1) (false 2) (else 3))) ;; => nil
