#lang racket/base

(require racket/contract/base
         racket/string
         sentry
         web-server/http
         "http.rkt")

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

(define (co-unsupplied/c arg unsupplied/c)
  (if (unsupplied-arg? arg)
      unsupplied/c
      unsupplied-arg?))

(define (make-sentry-wrapper
         [dsn #f]
         #:client [client #f]
         #:backlog [backlog 128]
         #:release [release #f]
         #:environment [environment #f])
  (cond
    [client
     (wrap-sentry client)]
    [dsn
     (wrap-sentry
      (make-sentry
       dsn
       #:backlog backlog
       #:release release
       #:environment environment))]
    [else
     values]))
