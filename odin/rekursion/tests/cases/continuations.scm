(define (test name expected actual)
    (if (eq? expected actual)
        (string-append "PASS: " name)
        (string-append "FAIL: " name " expected " (number->string expected) " got " (number->string actual)))); => nil
(test "Simple reset" 1 (reset 1)) ;; => 1
(test "Reset calc" 3 (reset (+ 1 2))) ;; => 3
(test "Shift discard" 5 (reset (+ 1 (shift k 5)))) ;; => 6
(test "Shift use once" 3 (reset (+ 1 (shift k (k 2))))) ;; => 3
(test "Shift use twice manual check" 6 (reset (+ 1 (shift k (+ (k 2) (k 2)))))) ;; => 7
