(ns advanced.polymorphism)

;; Polymorphism in Clojure
;; Clojure provides two main ways to handle polymorphic behavior:
;; 1. Protocols (efficient, type-based)
;; 2. Multimethods (flexible, logic-based)

;; --- 1. Protocols ---
;; Protocols are like interfaces. They are fast and provide "expression problem" solutions.
(defprotocol Speakable
  (speak [this]))

(defrecord Dog [name]
  Speakable
  (speak [_] (str name " says Woof!")))

(defrecord Cat [name]
  Speakable
  (speak [_] (str name " says Meow!")))

;; You can even extend existing types!
(extend-type String
  Speakable
  (speak [this] (str "The string says: " this)))

(println "Protocol Speak (Dog):" (speak (->Dog "Buddy")))
(println "Protocol Speak (String):" (speak "Hello"))


;; --- 2. Multimethods ---
;; Multimethods use a dispatch function to decide which implementation to run.
;; This allows for dispatch on value, multiple arguments, or any arbitrary logic.
(defmulti area (fn [shape] (:type shape)))

(defmethod area :circle [{:keys [radius]}]
  (* Math/PI radius radius))

(defmethod area :rectangle [{:keys [width height]}]
  (* width height))

(defmethod area :default [shape]
  (throw (Exception. (str "Unknown shape: " (:type shape)))))

(println "Multimethod Area (Circle):" (area {:type :circle :radius 10}))
(println "Multimethod Area (Rectangle):" (area {:type :rectangle :width 5 :height 4}))

;; Comparison:
;; - Protocols: Faster (JVM interface), dispatch only on first argument's TYPE.
;; - Multimethods: Slower (more overhead), dispatch on ANYTHING (values, multiple args, hierarchies).
