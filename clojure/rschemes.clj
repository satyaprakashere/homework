(ns rschemes)
(require '[clojure.core :refer [seq]])

;; (def ListF [a r] (ListF a r))

(defprotocol Recursive
  (project [t]))
(defprotocol Corecursive
  (embed [t]))

(extend-protocol Recursive
  clojure.lang.PersistentVector
  (project [t] [(first t) (seq (rest t))])
  
  clojure.lang.PersistentList
  (project [t] [(first t) (seq (rest t))])
  
  clojure.lang.PersistentVector$ChunkedSeq
  (project [t] [(first t) (seq (rest t))])
  
  clojure.lang.LazySeq
  (project [t] [(first t) (seq (rest t))])
  
  clojure.lang.IPersistentSet
  (project [t] [(first t) (seq (rest t))]))

(extend-protocol Corecursive
  clojure.lang.PersistentVector
  (embed [t] (flatten t))
  
  clojure.lang.PersistentList
  (embed [t] (flatten t))
  
  clojure.lang.LazySeq
  (embed [t] (flatten t)))


;; Catamorphism
(defn cata [alg data]
  (if (sequential? data)
    (let [[head tail] (project data)]
      (alg head (cata alg tail)))
    (alg data nil)))  ;; Base case for non-sequences

(print "hello")
(println (project (list 1 2 4)))
(println (project [1 2 3]))

(println (embed [1 [2 3]]))
(println (embed (list 1 (list 2 3))))

(defn sum-alg [seq]
  (apply + seq))

(println (mapcat inc [1 [2 4]]))
(println (sum-alg [1 2 3]))

;(println (cata sum-alg (list 1 2 3)))
;(print (project ())
;; (defn test-ana []
;;   (let [f (fn [x] [(+ x 1) (* x 2)])]
;;     (println "Ana:" (ana f 1))))
;; (test-ana)