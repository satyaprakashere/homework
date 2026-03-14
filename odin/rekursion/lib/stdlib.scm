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
  (rev-helper lst '()))

(define map
  (lambda (proc lst)
    (if (is-null lst)
        '()
        (cons (proc (first lst)) (map proc (rest lst))))))

(define (filter pred lst)
  (if (is-null lst)
      '()
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

(defmacro let (bindings . body)
  (cons (cons 'lambda (cons (map first bindings) body))
        (map (lambda (b) (first (rest b))) bindings)))

(defmacro and args
  (if (is-null args)
      true
      (if (is-null (rest args))
          (first args)
          (cons 'if (cons (first args) (cons (cons 'and (rest args)) (cons false '())))))))

(defmacro or args
  (if (is-null args)
      false
      (if (is-null (rest args))
          (first args)
          (cons 'let (cons (cons (cons '__or_val (cons (first args) '())) '())
                (cons (cons 'if (cons '__or_val (cons '__or_val (cons (cons 'or (rest args)) '())))) '()))))))

(defmacro cond clauses
  (if (is-null clauses)
      false
      (let ((clause (first clauses)))
        (if (eq? (first clause) 'else)
            (cons 'begin (rest clause))
            (cons 'if (cons (first clause)
                  (cons (cons 'begin (rest clause))
                  (cons (cons 'cond (rest clauses)) '()))))))))

(define Y
  (lambda (f)
    ((lambda (x) (f (lambda (v) ((x x) v))))
     (lambda (x) (f (lambda (v) ((x x) v)))))))
