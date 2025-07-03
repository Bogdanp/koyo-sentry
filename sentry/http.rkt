#lang racket/base

(require koyo/http
         koyo/profiler
         koyo/url
         net/url
         racket/match
         sentry
         sentry/tracing
         threading
         web-server/http
         web-server/managers/manager
         "logger.rkt")

(provide
 wrap-sentry)

(define (((wrap-sentry sentry) hdl) req)
  (with-timing 'sentry "wrap-sentry"
    (cond
      [(capture-request? req)
       (parameterize ([current-sentry sentry])
         (define-values (trace-id parent-id _sampled?)
           (request-trace-ids req))
         (call-with-transaction
           #:origin 'auto.http.koyo
           #:source 'url
           #:request (request-data req)
           #:trace-id trace-id
           #:parent-id parent-id
           #:operation 'http.server
           (request-txn-name req)
           (lambda (t)
             (define res
               (with-handlers ([can-be-ignored?
                                (lambda (e)
                                  (log-koyo-sentry-debug "exception ~v ignored" (exn-message e))
                                  (raise e))]
                               [exn:fail?
                                (lambda (e)
                                  (log-koyo-sentry-debug "capturing exception ~v" (exn-message e))
                                  (sentry-capture-exception! #:request req e)
                                  (span-set! t 'http.response.status_code 500)
                                  (raise e))])
                 (hdl req)))
             (when (response? res)
               (span-set! t 'http.response.status_code (response-code res)))
             res)))]
      [else
       (hdl req)])))

(define (request-trace-ids req)
  (define maybe-parts
    (and~>
     (request-headers/raw req)
     (headers-assq* #"sentry-trace" _)
     (header-value)
     (bytes->string/utf-8)
     (regexp-split #rx"-" _)))
  (match maybe-parts
    [`(,trace-id ,parent-id) (values trace-id parent-id 'defer)]
    [`(,trace-id ,parent-id ,sampled) (values trace-id parent-id (equal? sampled "1"))]
    [_ (values #f #f #t)]))

(define (request-data req)
  (define u (request-uri req))
  (hasheq
   'url (~url u)
   'method (bytes->string/utf-8 (request-method req))
   'query_string
   (for*/list ([p (in-list (url-query u))]
               [k (in-value (symbol->string (car p)))]
               [v (in-value (cdr p))])
     (list k (or v "")))))

(define (request-txn-name req)
  (url-path* (request-uri req)))

(define (can-be-ignored? e)
  (or (exn:fail:servlet-manager:no-continuation? e)
      (exn:fail:servlet-manager:no-instance? e)))

(define (capture-request? req)
  (member
   (request-method req)
   '(#"CONNECT" #"DELETE" #"GET" #"PATCH" #"POST" #"PUT" #"TRACE")))

(define (~url u)
  (apply make-application-url (map path/param-path (url-path u))))
