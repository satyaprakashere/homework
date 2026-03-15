(define (test name expected actual)
  (if (equal expected actual)
      (print (string-append "STDLIB-PASS: " name))
      (print (string-append "STDLIB-FAIL: " name " | expected " (number->string expected) " got " (number->string actual))))); => test

(test "list" '(1 2 3) (list 1 2 3)); => nil
(test "length empty" 0 (length '())); => nil
(test "length non-empty" 3 (length '(a b c))); => nil

(test "append" '(1 2 3 4) (append '(1 2) '(3 4))); => nil
(test "reverse" '(3 2 1) (reverse '(1 2 3))); => nil

(test "map" '(2 3 4) (map (lambda (x) (add x 1)) '(1 2 3))); => nil
(test "foldl" 10 (foldl (lambda (acc x) (add acc x)) 0 '(1 2 3 4))); => nil
(test "foldr" 10 (foldr (lambda (x acc) (add x acc)) 0 '(1 2 3 4))); => nil

(test "let" 3 (let ((x 1) (y 2)) (add x y))); => nil
(test "and true" 3 (and true 3)); => nil
(test "and false" false (and false 3)); => nil
(test "or true" 1 (or false 1 false)); => nil
(test "or false" false (or false false)); => nil

(test "cond 1" 2 (cond (false 1) (true 2) (else 3))); => nil
(test "cond else" 3 (cond (false 1) (false 2) (else 3))); => nil

(and) ;; => true
(and true true) ;; => true
(and true false) ;; => false
(and true true 10) ;; => 10

(or) ;; => false
(or false true) ;; => true
(or true false) ;; => true
(or false false 20) ;; => 20