(define cadr (lambda (x) (car (cdr x))))
(define cdar (lambda (x) (cdr (car x))))
(define caar (lambda (x) (car (car x))))
(define cddr (lambda (x) (cdr (cdr x))))
(define caddr (lambda (x) (car (cdr (cdr x)))))

(define map
  (lambda (proc lst)
    (if (is-null lst)
        '()
        (cons (proc (car lst)) (map proc (cdr lst))))))

(defmacro let (bindings . body)
  `((lambda ,(map car bindings) ,@body) ,@(map cadr bindings)))

(defmacro and args
  (if (is-null args)
      true
      (if (is-null (cdr args))
          (car args)
          `(if ,(car args) (and ,@(cdr args)) #f))))

(defmacro or args
  (if (is-null args)
      #f
      (if (is-null (cdr args))
          (car args)
          (let ((val (car args)))
            `(if ,val ,val (or ,@(cdr args)))))))

(defmacro cond clauses
  (if (is-null clauses)
      '()
      (let ((clause (car clauses)))
        (if (eq (car clause) 'else)
            `(begin ,@(cdr clause))
            `(if ,(car clause)
                 (begin ,@(cdr clause))
                 (cond ,@(cdr clauses)))))))
