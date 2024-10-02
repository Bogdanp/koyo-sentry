#lang racket/base

(require koyo/http
         koyo/job
         koyo/profiler
         net/uri-codec
         net/url
         racket/contract/base
         racket/match
         racket/string
         sentry
         sentry/tracing
         threading
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


;; request ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (((wrap-sentry sentry) hdl) req)
  (with-timing 'sentry "wrap-sentry"
    (parameterize ([current-sentry sentry])
      (define data (request-trace-data req))
      (define-values (trace-id parent-id _sampled?)
        (request-trace-ids req))
      (call-with-transaction
        #:data data
        #:source 'url
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
                               (sentry-capture-exception! e #:request req)
                               (span-set! t 'http.response.status_code 500)
                               (raise e))])
              (hdl req)))
          (begin0 res
            (when (response? res)
              (span-set! t 'http.response.status_code (response-code res)))))))))

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

(define (request-trace-data req)
  (define uri
    (request-uri req))
  (hasheq
   'http.request.method (bytes->string/utf-8 (request-method req))
   'url.scheme (or (url-scheme uri) "http")
   'url.path (url-path* uri)
   'url.query (url-query* uri)))

(define (request-txn-name req)
  (format "~a ~a"
          (request-method req)
          (url-path* (request-uri req))))

(define (url-query* u)
  (alist->form-urlencoded (url-query u)))


;; job ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide
 wrap-sentry/job)

(define ((wrap-sentry/job sentry) meta proc)
  (with-timing 'sentry "wrap-sentry-job"
    (make-keyword-procedure
     (lambda (kws kw-args . args)
       (parameterize ([current-sentry sentry])
         (match-define (job-metadata id queue name attempts) meta)
         (call-with-transaction
           #:data (hasheq 'messaging.system "koyo"
                          'messaging.message.id id
                          'messaging.message.retry.count (sub1 attempts))
           #:source 'task
           #:operation 'queue.task
           (format "process ~a.~a" queue name)
           (lambda (_t)
             (with-handlers ([exn:fail?
                              (lambda (e)
                                (log-koyo-sentry-debug "capturing exception ~v" (exn-message e))
                                (sentry-capture-exception! e)
                                (raise e))])
               (keyword-apply proc kws kw-args args)))))))))
