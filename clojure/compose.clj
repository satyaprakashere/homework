(ns compose)

;; --- 1. Basic Composition ---
(defn add-one [x]
  (+ x 1))

(defn triple [x]
  (* x 3))

;; Your manual compose: (f(g(x)))
(defn manual-compose [f g]
  (fn [x] (f (g x))))

(println "Manual Compose (1 + 1) * 3 =" ((manual-compose triple add-one) 1))

;; --- 2. Built-in 'comp' ---
;; 'comp' can take any number of functions and composes them from RIGHT to LEFT

(def triple-then-add-one-then-square
  (comp #(* % %) add-one triple))

(println "Built-in comp (1 * 3 + 1)^2 =" (triple-then-add-one-then-square 1))

;; --- 3. Partial Application ---
;; 'partial' takes a function and fewer than its required arguments, 
;; returning a new function that takes the rest

(def add-five (partial + 5))

(println "Partial (5 + 10) =" (add-five 10))

;; --- 4. Juxtaposition (juxt) ---
;; 'juxt' takes several functions and returns a function that applies 
;; all of them to its arguments, returning a vector of results

(def sum 	(partial apply +))
(def avg
  (comp (partial apply /)
        (juxt sum count)))

(def stats 	(juxt count sum avg))

(println "Juxt [count, sum, avg] of [1 2 3 4 5] =" (stats [1 2 3 4 5]))

;; --- 5. Complement ---
;; 'complement' takes a predicate and returns a function that yields the opposite.

(def not-empty? (complement empty?))

(println "Complement (not-empty? []) =" (not-empty? []))
(println "Complement (not-empty? [1]) =" (not-empty? [1]))

;; --- 6. Memoization ---
;; 'memoize' returns a version of the function that caches results

(defn slow-calc [x]
  (Thread/sleep 500)
  (* x x))

(def fast-calc (memoize slow-calc))

(println "First call (slow)...")

(time (fast-calc 10))

(println "Second call (fast)...")

(time (fast-calc 10))

;; --- 7. Constantly ---
;; Returns a function that always returns the same value

(def always-ten (constantly 10))

(println "Constantly (always 10) =" (always-ten :ignored))
