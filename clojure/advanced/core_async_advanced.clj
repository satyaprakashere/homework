(ns advanced.core-async-advanced
  (:require [clojure.core.async :as a :refer [go chan <! >! <!! >!! alts! timeout]]))

;; Advanced core.async patterns

;; 1. alts! (Selective choice)
;; Useful for waiting on multiple channels or implementing timeouts.
(defn test-alts []
  (let [c1 (chan)
        c2 (chan)]
    (go (a/onto-chan! c1 ["A1" "A2"]))
    (go (a/onto-chan! c2 ["B1" "B2"]))
    (go
      (loop [i 0]
        (when (< i 4)
          (let [[val ch] (alts! [c1 c2])]
            (println "Received:" val "from" (if (= ch c1) "Channel A" "Channel B"))
            (recur (inc i))))))))

(println "--- Testing alts! ---")
(test-alts)
(<!! (timeout 100)) ; Wait for go block output


;; 2. Timeout Pattern
;; Race a channel against a timeout channel.
(defn fetch-with-timeout [c ms]
  (go
    (let [[val ch] (alts! [c (timeout ms)])]
      (if (= ch c)
        (println "Fetched value:" val)
        (println "Request timed out!")))))

(println "--- Testing Timeout (Success) ---")
(let [c (chan)]
  (go (>! c "Data ready"))
  (fetch-with-timeout c 1000))

(println "--- Testing Timeout (Failure) ---")
(let [c (chan)]
  ;; Don't put anything in c
  (fetch-with-timeout c 50))

(<!! (timeout 200))


;; 3. Pipelines (Conceptual)
;; Use (a/pipeline) for parallel processing across multiple channels.
;; (a/pipeline n to-chan xf from-chan)
;; n: parallelism level
;; xf: transducer to apply

(println "--- core.async concepts summary ---")
(println "go blocks: light-weight threads (IoC threads)")
(println "channels: conduits for data")
(println "alts!: race/select multiple operations")
(println "timeout: non-blocking timer channel")
