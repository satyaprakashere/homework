#lang racket

(define-syntax-rule (swap x y)
  (let ([tmp x])
    (set! x y)
    (set! y tmp)))

(define (run-demo)
  (displayln "\n--- 1. Racket Macro Demo ---")
  (define a 1)
  (define b 2)
  (swap a b)
  (printf "a: ~a, b: ~a\n" a b))
