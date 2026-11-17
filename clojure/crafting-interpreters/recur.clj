(ns recur)

(defn report [line where message]
  (println "[Line" line ":" where "] Error:" message ))

(defn error [line message]
  (report line "" message))

(defn -main [& args]
  (println "Hello, world!")
  (error 1 "Error message")
  (println "Hello There!"))

(-main [])