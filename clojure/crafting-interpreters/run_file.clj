(ns run-file
  (:require [lexer :as lexer]))

(declare run-file)
(declare run-prompt)
(declare run)

(defn -main [& args]
  (cond
    (= (count args) 1) (run-file (first args))
    (= (count args) 2) (run-prompt)
    :else (run-file "hello.recur")))

(defn run-file [file-path]
  (println "Running file: " file-path)
  (let [bytes (slurp file-path)]
    (run bytes)))

(defn run-prompt []
  (println "Running prompt")
  (doseq [line (line-seq (java.io.BufferedReader. *in*))]
    (run line)))

(defn run [source]
  (println "Running file")
  (println "Tokens:" (lexer/scanTokens source)))
