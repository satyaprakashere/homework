(define (car list) (first list))
(define (cdr list) (rest list))

(define (+ args) (add args))
(define (- args) (sub args))
(define (* args) (mult args))
(define (/ args) (div args))


(define cadr (lambda (x) (first (rest x))))
(define cdar (lambda (x) (rest (first x))))
(define caar (lambda (x) (first (first x))))
(define cddr (lambda (x) (rest (rest x))))
(define caddr (lambda (x) (first (rest (rest x)))))

(define map
  (lambda (proc lst)
    (if (is-null lst)
        '()
        (cons (proc (first lst)) (map proc (rest lst))))))

(defmacro let (bindings . body)
  (cons (cons 'lambda (cons (map first bindings) body))
        (map cadr bindings)))

(defmacro and args
  (if (is-null args)
      'true
      (if (is-null (rest args))
          (first args)
          (cons 'if (cons (first args) (cons (cons 'and (rest args)) (cons 'false '())))))))

(defmacro or args
  (if (is-null args)
      'false
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
