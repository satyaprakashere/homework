;; tests/cases/map_test.scm

(define t (map))
(print "Is map?" (is-map t))
(set t 'a 1)
(set t 'b 2)
(print "a:" (get t 'a))
(print "b:" (get t 'b))
(set t 'a 10)
(print "a after update:" (get t 'a))

(define t2 (map t))
(print "t2 inherits a:" (get t2 'a))
(set t2 'a 100)
(print "t2 a:" (get t2 'a))
(print "t1 a (should be 10):" (get t 'a))

(define t3 (map))
(set-parent t3 t)
(print "t3 inherits b:" (get t3 'b))
