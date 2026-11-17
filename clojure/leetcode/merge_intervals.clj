(ns leetcode.merge-intervals)

;; Merge Intervals
;; Given an array of intervals where intervals[i] = [starti, endi],
;; merge all overlapping intervals, and return an array of the non-overlapping 
;; intervals that cover all the intervals in the input.

(defn merge-intervals [intervals]
  (if (empty? intervals)
    []
    (let [sorted (sort-by first intervals)] ; Sort intervals by start time
      (reduce (fn [acc next-interval]
                (let [last-interval (last acc)]
                  (if (and last-interval (<= (first next-interval) (second last-interval)))
                    ;; Overlap: Update the end of the last interval in acc
                    (conj (vec (butlast acc)) 
                          [(first last-interval) (max (second last-interval) (second next-interval))])
                    ;; No overlap: Append the new interval
                    (conj acc next-interval))))
              [(first sorted)] ; Initial accumulator with the first sorted interval
              (rest sorted)))))

;; Test cases
;; Expected: [[1 6] [8 10] [15 18]]
(println "Merge [[1 3] [2 6] [8 10] [15 18]] :" (merge-intervals [[1 3] [2 6] [8 10] [15 18]]))

;; Expected: [[1 5]]
(println "Merge [[1 4] [4 5]] :" (merge-intervals [[1 4] [4 5]]))

;; Expected: [[0 4]]
(println "Merge [[1 4] [0 4]] :" (merge-intervals [[1 4] [0 4]]))
