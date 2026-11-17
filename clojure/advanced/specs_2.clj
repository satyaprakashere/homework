(ns spec-demo.function
  (:require [clojure.spec.alpha :as s]
            [clojure.spec.gen.alpha :as gen]
            [clojure.spec.test.alpha :as stest]))

;; Define a function that adds a percentage-based tax
(defn calculate-tax [price rate]
  (+ price (* price rate)))

;; Define the spec for the function
(s/fdef calculate-tax
  :args (s/cat :price (s/double-in :min 0.0 :max 10000.0)
               :rate  (s/double-in :min 0.0 :max 1.0))
  :ret  double?
  :fn   (fn [{:keys [args ret]}] 
          (>= ret (:price args)))) ; Return must be >= original price

;; 1. Instrument the function (Validation)
;; This forces the function to check its arguments every time it's called.
(stest/instrument `calculate-tax)

(try
  (calculate-tax -50.0 0.2) ; This will throw a Spec Exception because price < 0
  (catch Exception e (println "Caught invalid call!")))

;; 2. Data Generation
;; See what kind of data Spec thinks matches our :args
(println "Sample generated args:" (gen/sample (s/gen :user/id) 5))
;; => (0 -1 2 15 42)

;; 3. Run Generative Tests
;; This runs the function 1000 times with random valid inputs to find bugs.
(println "Running generative test...")
(stest/check `calculate-tax)