(ns collections)

(def a-vector [1 2 3])                              ; Vectors are for indexed access (O(1) append/nth)
(def a-list  '(1 2 3))                              ; Lists are for stack-like access (O(1) prepend/first)
(def a-set   #{1 2 3})                              ; Sets are for unique values
(def a-map    {:a 1 :b 2 :c 3})                     ; Maps are for key-value pairs (use keywords as keys!)

;; --- 2. Modification (Immutability) ---
;; Remember: These functions don't change the original; they return a NEW version.

(println "Conj (vector):"  (conj a-vector 4))       ; Appends to vector
(println "Conj (list):"    (conj a-list 4))         ; Prepends to list
(println "Assoc (map):"    (assoc a-map :d 4))      ; Adds/updates key
(println "Dissoc (map):"   (dissoc a-map :a))       ; Removes key
(println "Into (merging):" (into a-vector a-list))  ; Merges one coll into another
(println "Into (merging):" (into a-list a-vector))  ; Merges one coll into another


;; --- 3. Deep Access & Updates ---

(def users {:prakash {:age 25 :skills ["clojure" "python"]}
            :bob     {:age 30 :skills ["java"]}})

(println "Get-in:"    (get-in    users [:prakash :skills 0]))
(println "Update-in:" (update-in users [:bob :age] inc))
(println "Assoc-in:"  (assoc-in  users [:prakash :location] "India"))

;; --- 4. Threading Macros (-> and ->>) ---
;; -> (Thread-first): Inserts result as FIRST argument. Good for map transformations.
(println "Thread-first:"
         (-> users
             (assoc-in [:alice :age] 28)
             (update :prakash dissoc :skills)
             (keys)))

;; ->> (Thread-last): Inserts result as LAST argument. Good for sequence processing.
(println "Thread-last:"
         (->> (range 10)
              (filter odd?)
              (map #(* % %))
              (reduce +)))

;; --- 5. Destructuring ---
;; Sequential
(let [[x y & rest] [1 2 3 4 5]]
  (println "De-structured Sequential:" x y rest))

;; Map
(let [{:keys [a b] :or {a 0}} {:b 10}]
  (println "De-structured Map:" a b))
;(println "De-structured Map:" a b where
; ([{:keys [a b]
;     :or {a 0}}
;   {:b 10}]))

;; --- 6. Advanced Sequence Functions ---
(def data
  [{:name "Alice" :role :admin :score 100}
   {:name "Bob"   :role :user  :score 80}
   {:name "Charlie" :role :user :score 90}])

(println "Group-by role:" (group-by :role data))
(println "Frequencies:"   (frequencies [:a :b :a :c :a :b]))
(println "Sort-by score:" (sort-by :score > data))
  