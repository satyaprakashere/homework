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
; (define (caaar x) (car (car (car x))))
; (define (caadr x) (car (car (cdr x))))
; (define (cadar x) (car (cdr (car x))))
; (define (caddr x) (car (cdr (cdr x))))
; (define (cdaar x) (cdr (car (car x))))
; (define (cdadr x) (cdr (car (cdr x))))
; (define (cddar x) (cdr (cdr (car x))))
; (define (cdddr x) (cdr (cdr (cdr x))))

;; Higher-order functions
; (define (map proc lst)
;   (if (is-null lst)
;       '()
;       (cons (proc (car lst)) (map proc (cdr lst)))))

(define (filter pred lst)
  (if (is-null lst)
      '()
      (if (pred (car lst))
          (cons (car lst) (filter pred (cdr lst)))
          (filter pred (cdr lst)))))

; (define (foldl proc init lst)
;   (if (is-null lst)
;       init
;       (foldl proc (proc init (car lst)) (cdr lst))))

; (define (foldr proc init lst)
;   (if (is-null lst)
;       init
;       (proc (car lst) (foldr proc init (cdr lst)))))

; ;; Macros
; (defmacro let (bindings . body)
;   (cons (cons 'lambda (cons (map car bindings) body))
;         (map cadr bindings)))

; (defmacro and args
;   (if (is-null args)
;       #t
;       (if (is-null (cdr args))
;           (car args)
;           (cons 'if (cons (car args) (cons (cons 'and (cdr args)) (cons #f '())))))))

; (defmacro or args
;   (if (is-null args)
;       #f
;       (if (is-null (cdr args))
;           (car args)
;           (cons 'let (cons (cons (cons '__or_val (cons (car args) '())) '())
;                 (cons (cons 'if (cons '__or_val (cons '__or_val (cons (cons 'or (cdr args)) '())))) '()))))))

; (defmacro cond clauses
;   (if (is-null clauses)
;       #f
;       (let ((clause (car clauses)))
;         (if (eq? (car clause) 'else)
;             (cons 'begin (cdr clause))
;             (cons 'if (cons (car clause)
;                   (cons (cons 'begin (cdr clause))
;                   (cons (cons 'cond (cdr clauses)) '()))))))))
