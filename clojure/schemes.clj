(ns schemes)

;; --- Core Concepts ---

(defn unfold [f seed]
  (lazy-seq
   (if-let [[x next-seed] (f seed)]
     (cons x (unfold f next-seed))
     nil)))

;; A proper hylomorphism (refold) doesn't need to reverse the sequence.
;; It can either be a tail-recursive fold (reduce) or a recursive composition.
(defn refold [coalg alg initial-value seed]
  (reduce alg initial-value (unfold coalg seed)))

;; --- Building Blocks ---

(defn multiply [acc x]
  (*' acc x)) ; Using *' for auto-promoting to BigInt to avoid overflow

(defn decrease [n]
  (if (<= n 0)
    nil
    [n (dec n)]))

;; --- Implementations ---

(defn factorial [n]
  (refold decrease multiply 1 n)) ; 1N is a BigInt

(defn fibonacci [n]
  ;; Using iterate for fibonacci is very idiomatic in Clojure
  (let [next-fib (fn [[a b]] [b (+ a b)])]
    (map first (take n (iterate next-fib [0 1])))))

;; --- Usage ---

(println "Factorial (10):" (factorial 10))
(println "Factorial (50):" (factorial 50)) ; BigInt handles this easily
(println "Unfold (5):" (unfold decrease 5))
(println "Fibonacci (10):" (fibonacci 10))

;; Example of a custom refold: Sum of squares
(defn sum-squares [n]
  (refold decrease (fn [acc x] (+ acc (* x x))) 0 n))

(println "Sum of squares (5):" (sum-squares 5)) ; 1+4+9+16+25 = 55
