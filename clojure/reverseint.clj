(ns reverseint)

;; Hylomorphism (hylo) is the composition of an anamorphism (unfold)
;; and a catamorphism (fold). 
;; hylo = fold . unfold

(defn unfold [coalg seed]
  (lazy-seq
   (if-let [[data next-seed] (coalg seed)]
     (cons data (unfold coalg next-seed))
     nil)))

(defn fold [alg initial-value coll]
  (reduce alg initial-value coll))

(defn reverse-int [n]
  (let [;; Coalgebra: decomposes the number into [last-digit, remaining]
        project (fn [n]
                  (if (zero? n)
                    nil
                    [(mod n 10) (quot n 10)]))
        ;; Algebra: combines the current digit with the accumulated result
        ;; acc = 3, digit = 2 => 3 * 10 + 2 = 32
        embed (fn [acc digit]
                (+ (* acc 10) digit))]
    (fold embed 0 (unfold project n))))

;; Test cases
(println "Reverse 12345:" (reverse-int 12345))   ; => 54321
(println "Reverse 987654:" (reverse-int 987654)) ; => 456789
(println "Reverse 100:" (reverse-int 100))       ; => 1
(println "Reverse 0:" (reverse-int 0))           ; => 0
