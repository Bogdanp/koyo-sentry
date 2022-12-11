#lang info

(define license 'BSD-3-Clause)
(define verison "0.1")
(define collection "koyo")

(define deps '("base"
               "koyo-lib"
               "sentry-lib"
               "web-server-lib"))
(define build-deps '("racket-doc"
                     "scribble-lib"
                     "sentry-doc"
                     "web-server-doc"))
(define scribblings '(("koyo-sentry.scrbl")))
