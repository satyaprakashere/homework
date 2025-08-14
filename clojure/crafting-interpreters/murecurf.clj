(ns murecurf)

(defn compose
  ([] (comp []))
  ([f] (comp [] f))
  ([f g] (comp f g))
  ([f g & fs] (fn [& args]
                (apply f (map #(apply % args) (cons g fs))))))

(defn pcompose
  ([] (comp []))
  ([f] (comp [] f))
  ([f g] (comp f g))
  ([f g & fs] (fn [& args]
                (apply f (pmap #(apply % args) (cons g fs))))))

;; (defrecord Fix [unfix])

;; (defn fix [x] (->Fix x))
;; (defn unfix [F] (F (unfix F)))

(defprotocol Functor
  (fmap [f x]))

(defprotocol Recursive
  (project [f]))
(defprotocol Corecursive
  (embed [f]))

(defn precur [h]
  (comp h (partial fmap (precur h)) project))

(defn precurf [g h]
  (fn [] (comp (h g) (map (precurf g h)) project)))

(defn muop [] ())

(defrecord NilF [])
(defrecord ConsF [head tail])

(extend-protocol Functor
  NilF
  (fmap [_ _] (->NilF))
  ConsF
  (fmap [f this] (->ConsF (f (:head this)) (fmap f (:tail this)))))

(defrecord Nil []
  Recursive
  (project [_] (->NilF)))

(defrecord Cons [x xs]
  Recursive
  (project [_] (->ConsF x xs)))

(defn length-alg [f]
  ;; (println (project f))
  (cond
    (instance? NilF f) 0
    (instance? ConsF f) (inc (:tail f))
    :else (throw (Exception. (format "Unknown form %s" (str f))))))

(defn length [xs]
  ((precur length-alg) xs))

(defn -main [& args]
  (println ((compose inc dec) 1))
  (println ((compose first sort) [5 9 18 4]))
  (println ((compose + inc dec) 5))
  (println ((pcompose + inc dec) 5))
  (println (project (->Nil)))
  (println (project (->Cons 1 (->Nil))))
  (println (map + (->NilF)))
  (println (length (->Nil)))
  ;; (println (length Nil))
  (println "Good Bye")
  (System/exit 0))
