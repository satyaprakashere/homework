;; Extended Logic Tests

(xor true true) ;; => false
(xor true false) ;; => true
(xor false true) ;; => true
(xor false false) ;; => false

(nand true true) ;; => false
(nand true false) ;; => true
(nand false true) ;; => true
(nand false false) ;; => true

(nor true true) ;; => false
(nor true false) ;; => false
(nor false true) ;; => false
(nor false false) ;; => true

(implies true true) ;; => true
(implies true false) ;; => false
(implies false true) ;; => true
(implies false false) ;; => true

(iff true true) ;; => true
(iff true false) ;; => false
(iff false true) ;; => false
(iff false false) ;; => true
