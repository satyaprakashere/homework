#lang racket

(println "hello world")
(define x 10)
(println x)
(define (fibonacci n)
    (define (fibs a b n)
        (if (< n 1) a (fibs b (+ a b) (- n 1))))
    (fibs 0 1 n))
(println (fibonacci 98765))
