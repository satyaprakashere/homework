;; Test Feature Completeness (Step 6)

;; 1. List Operations
(assert (eq (length (quote ())) 0))
(assert (eq (length (quote (1 2 3))) 3))

(assert (equal (append (quote (1 2)) (quote (3 4))) (quote (1 2 3 4))))
(assert (equal (append (quote (1)) (quote (2)) (quote (3 4))) (quote (1 2 3 4))))
(assert (equal (append (quote ())) (quote (1 2))) (quote (1 2)))
(assert (eq (append (quote (1 2)) (quote ())) (quote (1 2))))

(assert (equal (reverse (quote (1 2 3))) (quote (3 2 1))))
(assert (equal (reverse (quote ())) (quote ())))

(assert (eq (list-ref (quote (a b c)) 1) (quote b)))

;; 2. Membership and Assoc
(assert (member 2 (quote (1 2 3))))
(assert (not (member 4 (quote (1 2 3)))))
(assert (memq (quote b) (quote (a b c))))

(define alist (quote ((a . 1) (b . 2) (c . 3))))
(assert (equal (assoc (quote b) alist) (quote (b . 2))))
(assert (not (assoc (quote d) alist)))

;; 3. Aliases
(assert (is_null (quote ())))
(assert (not (is_null (quote (1)))))
(assert (is_pair (quote (1 . 2))))
(assert (is_number 123))
(assert (is_symbol (quote x)))
(assert (is_boolean true))
(assert (is_string "hello"))

;; 4. I/O (Manual verification mostly, but calling them to ensure they exist)
(display "Testing display and newline...\n")
(newline)

(print "Feature Completeness Tests Passed!")
