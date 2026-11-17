(ns hello-datomic
  (:require [datomic.client.api :as d]))

(def client
  (d/client {:server-type :datomic-local
             :system "datomic-samples"}))

(def conn (d/connect client {:db-name "streets"}))

(def db (d/db conn))

(d/pull db '[*] [:person/name "Joe"])