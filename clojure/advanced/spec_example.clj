(ns advanced.spec-example
  (:require [clojure.spec.alpha :as s]))

;; Clojure Spec
;; Used for validation, error reporting, and generative testing.

;; 1. Defining Specs
(s/def ::id int?)
(s/def ::name string?)
(s/def ::email (s/and string? #(re-matches #".+@.+\..+" %)))

;; Defining a map spec
(s/def ::user (s/keys :req [::id ::name ::email]
                      :opt [::age]))

;; 2. Validation
(println "Valid User?:" (s/valid? ::user {::id 1 ::name "Alice" ::email "alice@example.com"}))
(println "Invalid User?:" (s/valid? ::user {::id "not-an-int" ::name "Bob"}))

;; 3. Explaining Errors
(println "--- Explain Error ---")
(s/explain ::user {::id "not-an-int" ::email "bad-email"})


;; 4. Function Specs (fdef)
(defn register-user [user]
  (println "Registering user:" (::name user))
  true)

(s/fdef register-user
  :args (s/cat :user ::user)
  :ret boolean?)

;; You can instrument functions to check specs during development
;; (require '[clojure.spec.test.alpha :as stest])
;; (stest/instrument `register-user)


;; 5. Conform (Destructuring/Parsing)
;; Spec can also be used to parse complex data structures.
(s/def ::config-item (s/or :s string? :i int? :b boolean?))
(println "Conformed config (string):" (s/conform ::config-item "prod"))
(println "Conformed config (int):" (s/conform ::config-item 8080))


;; Generative Testing (Conceptual)
;; Spec can automatically generate test data based on these definitions.
;; (require '[clojure.spec.gen.alpha :as gen])
;; (gen/generate (s/gen ::user))
