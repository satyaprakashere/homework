;; Silent Error Verification Tests

;; Cons (expected 2 args)
(cons 1) ;; Error: cons expects 2 arguments, got 1

;; First (expected 1 arg)
(first) ;; Error: first expects 1 argument, got 0

;; First (expected pair)
(first 10) ;; Error: first expects a pair, got 10

;; Rest (expected pair)
(rest "hi") ;; Error: rest expects a pair, got "hi"

;; Arithmetic (expected numbers)
(add 1 "a") ;; Error: add expects numbers, got "a"
(sub 1 true) ;; Error: sub expects numbers, got true
(mul 1 (quote x)) ;; Error: mul expects numbers, got x
(div 1 0) ;; Error: Division by zero

;; Converters
(number-to-string "not-a-number") ;; Error: number-to-string expects a number, got "not-a-number"
(symbol-to-string 123) ;; Error: symbol-to-string expects a symbol, got 123
