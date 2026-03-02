(require '[delimc.core :refer [shift reset]])

(reset
  (+ 1 (shift k (k 10))))
;; Returns 11. 'k' represents the "rest of the computation" inside the reset.