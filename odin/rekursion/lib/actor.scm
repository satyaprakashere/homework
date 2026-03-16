;; lib/actor.scm
;; Actor model based on Delimited Continuations

(define scheduler (map))
(set scheduler (quote run-queue) (quote ()))
(set scheduler (quote next-pid) 1)
(set scheduler (quote actors) (map))
(set scheduler (quote current-pid) (quote ()))

(define enqueue (lambda (thunk)
  (let ((q (get scheduler (quote run-queue))))
    (if (is-null q)
        (set scheduler (quote run-queue) (list thunk))
        (set scheduler (quote run-queue) (append q (list thunk)))))))

(define dequeue (lambda ()
  (let ((q (get scheduler (quote run-queue))))
    (if (is-null q)
        (quote ())
        (let ((head (first q))
              (tail (rest q)))
          (set scheduler (quote run-queue) tail)
          head))))))

(define schedule-next (lambda ()
  (let ((next-thunk (dequeue)))
    (if (is-null next-thunk)
        (quote all-actors-finished)
        (next-thunk)))))

(define spawn (lambda (f)
  (let ((pid (get scheduler (quote next-pid)))
        (info (map)))
    (set scheduler (quote next-pid) (add pid 1))
    
    (set info (quote mailbox) (quote ()))
    (set info (quote waiting) false)
    (set (get scheduler (quote actors)) pid info)

    (enqueue 
      (lambda ()
        (set scheduler (quote current-pid) pid)
        (reset (f))
        (set scheduler (quote current-pid) (quote ()))
        (schedule-next)))
    pid)))

(define (send pid msg)
  (let ((info (get (get scheduler (quote actors)) pid)))
    (if (is-null info)
        false
        (begin
          (let ((mbox (get info (quote mailbox))))
            (if (is-null mbox)
                (set info (quote mailbox) (list msg))
                (set info (quote mailbox) (append mbox (list msg)))))))
          
          (let ((k (get info (quote waiting))))
            (if k
                (begin
                  (set info (quote waiting) false)
                  (enqueue (lambda () 
                              (set scheduler (quote current-pid) pid)
                              (k (quote wake))
                              (set scheduler (quote current-pid) (quote ()))
                              (schedule-next))))
                false))
          (quote ok))))

(define receive (lambda ()
  (let ((pid (get scheduler (quote current-pid))))
    (let ((info (get (get scheduler (quote actors)) pid)))
      (let ((mbox (get info (quote mailbox))))
        (if (is-null mbox)
            (begin
              (shift k
                     (begin
                       (set info (quote waiting) k)
                       (quote suspended)))
              (receive))
            (begin
              (let ((msg (first mbox))
                    (rest-mbox (rest mbox)))
                (set info (quote mailbox) rest-mbox)
                msg)))))))))

(define run-scheduler (lambda ()
  (schedule-next)))
