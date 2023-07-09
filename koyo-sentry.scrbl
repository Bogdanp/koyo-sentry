#lang scribble/manual

@(require (for-label racket/base
                     racket/contract
                     racket/string
                     sentry
                     web-server/http))

@title{Sentry Middleware for Koyo}
@author[(author+email "Bogdan Popa" "bogdan@defn.io")]
@defmodule[koyo/sentry]

@(define sentry-url "https://sentry.io")

This package provides a middleware that automatically sends exceptions
to @link[sentry-url]{Sentry} when they occur.

@section{Reference}

@defproc[((make-sentry-wrapper [dsn (or/c false/c non-empty-string?) #f]
                               [#:client client (or/c false/c sentry?) #f]
                               [#:backlog backlog exact-positive-integer? 128]
                               [#:release release (or/c false/c non-empty-string?) #f]
                               [#:environment environment (or/c false/c non-empty-string?) #f]) [hdl (-> request? response?)])  (-> request? response?)]{

  Creates a function that wraps a request handler so that any
  exceptions it raises get sent to Sentry.

  When @racket[client] is provided, all other arguments are
  disallowed.  Conversely, @racket[client] may not be provided when
  @racket[dsn] is provided.

  When either @racket[client] or @racket[dsn] is is @racket[#f],
  @racket[hdl] is returned unchanged.
}
