(require '[clojure.string :as str])

(defn longestCommonPrefix [strs]
  (if (empty? strs) ""
    (loop [commonPrefix (first strs) remaining (rest strs)]
      (cond
        (empty? remaining) commonPrefix     ;; All strings processed, return the common prefix

        ;; Current string starts with the common prefix, move to next string
        (str/starts-with? (first remaining) commonPrefix)
          (recur commonPrefix (rest remaining))
        (empty? commonPrefix) "" ;; Common prefix is empty, no match possible

        :else ;; Shorten the common prefix and retry with the same string
          (recur (apply str (butlast commonPrefix)) remaining)))))

(defn -main [& _]
  (let [res (longestCommonPrefix ["flower", "flow", "flight"])]
    (println res)))

(-main "")
