(ns advanced.transducers)

;; Transducers
;; Transducers are composable algorithmic transformations. 
;; They are independent from the context of their input and output sources.

;; Standard collection processing (Eager/Lazy)
;; creates intermediate collections: (filter ...) -> (map ...) -> (take ...)
(defn standard-process [data]
  (->> data
       (filter odd?)
       (map #(* % %))
       (take 5)))

;; Transducer version
;; Note: 'filter', 'map', and 'take' called with ONE argument return a transducer.
(def xf
  (comp
   (filter odd?)
   (map #(* % %))
   (take 5)))

;; 1. Using with 'into'
(println "Transduced into vector:" (into [] xf (range 100)))

;; 2. Using with 'sequence' (returns a lazy sequence)
(println "Transduced sequence:" (sequence xf (range 100)))

;; 3. Using with 'transduce' (reduces the result immediately)
;; (transduce xf f init coll)
(println "Sum of transduced values:" (transduce xf + (range 100)))

;; Why Transducers?
;; 1. Performance: No intermediate collections are created.
;; 2. Composability: The same 'xf' can be used with collections, core.async channels, or streams.
;; 3. Decoupling: Logic is separate from how the data is stored or iterated.

;; Example with core.async (conceptual)
;; (chan 1 xf) ; Creates a channel that applies 'xf' to every item put into it.
