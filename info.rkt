#lang info

(define license 'BSD-3-Clause)
(define version "0.2")
(define collection "koyo")
(define deps
  '("base"
    "koyo-lib"
    ["sentry-lib" #:version "0.4"]
    "threading-lib"
    "web-server-lib"))
(define build-deps
  '("racket-doc"
    "scribble-lib"
    "sentry-doc"
    "web-server-doc"))
(define scribblings
  '(("koyo-sentry.scrbl" () ("Web Development"))))
