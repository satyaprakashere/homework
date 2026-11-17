(ns leetcode.binary-search)

;; Binary Search
;; Given an array of integers nums which is sorted in ascending order, 
;; and an integer target, write a function to search target in nums. 
;; If target exists, then return its index. Otherwise, return -1.

(defn search [nums target]
  (loop [left 0
         right (dec (count nums))]
    (if (> left right)
      -1
      (let [mid     (quot (+ left right) 2) ; Integer division
            mid-val (nth nums mid)]
        (cond
          (= mid-val target) mid
          (< mid-val target) (recur (inc mid) right)
          :else (recur left (dec mid)))))))

;; Test cases
(println "Search 9 in [-1 0 3 5 9 12]:" (search [-1 0 3 5 9 12] 9)) ; Expected: 4
(println "Search 2 in [-1 0 3 5 9 12]:" (search [-1 0 3 5 9 12] 2)) ; Expected: -1
(println "Search 5 in [5]:"             (search [5] 5))             ; Expected: 0
(println "Search 2 in [5]:"             (search [5] 2))             ; Expected: -1
