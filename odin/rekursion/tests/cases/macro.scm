(defmacro when (condition . body) `(if ,condition (begin ,@body) '())) ;; => nil
(defmacro unless (condition . body) `(if ,condition '() (begin ,@body))) ;; => nil

(define x 10) ;; => x
(when (less_than x 20) 10) ;; => 10
(unless (greater_than x 20) 30) ;; => 30
