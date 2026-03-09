(define (test name expected actual)
  (if (equal expected actual)
      (print (string-append "PASS: " name))
      (print (string-append "FAIL: " name " | expected " (number->string expected) " got " (number->string actual)))))

(test "not #t" false (not true)); => nil
(test "not #f" true (not false)); => nil

(test "caar" 1 (caar '((1 2) 3))); => nil
(test "cadr" 2 (cadr '(1 2 3))); => nil

(test "list" '(1 2 3) (list 1 2 3)); => nil
(test "length empty" 0 (length '())); => nil
(test "length non-empty" 3 (length '(a b c))); => nil

(test "append" '(1 2 3 4) (append '(1 2) '(3 4))); => nil
(test "reverse" '(3 2 1) (reverse '(1 2 3))); => nil

(test "map" '(2 3 4) (map (lambda (x) (+ x 1)) '(1 2 3))); => nil
(test "foldl" 10 (foldl (lambda (acc x) (+ acc x)) 0 '(1 2 3 4))); => nil
(test "foldr" 10 (foldr (lambda (x acc) (+ x acc)) 0 '(1 2 3 4))); => nil

(test "let" 3 (let ((x 1) (y 2)) (+ x y))); => nil
(test "and true" 3 (and true 3)); => nil
(test "and false" false (and false 3)); => nil
(test "or true" 1 (or false 1 false)); => nil
(test "or false" false (or false false)); => nil

(test "cond 1" 2 (cond (false 1) (true 2) (else 3))); => nil
(test "cond else" 3 (cond (false 1) (false 2) (else 3))); => nil
