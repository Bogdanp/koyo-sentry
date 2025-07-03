#lang info

(define license 'BSD-3-Clause)
(define version "0.6")
(define collection "koyo")
(define deps
  '("base"
    ["component-lib" #:version "1.3"]
    ["koyo-lib" #:version "0.24"]
    ["sentry-lib" #:version "0.6"]
    "threading-lib"
    "web-server-lib"))
(define build-deps
  '("component-doc"
    "koyo-doc"
    "racket-doc"
    "scribble-lib"
    "sentry-doc"
    "web-server-doc"))
(define scribblings
  '(("koyo-sentry.scrbl" () ("Web Development"))))
