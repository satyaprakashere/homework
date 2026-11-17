(ns advanced.recursion-schemes)

;; Hylomorphism: Anamorphism (unfold) followed by Catamorphism (fold)
(defn ana [f seed]
  (let [[val next-seed] (f seed)]
    (if (nil? next-seed)
      (list val)
      (cons val (lazy-seq (ana f next-seed))))))

(defn cata [f z coll]
  (if (empty? coll)
    z
    (f (first coll) (cata f z (rest coll)))))

(defn run-demo []
  (println "\n--- 1. Recursion Schemes Demo ---")
  ;; Factorial using hylo
  (let [unfold-fn (fn [n] (if (zero? n) [1 nil] [n (dec n)]))
        fold-fn (fn [x acc] (* x acc))]
    (println "Factorial of 5:" (cata fold-fn 1 (ana unfold-fn 5)))))
