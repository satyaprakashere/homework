;; coverage_compiler_edge.scm

;; Macro Insufficient Arguments
(defmacro mac-2 (x y) (list x y)) ;; => nil
(mac-2 1) ;; => nil

;; Variadic Macro Edge Cases
(defmacro vari-mac x (list (quote quote) x)) ;; => nil
(vari-mac) ;; => nil
(vari-mac 1 2) ;; => (1 2)

;; Complex Quasiquotes
(define a 1) ;; => a
(define b 2) ;; => b
(quasiquote (a (comma (add a b)) (comma-at (list 3 4)) d)) ;; => (a 3 3 4 d)
(quasiquote (a (comma-at (quote ())) b)) ;; => (a b)

;; Literal quotes with commas (verified earlier, just adding here for coverage)
(quote (comma x)) ;; => (comma x)

;; Nested variadic calls
(define (f-var . args) args) ;; => f-var
(f-var 1 (f-var 2 3) 4) ;; => (1 (2 3) 4)
