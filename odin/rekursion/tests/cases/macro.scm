; (print "Running Macro Tests...") ;; => nil

(defmacro when (condition body) `(if ,condition ,body '())) ;; => nil
(defmacro unless (condition body) `(if ,condition '() ,body)) ;; => nil

(define x 10) ;; => x
(when (< x 20) (print "x is less than 20")) ;; => nil
(unless (> x 20) (print "x is not greater than 20")) ;; => nil
