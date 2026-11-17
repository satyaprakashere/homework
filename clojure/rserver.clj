(ns rserver
  (:import [java.net ServerSocket Socket]
           [java.io BufferedReader InputStreamReader OutputStreamWriter]))

(defn handle-client [^Socket client]
  (with-open [reader (BufferedReader. (InputStreamReader. (.getInputStream client)))
              writer (OutputStreamWriter. (.getOutputStream client))]

    ;; Read and print the HTTP request
    (println "Request:")

    (loop [line (.readLine reader)]
      (when (and line (not (.isEmpty line)))
        (println line)
        (recur (.readLine reader))))  ;; Recursive request reading

    ;; Send a simple HTTP response
    (.write writer "HTTP/1.1 200 OK\r\n")
    (.write writer "Content-Type: text/html\r\n")
    (.write writer "\r\n")
    (.write writer "<html><body><h1>Hello, Recursion!</h1></body></html>\r\n")
    (.flush writer)))  ;; Ensure response is sent

(defn start-server [server]
  (println "Server started on port 8080")
  (loop []
    (let [client (.accept server)]                            ;; Accept incoming connection
      (future (handle-client client))                         ;; Run handler in a separate thread
      (recur))))                                              ;; Keep accepting new connections recursively

(let [server (ServerSocket. 8080)]                            ;; Keep server running
  (start-server server))                                      ;; Never exits
