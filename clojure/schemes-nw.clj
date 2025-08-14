(ns recursion-schemes.core)

(defn multiply [[a b]]
  (* a b))

(defn unfold [f seed]
  (when seed
    (lazy-seq (cons seed (unfold f (f seed))))))

(defn decrease [n]
  (if (zero? n) nil [n (dec n)]))

(defn ends-with-9 [n]
  (+ n 10))

(defn refold [coalg alg seed]
    (alg (cons seed (refold coalg alg (coalg seed)))))

(defn factorial [n]
  (refold decrease multiply n))

(defn fibonacci [n]
  (letfn [(add-last-two [[a b]]
            [b (+ a b)])]
    (map first (take n (iterate add-last-two [0 1])))))

;; Usage
(println "Factorial:" (unfold decrease 5))
;(println "Fibonacci:" (fibonacci 10))
(println "decrease" (multiply [5 4]))
