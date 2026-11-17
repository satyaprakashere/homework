(ns leetcode.two-sum)

;; Two Sum
;; Given an array of integers nums and an integer target, 
;; return indices of the two numbers such that they add up to target.

(defn two-sum [nums target]
  (loop [index 0
         seen {}] ; seen is a map of value -> index
    (if (>= index (count nums))
      nil
      (let [num (nth nums index)
            complement (- target num)]
        (if-let [complement-index (get seen complement)]
          [complement-index index]
          (recur (inc index) (assoc seen num index)))))))

;; Test cases
(println "Two Sum [2 7 11 15] target 9:" (two-sum [2 7 11 15] 9))    ; Expected: [0 1]
(println "Two Sum [3 2 4] target 6:" (two-sum [3 2 4] 6))          ; Expected: [1 2]
(println "Two Sum [3 3] target 6:" (two-sum [3 3] 6))              ; Expected: [0 1]
