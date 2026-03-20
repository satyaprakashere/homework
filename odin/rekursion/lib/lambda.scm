;; Logic
(define (not x)
  (if x false true))

(defmacro assert (cond)
  (list (quote if) cond (quote (quote ok)) (list (quote error) (list (quote string-append) "Assertion failed: " (quote (quote cond))))))

;; List Constructor
(define (list . lst) lst)

;; Higher-order functions
(define (fmap proc lst)
  (define (map-helper lst acc)
    (if (is_null lst)
        (reverse acc)
        (recur (rest lst) (cons (proc (first lst)) acc))))
  (map-helper lst (quote ())))

(define (filter pred lst)
  (define (filter-helper lst acc)
    (if (is_null lst)
        (reverse acc)
        (if (pred (first lst))
            (recur (rest lst) (cons (first lst) acc))
            (recur (rest lst) acc))))
  (filter-helper lst (quote ())))

(define (foldl proc init lst)
  (if (is_null lst)
      init
      (recur proc (proc init (first lst)) (rest lst))))

(define (foldr proc init lst)
  (foldl (lambda (acc x) (proc x acc)) init (reverse lst)))

;; Macros
(defmacro and args
  (if (is_null args)
      true
      (if (is_null (rest args))
          (first args)
          (cons (quote if) (cons (first args) (cons (cons (quote and) (rest args)) (cons false (quote ()))))))))


(defmacro or args
  (if (is_null args)
      false
      (if (is_null (rest args))
          (first args)
          (cons (quote let) (cons (cons (cons (quote __or_val) (cons (first args) (quote ()))) (quote ()))
                (cons (cons (quote if) (cons (quote __or_val) (cons (quote __or_val) (cons (cons (quote or) (rest args)) (quote ()))))) (quote ())))))))

(defmacro cond clauses
  (if (is_null clauses)
      false
      (let ((clause (first clauses)))
        (if (eq (first clause) (quote else))
            (cons (quote do) (rest clause))
            (cons (quote if) (cons (first clause)
                  (cons (cons (quote do) (rest clause))
                  (cons (cons (quote cond) (rest clauses)) (quote ())))))))))

;; Delimited Continuations
(defmacro reset (body)
  (cons (quote creset) (cons (cons (quote lambda) (cons (quote ()) (cons body (quote ())))) (quote ()))))

(defmacro shift (k . body)
  (cons (quote cshift) (cons (cons (quote lambda) (cons (cons k (quote ())) (cons (cons (quote do) body) (quote ())))) (quote ()))))

;; Maps (implemented as tagged lists: ('map data-alist parent))
(define (map . parent)
  (cons (quote map) (cons (quote ()) (if (is_null parent) (quote (())) parent))))

(define (is_map x)
  (if (is_pair x)
      (eq (first x) (quote map))
      false))

(define (get tbl key)
  (if (is_map tbl)
      (let ((alist (first (rest tbl)))
            (parent (first (rest (rest tbl)))))
        (let ((pair (assoc key alist)))
          (if pair
              (rest pair)
              (if (is_null parent)
                  (quote ())
                  (recur parent key)))))
      (quote ())))

(define (set tbl key val)
  (if (is_map tbl)
      (let ((alist (first (rest tbl))))
        (let ((pair (assoc key alist)))
          (if pair
              (do
                (set_rest pair val)
                val)
              (do
                (set_first (rest tbl) (cons (cons key val) alist))
                val))))
      (quote ())))

(define (set_parent tbl parent)
  (if (is_map tbl)
      (do
        (set_first (rest (rest tbl)) parent)
        parent)
      (quote ())))
