(defn fibH [^long a ^long b ^long n]
  (cond
    (= 0 n) a
    :else (recur b (unchecked-add a b) (dec n))))

(defn fib [n]
  (fibH 0 1 n))

(def n 98765432)
(println "Fibonacci of " n ": " (fib n))