(define + add)
(define - sub)
(define * mul)
(define / div)
(define = numeq)
(define < less_than)
(define > greater_than)
(define car first)
(define cdr rest)
(define number->string number-to-string)
(define #t true)
(define #f false)

(define (caar x) (car (car x)))
(define (cadr x) (car (cdr x)))
(define (cdar x) (cdr (car x)))
(define (cddr x) (cdr (cdr x)))

;; Higher-order functions
(define (map proc lst)
  (if (is-null lst)
      (quote ())
      (cons (proc (car lst)) (map proc (cdr lst)))))

(define (filter pred lst)
  (if (is-null lst)
      (quote ())
      (if (pred (car lst))
          (cons (car lst) (filter pred (cdr lst)))
          (filter pred (cdr lst)))))

(define (foldl proc init lst)
  (if (is-null lst)
      init
      (foldl proc (proc init (car lst)) (cdr lst))))

(define (foldr proc init lst)
  (if (is-null lst)
      init
      (proc (car lst) (foldr proc init (cdr lst)))))

(define (reverse lst)
  (define (rev-helper lst acc)
    (if (is-null lst)
        acc
        (rev-helper (cdr lst) (cons (car lst) acc))))
  (rev-helper lst (quote ())))

(define (length lst)
  (if (is-null lst)
      0
      (+ 1 (length (cdr lst)))))

(define (append lst1 lst2)
  (if (is-null lst1)
      lst2
      (cons (car lst1) (append (cdr lst1) lst2))))

(define (list . lst) lst)

;; Macros
(defmacro let (bindings . body)
  (cons (cons (quote lambda) (cons (map car bindings) body))
        (map cadr bindings)))

(defmacro and args
  (if (is-null args)
      true
      (if (is-null (cdr args))
          (car args)
          (cons (quote if) (cons (car args) (cons (cons (quote and) (cdr args)) (cons false (quote ()))))))))

(defmacro or args
  (if (is-null args)
      false
      (if (is-null (cdr args))
          (car args)
          (cons (quote let) (cons (cons (cons (quote __or_val) (cons (car args) (quote ()))) (quote ()))
                (cons (cons (quote if) (cons (quote __or_val) (cons (quote __or_val) (cons (cons (quote or) (cdr args)) (quote ()))))) (quote ())))))))

(defmacro cond clauses
  (if (is-null clauses)
      false
      (let ((clause (car clauses)))
        (if (eq? (car clause) (quote else))
            (cons (quote begin) (cdr clause))
            (cons (quote if) (cons (car clause)
                  (cons (cons (quote begin) (cdr clause))
                  (cons (cons (quote cond) (cdr clauses)) (quote ())))))))))
