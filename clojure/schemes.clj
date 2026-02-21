(ns schemes)

(defn multiply
  ([] 1)
  ([a b] (unchecked-multiply a b)))

(defn decrease [n]
  (if (zero? n)
    nil
    [n (dec n)]))

(defn unfold [f seed]
  (lazy-seq
    (if-let [[x next-seed] (f seed)]
      (cons x (unfold f next-seed))
      nil)))

(defn ends-with-9 [n]
  (+ n 10))

(defn refold [coalg alg seed]
  (reduce (fn [acc x] (alg x acc))
          (alg)
          (reverse (unfold coalg seed))))

(defn factorial [n]
  (refold decrease multiply n))

(defn fib [n]
  (refold decrease add-last-two n))

(defn fibonacci [n]
  (letfn [(add-last-two [[a b]]
            [b (+ a b)])]
    (map first (take n (iterate add-last-two [0 1])))))

;; Usage
(println "Factorial (98765):" (factorial 987654))
(println "Unfold (5):" (unfold decrease 5))
(println "Fibonacci (10):" (fibonacci 10))
