(reset 1) ;; => 1
(reset (+ 1 2)) ;; => 3
(reset (+ 1 (shift k 5))) ;; => 5
(reset (+ 1 (shift k (k 2)))) ;; => 3
(reset (+ 1 (shift k (+ (k 2) (k 2))))) ;; => 6
