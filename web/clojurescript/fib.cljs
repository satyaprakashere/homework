(ns fib)

(defn fibH [a b n]
  (cond
    (= 0 n) a
    :else (recur b (unsigned-bit-shift-right (+ a b) 0) (dec n))))

(defn fib [n]
  (fibH 0 1 n))

(def n 98765432)
(println "fibonacci of " n ": " (fib n))