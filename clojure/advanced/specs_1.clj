(ns spec-demo.core
  (:require [clojure.spec.alpha :as s]))

;; 1. Define individual "attribute" specs
(s/def :user/id int?)
(s/def :user/name (s/and string? #(not (empty? %))))
(s/def :user/role #{:admin :editor :guest})

;; 2. Combine them into an "entity" spec
(s/def :user/profile (s/keys :req [:user/id :user/name]
                             :opt [:user/role]))

;; --- Testing the specs ---

(def valid-user {:user/id 1 :user/name "Rich"})
(def invalid-user {:user/id "A1" :user/name ""})

(println "Is valid?" (s/valid? :user/profile valid-user)) 
;; => true

(if-not (s/valid? :user/profile invalid-user)
  (println "Errors found:" (s/explain-data :user/profile invalid-user)))