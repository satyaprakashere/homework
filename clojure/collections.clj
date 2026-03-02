
(def lst [1 2 3 4 5])
(println lst)

(def sets #{1 2 3 4 5})
(println sets)

(def maps {"a" 1 "b" 2 "c" 3})
(println maps)

(println (first lst))
(println (second lst))
(println (nth lst 2))
(println (last lst))

(println (map (fn [x] (+ x 1)) lst))

(defn add-one [x] (+ x 1))
(println (map add-one lst))

