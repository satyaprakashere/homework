(ns go
  (:require [clojure.core.async :as async :refer [go chan <! >! <!! >!! alts! timeout]]))

;; --- Aliases for better readability ---

(def take!  <!)                           ; Non-blocking take (go blocks)
(def put!   >!)                           ; Non-blocking put (go blocks)
(def take!! <!!)                          ; Blocking take (main thread)
(def put!!  >!!)                          ; Blocking put (main thread)

;; --- 1. Basic Channel Communication ---
(println "--- Basic Put/Take ---")

(let [c (chan)]
  (go    (println "Received:" (take! c))) ; non-blocking take inside a go block
  (put!! c "Hello World"))                ; blocking put outside a go block
(take!! (timeout 100))                    ; wait for go block output

;; --- 2. Multiple Producers (Fan-in) ---
(println "\n--- Fan-in Pattern ---")

(let [c (chan 10)] ; buffered channel
  (go (dotimes [i 3]
        (put! c (str "Producer 1: " i))))
  (go (dotimes [i 3]
        (put! c (str "Producer 2: " i))))
  (go (loop [i 0]
        (when (< i 6)
          (println "Consuming:" (take! c))
          (recur (inc i))))))

(take!! (timeout 200))

;; --- 3. Selection and Timeouts with alts! ---
(println "\n--- Timeouts and Selective Choice ---")

(defn fetch-with-timeout [c ms]
  (go
    (let [[val ch] (alts! [c (timeout ms)])]
      (if (= ch c) (println "Success:" val)
                   (println "Timed out!")))))

(let [c (chan)]
  (fetch-with-timeout c 50)                       ; will timeout
  (go (take! (timeout 100)) (put! c "Too late")))

(take!! (timeout 200))

;; --- 4. Pipelines with Transducers ---
(println "\n--- Pipelines with Transducers ---")

(let [xf (comp (filter even?) (map #(* % 10)))
      input (chan 10)
      output (chan 10 xf)] ; channel applies transducer automatically
  (async/pipe input output) ; pipes all values from input to output
  (go (loop []
        (when-let [v (take! output)]
          (println "Transduced:" v)
          (recur))))
  (go (doseq [n (range 5)] (put! input n)) (async/close! input)))

(take!! (timeout 200))

;; --- 5. Pub/Sub Pattern ---
(println "\n--- Pub/Sub Pattern ---")

(let [main-chan (chan)
      publisher (async/pub main-chan #(:topic %)) ; dispatch based on :topic
      sub1 (chan)
      sub2 (chan)]
  (async/sub publisher :news sub1)
  (async/sub publisher :sports sub2)

  (go (loop [] (when-let [v (take! sub1)] (println "Sub 1 (News):" v) (recur))))
  (go (loop [] (when-let [v (take! sub2)] (println "Sub 2 (Sports):" v) (recur))))

  (put!! main-chan {:topic :news :msg "Clojure is great!"})
  (put!! main-chan {:topic :sports :msg "Lakers won!"})
  (put!! main-chan {:topic :news :msg "Weather is sunny."}))

(take!! (timeout 500))
