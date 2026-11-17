(define (run-demo)
  (display "\n--- 1. Scheme Continuations Demo ---\n")
  (call-with-current-continuation
   (lambda (exit)
     (for-each (lambda (x)
                 (if (negative? x) (exit x) (display x)))
               '(1 2 -3 4))
     (display "Done\n"))))
