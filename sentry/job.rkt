#lang racket/base

(require koyo/job
         koyo/profiler
         racket/match
         sentry
         sentry/tracing
         "logger.rkt")

(provide
 wrap-sentry/job)

(define ((wrap-sentry/job sentry) meta proc)
  (make-keyword-procedure
   (lambda (kws kw-args . args)
     (with-timing 'sentry "wrap-sentry/job"
       (parameterize ([current-sentry sentry])
         (match-define (job-metadata id queue name attempts) meta)
         (call-with-transaction
           #:data (hasheq 'messaging.system "koyo"
                          'messaging.message.id (number->string id)
                          'messaging.message.retry.count (sub1 attempts))
           #:source 'task
           #:operation 'queue.task
           (format "~a.~a" queue name)
           (lambda (_t)
             (with-handlers ([exn:fail?
                              (lambda (e)
                                (log-koyo-sentry-debug "capturing exception ~v" (exn-message e))
                                (sentry-capture-exception! e)
                                (raise e))])
               (keyword-apply proc kws kw-args args)))))))))
