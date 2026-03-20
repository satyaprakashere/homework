;; Church Encoding Tests

(assert (eq (church->int (church-succ church3)) 4))
;; => 3
(church->int (church-add church2 church3)) ;; => 5
(church->int (church-mul church2 church3)) ;; => 6
(church->int (church-pow church2 church3)) ;; => 8
(church->int (int->church 10)) ;; => 10

(church-if church-true 1 0) ;; => 1
(church-if church-false 1 0) ;; => 0
(church-if (church-and church-true church-true) 1 0) ;; => 1
(church-if (church-and church-true church-false) 1 0) ;; => 0
(church-if (church-or church-true church-false) 1 0) ;; => 1
(church-if (church-not church-true) 1 0) ;; => 0
