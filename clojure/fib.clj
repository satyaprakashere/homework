(ns hello)

(defn -main [& args]
	(println "Hello, World!"))

(println "Hello you")

(defn fib [n]
	(letfn [(fibH [a b n]
		(cond
			(= 0 n) a
			(= 1 n) b
			:else (fibH b (+ a b) (dec n))))]
		(fibH 0 1 n)))

(println (fib 90))
