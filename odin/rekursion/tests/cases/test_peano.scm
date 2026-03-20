;; Peano Arithmetic Tests

(peano->int (int->peano 5)) ;; => 5
(peano-eq? (int->peano 3) (int->peano 3)) ;; => true
(peano-eq? (int->peano 3) (int->peano 4)) ;; => false

(peano->int (peano-add (int->peano 3) (int->peano 4))) ;; => 7
(peano->int (peano-mul (int->peano 3) (int->peano 4))) ;; => 12
(peano->int (peano-mul peano-zero (int->peano 10))) ;; => 0
