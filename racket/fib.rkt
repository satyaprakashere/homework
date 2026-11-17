#lang racket

(define (fibonacci n)
    (define (fibs a b n)
        (if (< n 1) a (fibs b (+ a b) (- n 1))))
    (fibs 0 1 n))

(println (fibonacci 985))

; (define (fibonacci n) (fibs 0 1 n) where
;     (define (fibs a b n)
;         (if (< n 1) a (fibs b (+ a b) (- n 1)))))
; (println (fibonacci 985))
