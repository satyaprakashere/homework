;; coverage_vm_errors.scm

;; Stack Underflow / Type Errors
(apply add 10) ;; Error: expected pair. Result => nil
(apply (quote x) (quote (1 2))) ;; Error: expected procedure. Result => nil

;; Unbound Variables
(define (test-unbound) (do unbound-var)) ;; => test-unbound
(test-unbound) ;; Prints "Unbound variable: unbound-var". Result => nil

;; env-set errors
(define (test-env-set) (set! nonexistent-var 10)) ;; => test-env-set
(test-env-set) ;; Prints "Unbound variable: nonexistent-var". Result => nil

;; Infinite Loop Protection (MAX_STEPS = 1,000,000)
;; (define (forever) (forever)) ;; => forever
;; (forever) ;; Should terminate with "VM reached max steps limit!" Result => nil
