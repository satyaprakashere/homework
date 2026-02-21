(defprotocol Recursive
  (project [node])  ; Defines how to decompose a structure
  (embed [node]))   ; Defines how to reassemble a structure

(extend-type Long
  Recursive
  (project [n]
    (if (zero? n)
      nil
      [(mod n 10) (quot n 10)]))  ; Extracts digits (last digit first)
  (embed [digits]
    (reduce (fn [acc x] (+ (* acc 10) x)) 0 digits)))  ; Constructs number from digits

(defn hylo [project embed seed]
  (let [result (project seed)]
    (if (nil? result)
      (embed [])
      (embed (map #(hylo project embed %) result)))))

(defn reverse-int [n]
  (hylo project embed n))

;(reverse-int 12345)  ; => 54321
;(reverse-int 987654) ; => 456789
(reverse-int 100)    ; => 1
;(reverse-int 0)      ; => 0