(defmacro when (condition . body) (quote (if (comma condition) (begin (comma-at body)) (quote ())))) ;; => nil
(defmacro unless (condition . body) (quote (if (comma condition) (quote ()) (begin (comma-at body))))) ;; => nil

(define x 10) ;; => x
(when (less_than x 20) 10) ;; => 10
(unless (greater_than x 20) 30) ;; => 30
