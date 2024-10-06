#lang racket/base

(require component
         racket/contract/base
         sentry)

(provide
 (contract-out
  [make-sentry-component
   (-> (-> (or/c #f sentry?)) component?)]))

(define (make-sentry-component proc)
  (sentry-component proc))

(struct sentry-component (client)
  #:methods gen:component
  [(define (component-start self)
     (define client ((sentry-component-client self)))
     (struct-copy sentry-component self [client client]))

   (define (component-stop self)
     (define client (sentry-component-client self))
     (when client (sentry-stop client))
     (struct-copy sentry-component self [client #f]))]

  #:methods gen:wrapper-component
  [(define (component-unwrap self)
     (sentry-component-client self))])
