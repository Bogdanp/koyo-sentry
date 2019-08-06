#lang racket/base

(require koyo/profiler
         racket/contract
         racket/string
         sentry
         web-server/http
         web-server/managers/manager)

(provide
 make-sentry-wrapper)

(define-logger koyo-sentry)

(define (can-be-ignored? e)
  (exn:fail:servlet-manager:no-instance? e))

(define/contract (make-sentry-wrapper dsn
                                      #:backlog [backlog 128]
                                      #:release [release #f]
                                      #:environment [environment #f])
  (->* ((or/c false/c non-empty-string?))
       (#:backlog exact-positive-integer?
        #:release (or/c false/c non-empty-string?)
        #:environment (or/c false/c non-empty-string?))
       (-> (-> request? response?)
           (-> request? response?)))

  (cond
    [dsn
     (define sentry
       (make-sentry dsn
                    #:backlog backlog
                    #:release release
                    #:environment environment))

     (parameterize ([current-sentry sentry])
       (lambda (handler)
         (lambda (req)
           (with-timing 'sentry "wrap-sentry"
             (with-handlers ([can-be-ignored?
                              (lambda (e)
                                (log-koyo-sentry-debug "exception ~v ignored" (exn-message e))
                                (raise e))]

                             [exn?
                              (lambda (e)
                                (sentry-capture-exception! e #:request req)
                                (raise e))])
               (handler req))))))]

    [else values]))
