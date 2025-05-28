#lang racket/base

(require koyo/profiler
         sentry
         sentry/tracing)

(provide
 wrap-sentry/cron)

(define ((wrap-sentry/cron sentry) proc)
  (procedure-rename
   (lambda (timestamp)
     (with-timing 'sentry "wrap-sentry/cron"
       (parameterize ([current-sentry sentry])
         (call-with-transaction
           #:source 'component
           (format "crontab.~a" (object-name proc))
           (lambda (_)
             (with-handlers ([exn:fail?
                              (lambda (e)
                                (sentry-capture-exception! e)
                                (raise e))])
               (proc timestamp)))))))
   (object-name proc)))
