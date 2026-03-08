#lang racket

(function (fib n) (fibonacci 0 1 n))

(function (fibonacci a b n)
	(if (= 0 n) a
	(recur (b) (a+b) (n-1))))