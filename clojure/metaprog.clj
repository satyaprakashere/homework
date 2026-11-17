(defmacro when-not [condition & body]
  `(if (not ~condition)
     (do ~@body)))

(println (when-not false 1))  ;; 1
(println (when-not true 1))   ;; nil