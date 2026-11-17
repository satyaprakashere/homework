;#! /usr/local/bin/csi -script
;(import srfi-1)

(define (assoc-get key alist)
  (let ((entry (assoc key alist)))
    (if entry (cdr entry) '())))

(define (bfs graph start goal)
  (define (loop queue visited)
    (if (null? queue)
        #f  ;; not found
        (let* ((current (car queue))
               (rest (cdr queue)))
          (if (eq? current goal)
              #t
              (let* ((neighbors (assoc-get current graph))
                     (new-neighbors (filter (lambda (n) (not (member n visited))) neighbors))
                     (new-queue (append rest new-neighbors))
                     (new-visited (append visited new-neighbors)))
                (loop new-queue new-visited))))))
  (loop (list start) (list start)))

(define graph
  '((A B C)
    (B D)
    (C E)
    (D)
    (E)))

(display (bfs graph 'A 'E)) ;; => #t
(newline)
(display (bfs graph 'A 'F)) ;; => #f
