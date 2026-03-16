(defmacro when (condition . body)
    (quasiquote (if (comma condition)
                    (do (comma-at body))
                    (quote ())))) ;; => nil
(defmacro unless (condition . body)
    (quasiquote (if (comma condition)
                    (quote ()) (do (comma-at body))))) ;; => nil

(define x 10) ;; => x
(when (less_than x 20) 10) ;; => 10
(unless (greater_than x 20) 30) ;; => 30
