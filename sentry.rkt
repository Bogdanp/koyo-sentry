#lang racket/base

(require koyo/profiler
         racket/contract
         racket/string
         sentry
         web-server/http)

(provide
 make-sentry-wrapper)

(define/contract ((make-sentry-wrapper dsn
                                       #:backlog [backlog 128]
                                       #:release [release #f]
                                       #:environment [environment #f]) handler)
  (->* ((or/c false/c non-empty-string?))
       (#:backlog exact-positive-integer?
        #:release (or/c false/c non-empty-string?)
        #:environment (or/c false/c non-empty-string?))
       (-> (-> request? response?)
           (-> request? response?)))

  (cond
    [dsn
     (lambda (req)
       (with-timing 'sentry "wrap-sentry"
         (parameterize ([current-sentry (make-sentry dsn
                                                     #:backlog backlog
                                                     #:release release
                                                     #:environment environment)])
           (with-handlers ([exn?
                            (lambda (e)
                              (sentry-capture-exception! e #:request req)
                              (raise e))])
             (handler req)))))]

    [else handler]))
