#lang racket
(require racket/fixnum)

(define INT_MAX (most-positive-fixnum))
(print "INT_MAX: ")
INT_MAX
(define (fibonacci n)
    (define (fibs a b n)
        (if (< n 1) a (fibs b (remainder (+ a b) INT_MAX) (- n 1))))
    (fibs 0 1 n))
(println (fibonacci 9876543))
