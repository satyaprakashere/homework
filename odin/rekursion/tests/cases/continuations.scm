(reset 1) ;; => 1
(reset (add 1 2)) ;; => 3
(reset (add 1 (shift k 5))) ;; => 5
(reset (add 1 (shift k (k 2)))) ;; => 3
(reset (add 1 (shift k (add (k 2) (k 2))))) ;; => 6
