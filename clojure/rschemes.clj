(ns rschemes)

;; --- Protocols ---

(defprotocol Recursive
  (project [this] "Decomposes a structure (Coalgebra)"))

(defprotocol Corecursive
  (embed [this structure] "Reassembles a structure (Algebra)"))

;; Extend protocols for common Clojure sequences
(extend-protocol Recursive
  nil
  (project [_] nil) ; Base case: empty sequence

  clojure.lang.ISeq
  (project [t] [(first t) (next t)])

  clojure.lang.IPersistentCollection
  (project [t] (if (empty? t) nil [(first t) (next t)])))

;; --- Recursion Schemes ---

;; Catamorphism: Collapses a structure (Fold)
;; alg: a function that takes [head recursive-result] or nil
(defn cata [alg data]
  (if-let [[head tail] (project data)]
    (alg [head (cata alg tail)])
    (alg nil)))

;; Anamorphism: Builds a structure (Unfold)
;; coalg: a function that takes a seed and returns [data next-seed] or nil
(defn ana [coalg seed]
  (if-let [[head next-seed] (coalg seed)]
    (cons head (lazy-seq (ana coalg next-seed)))
    nil))

;; --- Examples ---

;; 1. Summing a list
(defn sum-alg [structure]
  (if (nil? structure)
    0
    (let [[head tail-sum] structure]
      (+ head tail-sum))))

;; 2. Factorial Algebra (for product)
(defn prod-alg [structure]
  (if (nil? structure)
    1
    (let [[head tail-prod] structure]
      (* head tail-prod))))

;; 3. Range Coalgebra (for unfold)
(defn range-coalg [n]
  (if (<= n 0)
    nil
    [n (dec n)]))

;; Usage
(println "Sum of (1 2 3 4):" (cata sum-alg [1 2 3 4]))     ; => 10
(println "Product of (1 2 3 4):" (cata prod-alg [1 2 3 4])) ; => 24
(println "Unfold 5 to 1:" (ana range-coalg 5))              ; => (5 4 3 2 1)

;; Hylomorphism: Factorial using ana + cata
(defn factorial [n]
  (cata prod-alg (ana range-coalg n)))

(println "Factorial 5:" (factorial 5)) ; => 120
