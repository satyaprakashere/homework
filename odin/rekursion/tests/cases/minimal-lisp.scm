true ;; => true
false ;; => false
(not true) ;; => false
(not false) ;; => true

(define x 10) ;; => x
x ;; => 10
(add 1 2) ;; => 3
(add x 5) ;; => 15

(cons 1 2) ;; => (1 . 2)
(first (cons 1 2)) ;; => 1
(rest (cons 1 2)) ;; => 2
(array 1 2 3) ;; => (1 2 3)

(define (+ a b) (add a b)) ;; => +
(+ 11 8) ;; => 19
(+ x 8) ;; => 18

(define arr (array 1 2 3)) ;; => arr
arr ;; => (1 2 3)
(+ x 1) ;; => 11
(define (list . x) x) ;; => list
(array 1 2 4 3) ;; => (1 2 4 3)

; (define (head-rest x . y) y);; nil
; (head-rest 1 2 3 4) ;; => (2 3 4)
; (head-rest 1) ;; => ()

; (define t (map)) ;; => t
; (set t (quote x) 10) ;; => 10
; (get t (quote x)) ;; => 10
; (define child (map)) ;; => child
; (set-parent child t) ;; => |map|
; (get child 'x) ;; => 10
; (set child 'x 20) ;; => 20
; (get child 'x) ;; => 20
; (get t 'x) ;; => 10
; (define (all . args) (and args)) ;; => all
; (all true false) ;; => false

(define (test name expected actual)
  (if (equal expected actual)
      (string-append "ML-PASS: " name)
      (string-append "ML-FAIL: " name " expected " expected " got "  actual)))
test ;; => |procedure|

(reset 1) ;; => 1
(reset (+ 1 2)) ;; => 3
(reset (+ 1 (shift k 5))) ;; => 5
(reset (+ 1 (shift k (k 2)))) ;; => 3
(reset (+ 1 (shift k (+ (k 2) (k 2))))) ;; => 6

(not true) ;; => false
(not false) ;; => true

(list 1 2 3) ;; => (1 2 3)
(length (list 1 2 3)) ;; => 3
(length (quote ())) ;; => 0
(length (quote (a b c))) ;; => 3

(append (quote (1 2)) (quote (3 4))) ;; => (1 2 3 4)
(reverse (quote (1 2 3))) ;; => (3 2 1)

(fmap (lambda (x) (add x 1)) (quote (1 2 3))) ;; => (2 3 4)
(fmap (lambda (x) (add x 1)) (quote (1 2 3))) ;; => (2 3 4)
; (filter (lambda (x) (= 0 (modulo x 2))) (quote (1 2 3 4 5))) ;; => (2 4)
(foldl (lambda (acc x) (add acc x)) 0 (quote (1 2 3 4))) ;; => 10
(foldr (lambda (x acc) (add x acc)) 0 (quote (1 2 3 4))) ;; => 10

(let ((x 1) (y 2)) (add x y)) ;; => 3
(and true 3) ;; => 3
(and false 3) ;; => false
(test "or true" 1 (or false 1 false)) ;; => "ML-PASS: or true"
(test "or false" false (or false false)) ;; => "ML-PASS: or false"

; (test "cond 1" 2 (cond (false 1) (true 2) (else 3))) ;; => "ML-PASS: cond 1"
; (test "cond else" 3 (cond (false 1) (false 2) (else 3))) ;; => "ML-PASS: cond else"
