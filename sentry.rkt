#lang racket/base

(require koyo/profiler
         racket/contract/base
         racket/string
         sentry
         web-server/http
         web-server/managers/manager)

(provide
 (contract-out
  [make-sentry-wrapper
   (->i ()
        ([dsn (or/c #f non-empty-string?)]
         #:client [client (dsn) (co-unsupplied/c dsn (or/c #f sentry?))]
         #:backlog [backlog (client) (co-unsupplied/c client exact-positive-integer?)]
         #:release [release (client) (co-unsupplied/c client (or/c #f non-empty-string?))]
         #:environment [environment (client) (co-unsupplied/c client (or/c #f non-empty-string?))])
        [result (-> (-> request? any)
                    (-> request? any))])]))

(define-logger koyo-sentry)

(define (can-be-ignored? e)
  (or (exn:fail:servlet-manager:no-continuation? e)
      (exn:fail:servlet-manager:no-instance? e)))

(define (co-unsupplied/c arg unsupplied/c)
  (if (unsupplied-arg? arg)
      unsupplied/c
      unsupplied-arg?))

(define (make-sentry-wrapper [dsn #f]
                             #:client [client #f]
                             #:backlog [backlog 128]
                             #:release [release #f]
                             #:environment [environment #f])
  (cond
    [(or client dsn)
     (wrap-sentry (or client (make-sentry dsn
                                          #:backlog backlog
                                          #:release release
                                          #:environment environment)))]

    [else values]))

(define (((wrap-sentry sentry) hdl) req)
  (with-timing 'sentry "wrap-sentry"
    (parameterize ([current-sentry sentry])
      (with-handlers ([can-be-ignored?
                       (lambda (e)
                         (log-koyo-sentry-debug "exception ~v ignored" (exn-message e))
                         (raise e))]

                      [exn:fail?
                       (lambda (e)
                         (log-koyo-sentry-debug "capturing exception ~v" (exn-message e))
                         (sentry-capture-exception! e #:request req)
                         (raise e))])
        (hdl req)))))
