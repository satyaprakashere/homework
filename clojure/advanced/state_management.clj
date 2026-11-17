(ns advanced.state-management)

;; State and Identity in Clojure
;; Clojure separates "Value" (immutable) from "Identity" (state over time).

;; --- 1. Atoms ---
;; Synchronous, independent state changes. 
;; Use for most common shared state needs.
(def counter (atom 0))

(println "Initial Atom value:" @counter)
(swap! counter inc) ; Atomic swap
(println "After swap:" @counter)
(reset! counter 10) ; Direct reset
(println "After reset:" @counter)

;; --- 2. Refs ---
;; Synchronous, COORDINATED state changes using STM (Software Transactional Memory).
;; Use when you need to update multiple pieces of state together (A to B transfer).
(def account-a (ref 100))
(def account-b (ref 50))

(defn transfer [from-ref to-ref amount]
  (dosync ; Everything inside dosync is atomic, consistent, and isolated
   (alter from-ref - amount)
   (alter to-ref + amount)))

(println "Accounts before transfer:" @account-a @account-b)
(transfer account-a account-b 20)
(println "Accounts after transfer:" @account-a @account-b)


;; --- 3. Agents ---
;; Asynchronous, independent state changes.
;; Use for things that can happen in the background (logging, external API calls).
(def logger (agent []))

(defn log [state msg]
  (conj state (str (java.util.Date.) ": " msg)))

(send logger log "System started")
(send logger log "Agent update sent")

;; Agents are updated in a thread pool. We might need to wait or check later.
(Thread/sleep 100) ; Wait a bit for the agent to process
(println "Agent log history:" @logger)

;; Summary:
;; - Atoms: Sync, Independent (Fastest, most common)
;; - Refs: Sync, Coordinated (Transaction-based)
;; - Agents: Async, Independent (Background tasks)
