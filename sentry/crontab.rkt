#lang racket/base

(require (prefix-in crontab: crontab)
         racket/promise
         sentry
         sentry/cron
         sentry/tracing)

(provide
 wrap-sentry/cron)

(define ((wrap-sentry/cron sentry)
         #:monitor? [monitor? #f]
         proc)
  (define monitor-config
    (delay (make-monitor-config)))
  (procedure-rename
   (lambda (timestamp)
     (parameterize ([current-sentry sentry])
       (call-with-transaction
         #:source 'component
         (format "crontab.~a" (object-name proc))
         (lambda (_)
           (if monitor?
               (call-with-monitor
                #:config (force monitor-config)
                (lambda ()
                  (proc timestamp)))
               (with-handlers ([exn:fail?
                                (lambda (e)
                                  (sentry-capture-exception! e)
                                  (raise e))])
                 (proc timestamp)))))))
   (object-name proc)))

(define (make-monitor-config)
  (monitor-config
   (schedule
    'crontab
    (schedule->string*
     (crontab:current-crontab-schedule)))))

(define (schedule->string* s)
  ;; schedule->string always produces a crontab string that has 6 fields
  ;; (i.e. it includes seconds), but Sentry expects a UNIX style cron
  ;; schedule, so just strip the seconds fields for now.
  (substring (crontab:schedule->string s) 2))
