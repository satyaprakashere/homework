(ns fib)

(defn -main [& _]
  (println "Hello, World!"))

(println "Hello you")

(defn fib [^long n]
  (letfn [(fibH [^long a ^long b ^long n])]
     (cond
      (= 0 n) a
      :else (recur b (unchecked-add a b) (dec n)))
     (fibH 0 1 n)))

(println (fib 98765432))
