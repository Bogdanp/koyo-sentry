#lang info

(define license 'BSD-3-Clause)
(define version "0.3")
(define collection "koyo")
(define deps
  '("base"
    ["koyo-lib" #:version "0.24"]
    ["sentry-lib" #:version "0.4"]
    "threading-lib"
    "web-server-lib"))
(define build-deps
  '("db-lib"
    "racket-doc"
    "scribble-lib"
    "sentry-doc"
    "web-server-doc"))
(define scribblings
  '(("koyo-sentry.scrbl" () ("Web Development"))))
