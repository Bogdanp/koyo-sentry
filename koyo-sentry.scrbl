#lang scribble/manual

@(require (for-label component
                     koyo/job
                     racket/base
                     racket/contract
                     racket/string
                     sentry
                     web-server/http))

@title{Sentry Middleware for Koyo}
@author[(author+email "Bogdan Popa" "bogdan@defn.io")]
@defmodule[koyo/sentry]

@(define sentry-url "https://sentry.io")

This package provides middleware that automatically trace transactions
and send exceptions to @link[sentry-url]{Sentry}.

@section{Reference}

@(define wrapper-component-tech
  (tech #:doc '(lib "component/component.scrbl") "wrapper component"))

@defproc[(make-sentry-component [proc (-> (or/c #f sentry?))]) component?]{
  Returns a @wrapper-component-tech that calls @racket[proc] when
  started and @racket[sentry-stop] on the wrapped client (unless the
  result of @racket[proc] is @racket[#f]) when stopped.

  @history[#:added "0.4"]
}

@defproc[((wrap-sentry [client (or/c #f sentry?)])
                       [hdl (-> request? response?)])
                       (-> request? response?)]{

  Wraps @racket[hdl] to trace requests to Sentry and to capture any
  unhandled exceptions.

  @history[#:added "0.4"]
}

@defproc[((wrap-sentry/cron [client (or/c #f sentry?)])
                            [proc (-> exact-integer? any)])
                            (-> exact-integer? any)]{

  Wraps @racket[proc] to trace crontab executions to Sentry and to
  capture any unhandled exceptions.

  @history[#:added "0.4"]
}

@defproc[((wrap-sentry/job [client (or/c #f sentry?)])
                           [meta job-metadata?]
                           [proc procedure?]) procedure?]{

  Wraps @racket[proc] to trace job executions to Sentry and to capture
  any unhandled exceptions.

  @history[#:added "0.4"]
}

@subsection{Deprecated API}

@defproc[((make-sentry-wrapper [dsn (or/c false/c non-empty-string?) #f]
                               [#:client client (or/c false/c sentry?) #f]
                               [#:backlog backlog exact-positive-integer? 128]
                               [#:release release (or/c false/c non-empty-string?) #f]
                               [#:environment environment (or/c false/c non-empty-string?) #f]) [hdl (-> request? response?)])  (-> request? response?)]{

  Creates a function that wraps a request handler so that any exceptions
  it raises get sent to Sentry and every request is tracked as a Sentry
  transaction. When @racket[client] is provided, all other arguments
  are disallowed. Conversely, @racket[client] may not be provided when
  @racket[dsn] is provided. When either @racket[client] or @racket[dsn]
  is is @racket[#f], @racket[hdl] is returned unchanged.

  @history[
    #:changed "0.4" @elem{This procedure is deprecated. Use
      @racket[make-sentry-component] instead.}
  ]
}
