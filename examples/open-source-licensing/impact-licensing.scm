#!r6rs

(import (rnrs)
        (carneades argument)
        (carneades argument-builtins)
        (carneades argument-diagram)
        (carneades argument-search)
        (carneades rule)
        (carneades owl)
        (carneades lkif2)
        (carneades shell)
        (carneades stream))

(define kb1 (lkif-import "impact-kb.xml" '(transitive symmetric domain range equivalent)))
(define rb1 (lkif-data-rulebase kb1))

(define cqs '())

(define CarneadesEngine (string->symbol "http://carneades.berlios.de/impact-licensing#CarneadesEngine"))
(define EPL (string->symbol "http://carneades.berlios.de/impact-licensing#EPL"))
(define mayUseLicenseTemplate  (string->symbol "http://carneades.berlios.de/oss-licenses#mayUseLicenseTemplate"))
(define implementedIn (string->symbol "http://carneades.berlios.de/oss-licenses#implementedIn"))
(define (c ns n) (string->symbol (string-append ns n)))

(define il "http://carneades.berlios.de/impact-licensing#")
(define oss "http://carneades.berlios.de/oss-licenses#")

;generate all possible licenses for MyCode
;(show1 `(,mayUseLicenseTemplate ,CarneadesEngine ?x) e1)

;(define sols (construct-arguments `(not (,mayUseLicenseTemplate ,CarneadesEngine ,EPL))
;                                  5000
;                                  1
;                                  empty-argument-graph
;                                  (list (generate-arguments-from-rules rb1 cqs)
;                                        builtins)))

(define generators  (list (generate-arguments-from-rules rb1 cqs) builtins))

(define e1 (make-engine* 5000 10 empty-argument-graph generators))

(define (args ag goal)
  (unite-solutions (construct-arguments goal
                       5000
                       8
                       ag
                       generators
                      )))

(define (argswc ag goal)
  (unite-solutions-with-candidates 
   (construct-arguments goal
                        5000
                        8
                        ag
                        generators)))

(define goal1 `(,(c oss "mayUseLicenseTemplate") ,(c il "CarneadesEngine") ,(c oss "EPL_Template")))
(define goal2 `(,(c oss "mayUseLicenseTemplate") ,(c il "CarneadesEngine") ,(c oss "GPL_Template")))
(define goal3 '(valid FSFTheoryOfLinking))

(define ag0 (make-argument-graph 'ag1 "licensing" goal1))
(define ag1 (args ag0 goal1))

; (define ag2 (state-arguments (stream-car (e1 goal1))))

(view ag1)

;(define ld (make-lkif-data (lkif-data-sources kb1) (lkif-data-rulebase kb1) (list ag1)))
; (lkif-export '() ld "output.xml")