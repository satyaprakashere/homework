(ns advanced.macros)

;; Macros
;; Macros allow you to extend the language by manipulating code as data.
;; They run at COMPILE time and return code that is then executed.

;; 1. Simple Macro: 'unless' (opposite of 'if')
;; Note: We use 'defmacro'. Symbols inside are syntax-quoted with '`'.
;; We use '~' (unquote) to evaluate arguments.
(defmacro unless [test & body]
  `(if (not ~test)
     (do ~@body))) ; '~@' is unquote-splicing (expands a list into the form)

(println "Unless test:")
(unless (= 1 2)
        (println "1 does not equal 2"))

;; 2. Debugging Macro: 'say-and-do'
;; Prints the expression before executing it.
(defmacro say-and-do [expr]
  `(let [result# ~expr] ; 'result#' creates a unique auto-gensym symbol
     (println "Executing:" '~expr "=>" result#)
     result#))

(say-and-do (+ 1 2 3))

;; 3. Control Flow: 'bench'
;; A simple macro to time an expression.
(defmacro bench [expr]
  `(let [start# (System/nanoTime)
         ret# ~expr
         end# (System/nanoTime)]
     (println "Elapsed time:" (/ (- end# start#) 1000000.0) "msecs")
     ret#))

(bench (reduce + (range 1000000)))

;; Key Rules for Macros:
;; 1. Don't use a macro if a function will do.
;; 2. Be careful with double evaluation (use 'let' inside the macro).
;; 3. Use 'macroexpand' to see what a macro call turns into:
(println "Macroexpand unless:" (macroexpand '(unless (= 1 2) (println "hi"))))
