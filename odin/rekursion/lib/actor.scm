;; lib/actor.scm
;; Actor model based on Delimited Continuations

(define scheduler (table))
(set scheduler 'run-queue '())
(set scheduler 'next-pid 1)
(set scheduler 'actors (table))
(set scheduler 'current-pid '())

(define enqueue (lambda (thunk)
  (let ((q (get scheduler 'run-queue)))
    (if (is-null q)
        (set scheduler 'run-queue (list thunk))
        (set scheduler 'run-queue (append q (list thunk)))))))

(define dequeue (lambda ()
  (let ((q (get scheduler 'run-queue)))
    (if (is-null q)
        '()
        (let ((head (first q))
              (tail (rest q)))
          (set scheduler 'run-queue tail)
          head))))))

(define schedule-next (lambda ()
  (let ((next-thunk (dequeue)))
    (if (is-null next-thunk)
        'all-actors-finished
        (next-thunk)))))

(define spawn (lambda (f)
  (let ((pid (get scheduler 'next-pid))
        (info (table)))
    (set scheduler 'next-pid (add pid 1))
    
    (set info 'mailbox '())
    (set info 'waiting false)
    (set (get scheduler 'actors) pid info)

    (enqueue 
      (lambda ()
        (set scheduler 'current-pid pid)
        (reset (f))
        (set scheduler 'current-pid '())
        (schedule-next)))
    pid)))

(define (send pid msg)
  (let ((info (get (get scheduler 'actors) pid)))
    (if (is-null info)
        false
        (begin
          (let ((mbox (get info 'mailbox)))
            (if (is-null mbox)
                (set info 'mailbox (list msg))
                (set info 'mailbox (append mbox (list msg)))))
          
          (let ((k (get info 'waiting)))
            (if k
                (begin
                  (set info 'waiting false)
                  (enqueue (lambda () 
                              (set scheduler 'current-pid pid)
                              (k 'wake)
                              (set scheduler 'current-pid '())
                              (schedule-next))))
                false))
          'ok))))

(define receive (lambda ()
  (let ((pid (get scheduler 'current-pid)))
    (let ((info (get (get scheduler 'actors) pid)))
      (let ((mbox (get info 'mailbox)))
        (if (is-null mbox)
            (begin
              (shift k
                     (begin
                       (set info 'waiting k)
                       'suspended))
              (receive))
            (begin
              (let ((msg (first mbox))
                    (rest-mbox (rest mbox)))
                (set info 'mailbox rest-mbox)
                msg)))))))))

(define run-scheduler (lambda ()
  (schedule-next)))
