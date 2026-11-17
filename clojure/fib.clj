(ns fib)

(defn fibH [a b n]
  (cond
    (= 0 n) a
    :else (recur b (unchecked-add a b) (dec n))))

(defn fib [n]
  (fibH 0 1 n))

(def n 9876543)
(println "Fibonacci of " n ": " (fib n))
