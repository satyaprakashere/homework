;; Logic
(define (not x)
  (if x false true))

;; List Constructor
(define (list . lst) lst)

;; List operations
(define (length lst)
  (if (is-null lst)
      0
      (+ 1 (length (rest lst)))))

(define (append lst1 lst2)
  (if (is-null lst1)
      lst2
      (cons (first lst1) (append (rest lst1) lst2))))

(define (reverse lst)
  (define (rev-helper lst acc)
    (if (is-null lst)
        acc
        (rev-helper (rest lst) (cons (first lst) acc))))
  (rev-helper lst (quote ())) )

(define map
  (lambda (proc lst)
    (if (is-null lst)
        (quote ())
        (cons (proc (first lst)) (map proc (rest lst))))))

(define (filter pred lst)
  (if (is-null lst)
      (quote ())
      (if (pred (first lst))
          (cons (first lst) (filter pred (rest lst)))
          (filter pred (rest lst)))))

(define (foldl proc init lst)
  (if (is-null lst)
      init
      (foldl proc (proc init (first lst)) (rest lst))))

(define (foldr proc init lst)
  (if (is-null lst)
      init
      (proc (first lst) (foldr proc init (rest lst)))))

;; Macros
(defmacro let (bindings . body)
  (cons (cons (quote lambda) (cons (map first bindings) body))
        (map (lambda (b) (first (rest b))) bindings)))

(defmacro and args
  (if (is-null args)
      true
      (if (is-null (rest args))
          (first args)
          (cons (quote if) (cons (first args) (cons (cons (quote and) (rest args)) (cons false (quote ()))))))))

(defmacro or args
  (if (is-null args)
      false
      (if (is-null (rest args))
          (first args)
          (cons (quote let) (cons (cons (cons (quote __or_val) (cons (first args) (quote ()))) (quote ()))
                (cons (cons (quote if) (cons (quote __or_val) (cons (quote __or_val) (cons (cons (quote or) (rest args)) (quote ()))))) (quote ())))))))

(defmacro cond clauses
  (if (is-null clauses)
      false
      (let ((clause (first clauses)))
        (if (eq? (first clause) (quote else))
            (cons (quote begin) (rest clause))
            (cons (quote if) (cons (first clause)
                  (cons (cons (quote begin) (rest clause))
                  (cons (cons (quote cond) (rest clauses)) (quote ())))))))))

;; Recursion
(define Y
  (lambda (f)
    ((lambda (x) (f (lambda args (apply (x x) args))))
     (lambda (x) (f (lambda args (apply (x x) args)))))))

(define Z
  (lambda (f)
    ((lambda (x) (f (lambda args (apply (x x) args))))
     (lambda (x) (f (lambda args (apply (x x) args)))))))

;; Delimited Continuations
(defmacro reset (body)
  (list (quote creset) (list (quote lambda) (quote ()) body)))

(defmacro shift (k . body)
  (list (quote cshift) (list (quote lambda) (list k) (cons (quote begin) body))))
