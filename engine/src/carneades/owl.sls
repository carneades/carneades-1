;;; Carneades Argumentation Library and Tools.
;;; Copyright (C) 2008 Thomas F. Gordon, Fraunhofer FOKUS, Berlin
;;; 
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU Lesser General Public License version 3 (LGPL-3)
;;; as published by the Free Software Foundation.
;;; 
;;; This program is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for details.
;;; 
;;; You should have received a copy of the GNU Lesser General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


#|
    An OWL document consists of:
     - optional ontology headers (generally at most one) - !!! no support !!!
     - class axioms                                      - partial support
     - property axioms                                   - partial support
     - facts about individuals                           - partial support 
    
|#

#|
    OWL class axioms
     - subclasses          - total support
     - equivalent classes  - partial support as far as rules only support conjunctions of literals in the head
     - disjoint classes    - partial support (s.a.); maybe different semantic
     - complete classes    - !!! no support !!! will propably be implemented later

    OWL class descriptions
     - identifier            - total support
     - enumerations          - total support
     - property restrictions - partial support
       - allValuesFrom  - partial support in subclasses and in equivalent classes in one direction
       - someValuesFrom - total support
       - hasValue       - total support
       - maxCardinality - !!! no support !!!
       - minCardinality - !!! no support !!!
       - Cardinality    - !!! no support !!!
     - intersections         - total support
     - unions                - total support
     - complements           - total support
|#

#|
    OWL property axioms
     - subproperty                 - total support
     - domain                      - total support
     - range                       - total support
     - equivalent property         - total support
     - inverse property            - total support
     - functional property         - !!! no support !!!
     - inverse functional property - !!! no support !!!
     - symmetric property          - total support
     - transitive property         - total support
|#

#|
    OWL individual axioms
     - class membership    - total support
     - property values     - total support
     - identity            - partial support
       - same as           - total support - but no equality-reasoning!
       - different from    - total support - but no equality-reasoning!
       - all different     - !!! no support !!!

   !!! Individual identity !!!
   OWL does not make the so-called "unique names" assumption. Carneades doesn't
   make this assumption explicitly either, but has no equation-theory implemented
   and therefore cannot reason about identity!
|#

; this library is not free of side-effects:
;  - *namespaces* is changed on import
;  - existential? is changed when converting axioms to rules
;  - classes is changed when converting class-axioms to rules

#!r6rs

(library
 (carneades owl)
 
 (export owl-import
         owl?
         namespaces
         ontology-path)
 
 (import (rnrs)
         (carneades rule)
         ;(carneades system)
         (carneades dnf)
         (only (carneades lib srfi strings)
               string-trim string-suffix? string-prefix? string-replace string-contains
               string-index string-index-right)
         (carneades lib xml ssax ssax-code)
         (carneades lib xml ssax access-remote)
         (carneades lib xml sxml sxpath))
 
 
 ; -------------------------
 ; debug
 ; -------------------------
 
 (define *debug* #f)
 
 
 ; -------------------------
 ; namespaces
 ; -------------------------
 
 ; list of namespace-prefixes used for sxpath
 (define *orig-namespaces* '((owl . "http://www.w3.org/2002/07/owl#")
                             (xsd . "http://www.w3.org/2001/XMLSchema#")
                             (owl2xml . "http://www.w3.org/2006/12/owl2-xml#")
                             (rdfs . "http://www.w3.org/2000/01/rdf-schema#")
                             (rdf . "http://www.w3.org/1999/02/22-rdf-syntax-ns#")))
 
 (define *namespaces* *orig-namespaces*)
 
 (define namespaces
   (case-lambda (() *namespaces*)
                ((ns) (set! *namespaces* ns) *namespaces*)))
 
 (define prefixes '("http://www.w3.org/2002/07/owl#"
                    "http://www.w3.org/2001/XMLSchema#"
                    "http://www.w3.org/2006/12/owl2-xml#"
                    "http://www.w3.org/2000/01/rdf-schema#"
                    "http://www.w3.org/1999/02/22-rdf-syntax-ns#"))
 
 (define xml-base "http://carneades/base#") 
 
 (define ontology-path "rdf:RDF")
 
  
 
 ; -------------------------
 ; "main"
 ; -------------------------
 
 ; owl-import: string (list-of symbol) -> rulebase
 ; optionals: transitive, symmetric, inverse, domain, range, disjoint or equivalent
 (define (owl-import path optionals)
   (set! local-gen 0)
   (clear-properties-and-classes)
   (let* ((doc (ssax:dtd-xml->sxml (open-input-resource path) '()))
          (owl-body ((sxpath ontology-path *namespaces*) doc))
          (rb (ontology->rules owl-body optionals)))
     (namespaces *orig-namespaces*)
     (if *debug*
         (begin (display *namespaces*)
                (newline)))
     rb))
 
 
 ; parsers:
 ; sxml -> (list-of sxml)
 
 ; -------------------------
 ; class parser
 ; -------------------------
 
 (define classes '())
 
 ; add-class: string -> <void>
 (define (add-class c)
   (if *debug*
       (begin (display "adding class: ")
              (write c)
              (newline)
              (display "ns          : ")
              (write (apply-namespaces c *namespaces*))
              (newline)))
   (set! classes (append classes (list (apply-namespaces c *namespaces*)))))
 
 ; class descriptions
  
 (define (get-owl-classes sxml)
   ((sxpath "owl:Class" *namespaces*) sxml))
 
 (define (get-class-enumerations sxml)
   ((sxpath "owl:oneOf" *namespaces*) sxml))
 
 (define (get-class-property-restrictions sxml)
   ((sxpath "owl:Restriction" *namespaces*) sxml))
 
 (define (get-owl-universal-restriction sxml)
   ((sxpath "*[self::owl:Restriction/owl:allValuesFrom]" *namespaces*) sxml))
 
 (define (get-class-intersections sxml)
   ((sxpath "owl:intersectionOf" *namespaces*) sxml))
 
 (define (get-class-unions sxml)
   ((sxpath "owl:unionOf" *namespaces*) sxml))
 
 (define (get-class-complements sxml)
   ((sxpath "owl:complementOf" *namespaces*) sxml))
 
 
 
 ; class axioms
 
 (define (get-subclasses sxml)
   ((sxpath "rdfs:subClassOf" *namespaces*) sxml))
 
 (define (get-equivalent-classes sxml)
   ((sxpath "owl:equivalentClass" *namespaces*) sxml))
 
 (define (get-disjoint-classes sxml)
   ((sxpath "owl:disjointWith" *namespaces*) sxml))
 
 
 ; -------------------------
 ; property parser
 ; -------------------------
 
 (define object-properties '())
 (define data-properties '())
 
 (define (add-object-property p)
   (set! object-properties (append object-properties (list (apply-namespaces p *namespaces*)))))
 
 (define (add-data-property p)
   (set! data-properties (append data-properties (list (apply-namespaces p *namespaces*)))))
 
 (define (get-object-properties sxml)
   ((sxpath "owl:ObjectProperty" *namespaces*) sxml))
 
 (define (get-data-properties sxml)
   ((sxpath "owl:DatatypeProperty" *namespaces*) sxml))
 
 (define (get-subproperties sxml)
   ((sxpath "rdfs:subPropertyOf" *namespaces*) sxml))
 
 (define (get-domains sxml)
   ((sxpath "rdfs:domain" *namespaces*) sxml))
 
 (define (get-ranges sxml)
   ((sxpath "rdfs:range" *namespaces*) sxml))
 
 (define (get-equivalent-properties sxml)
   ((sxpath "owl:equivalentProperty" *namespaces*) sxml))
 
 (define (get-inverse-properties sxml)
   ((sxpath "owl:inverseOf" *namespaces*) sxml))
 
 (define (get-functional-properties sxml)
   ((sxpath "owl:FunctionalProperty" *namespaces*) sxml))
 
 (define (get-inverse-functional-properties sxml)
   ((sxpath "owl:InverseFunctionalProperty" *namespaces*) sxml))
 
 (define (get-transitive-properties sxml)
   ((sxpath "owl:TransitiveProperty" *namespaces*) sxml))
 
 (define (get-symmetric-properties sxml)
   ((sxpath "owl:SymmetricProperty" *namespaces*) sxml))
 
 ; -------------------------
 ; individual parser
 ; -------------------------
 
 (define (get-descriptions sxml)
   ((sxpath "rdf:Description" *namespaces*) sxml))
 
 (define (get-class-members sxml)
   (if *debug*
       (begin (display "collected classes: ")
              (write classes)
              (newline)
              (display "namespace        : ")
              (write (namespaces))
              (newline)))
   (filter (lambda (c) (not (null? c)))
           (map (lambda (c) 
                  (let ((member ((sxpath c *namespaces*) sxml)))
                    (if (null? member)
                        '()
                        (cons c member))))
                classes)))
 
 (define (get-object-property-values sxml)
   (if *debug*
       (begin (display "collected properties ")
              (write object-properties)
              (newline)
              (display "namespace        : ")
              (write (namespaces))
              (newline)))
   (filter (lambda (p) (not (null? p)))
           (map (lambda (c) 
                  (let ((member ((sxpath c *namespaces*) sxml)))
                    (if (null? member)
                        '()
                        (cons c member))))
                object-properties)))
 
 (define (get-data-property-values sxml)
   (filter (lambda (p) (not (null? p)))
           (map (lambda (c) 
                  (let ((member ((sxpath c *namespaces*) sxml)))
                    (if (null? member)
                        '()
                        (cons c member))))
                data-properties)))
 
 (define (get-same-individuals sxml)
   ((sxpath "owl:sameAs" *namespaces*) sxml))
 
 (define (get-different-individuals sxml)
   ((sxpath "owl:differentFrom" *namespaces*) sxml))
 
 ; -------------------------
 ; rdf parser
 ; -------------------------
 
 (define (get-types sxml)
   ((sxpath "rdf:type" *namespaces*) sxml))
 
 
 ; -------------------------
 ; Ontology -> Rule Convertion
 ; -------------------------
 
 ; ontology->rules: sxml (list-of symbol) -> rule-base
 (define (ontology->rules ontology optionals)     
   (let* ((base ((sxpath "@xml:base/text()" *namespaces*) ontology))
          (namespaces-changed (if (not (null? base))
                                  (begin (namespaces (cons (cons 'base (string-append (car base) "#")) *namespaces*))
                                         (set! xml-base (string-append (car base) "#")))
                                  *namespaces*))
          (class-axioms (get-owl-classes ontology))
          (object-properties (get-object-properties ontology))
          (data-properties (get-data-properties ontology))
          (transitive-properties (if (exists (lambda (o) (eq? o 'transitive)) optionals)
                                     (get-transitive-properties ontology)
                                     '()))
          (symmetric-properties (if (exists (lambda (o) (eq? o 'symmetric)) optionals)
                                    (get-symmetric-properties ontology)
                                    '()))
          ; property rules
          (object-property-rules (filter (lambda (l) (not (null? l))) (flatmap (lambda (p) (property-axiom->rules p optionals)) object-properties)))
          (data-property-rules (filter (lambda (l) (not (null? l))) (flatmap (lambda (p) (property-axiom->rules p optionals)) data-properties)))
          (transitive-property-rules (filter (lambda (l) (not (null? l)))
                                             (flatmap transitive-property-axiom->rules transitive-properties)))
          (symmetric-property-rules (filter (lambda (l) (not (null? l)))
                                            (flatmap symmetric-property-axiom->rules symmetric-properties)))
          ; class rules
          (class-rules (filter (lambda (l) (not (null? l))) (flatmap (lambda (a) (class-axiom->rules a optionals)) class-axioms)))
          ; individual rules
          (descriptions (get-descriptions ontology))
          (class-members (get-class-members ontology))          
          (description-rules (flatmap individual-description->rules descriptions))
          (class-member-rules (flatmap class-members->rules class-members))
          (rules (append class-rules
                         object-property-rules
                         data-property-rules
                         transitive-property-rules
                         symmetric-property-rules
                         description-rules
                         class-member-rules)))
     (if *debug*
         (begin (newline)
                (display (length rules))
                (display " rules imported")
                (newline)))
     (add-rules empty-rulebase rules)))
 
 ; ----------------------
 ; class-conversion
 ; ----------------------
 
 ; class-axiom->rules: sxml (list-of symbol) -> (list-of rule)
 (define (class-axiom->rules axiom optionals)
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) axiom))
          (rdf-about ((sxpath "@rdf:about/text()" *namespaces*) axiom))
          (axiom-name (cond ((not (null? rdf-id)) (car rdf-id))
                            ((not (null? rdf-about)) (text->name rdf-about))
                            (else (error "class-axiom->rule" "no class name found" axiom))))
          (class-var (string->symbol (string-append "?" (apply-namespaces axiom-name *namespaces*))))
          (subclasses (get-subclasses axiom))
          (equivalents (get-equivalent-classes axiom))
          (disjoints (get-disjoint-classes axiom))
          (subclass-rules (map (lambda (s) (subclass-axiom->rule axiom-name class-var s)) subclasses))
          (equivalent-rules (flatmap (lambda (s) (equivalent-axiom->rules axiom-name class-var s optionals)) equivalents))
          (disjoint-rules (flatmap (lambda (s) (disjoint-axiom->rules axiom-name class-var s optionals)) disjoints)))
     (add-class axiom-name)
     (append subclass-rules equivalent-rules disjoint-rules)))
 
 ; subclass-axiom->rule: string symbol sxml -> rule
 (define (subclass-axiom->rule axiom-name argument sxml)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) sxml))
          (owl-classes (get-owl-classes sxml))
          (universal-restrictions (get-owl-universal-restriction sxml))
          (restrictions (get-class-property-restrictions sxml))
          (class-argument (cond ((not (null? rdf-resource))
                                 (list (string->symbol (text->name rdf-resource))
                                       argument))
                                ((not (null? universal-restrictions)) (universal-restriction->rule axiom-name
                                                                                                   argument
                                                                                                   (car universal-restrictions)))
                                ((not (null? owl-classes)) (class-description->formula argument (car owl-classes)))
                                ((not (null? restrictions)) (class-restriction->formula argument (car restrictions)))
                                (else (error "subclass-axiom->rule" "no class description found" sxml)))))
     (set! existential? #f) ; side effect: clear flag for existentialy quantified variables
     (if (rule? class-argument)
         class-argument
         (make-rule (gensym (string-append xml-base "subclass-rule-"))
                #f
                (make-rule-head class-argument)
                (make-rule-body (list (string->symbol axiom-name) argument))))))
 
 ; equivalent-axiom->rules: string symbol sxml (list-of symbol) -> (list-of rule)
 (define (equivalent-axiom->rules axiom-name argument sxml optionals)
   (let* ((equivalent? (member 'equivalent optionals))
          (rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) sxml))
          (owl-classes (get-owl-classes sxml))
          (universal-restrictions (get-owl-universal-restriction sxml))
          (restrictions (get-class-property-restrictions sxml))
          (class-argument (to-dnf (cond ((not (null? rdf-resource))
                                         (list (string->symbol (text->name rdf-resource))
                                               argument))
                                        ((not (null? universal-restrictions)) 'foo)
                                        ((not (null? owl-classes)) (class-description->formula argument (car owl-classes)))
                                        ((not (null? restrictions)) (class-restriction->formula argument (car restrictions)))
                                        (else (error "equivalent-axiom->rules" "no class description found" sxml)))))
          (rule-< (make-rule (gensym (string-append xml-base "equivalent-<-rule-"))
                             #f
                             (make-rule-head class-argument)
                             (make-rule-body (list (string->symbol axiom-name) 
                                                   argument))))
          (rule-> (make-rule (gensym (string-append xml-base "equivalent->-rule-"))
                             #f
                             (make-rule-head (list (string->symbol axiom-name)
                                                   argument))
                             (make-rule-body class-argument)))
          (rules (if (not (null? universal-restrictions))
                     (list (universal-restriction->rule axiom-name argument (car universal-restrictions)))
                     (if (and equivalent?                      ; equivalent as parameter
                              (lconjunction? class-argument)   ; head is conjunction of literals
                              (not existential?))             ; head has no existentialy quantified variables
                         (list rule-< rule->)
                         (begin (if *debug*
                                    (begin (display "not lconjunction? : ")
                                           (write class-argument)
                                           (newline)))
                                (list rule->))))))
     (set! existential? #f)
     rules))
 
 ; disjoint-axiom->rules : string symbol sxml (list-of symbol) -> (list-of rule)
 (define (disjoint-axiom->rules axiom-name argument sxml optionals)
   (let* ((disjoint? (member 'disjoint optionals))
          (rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) sxml))
          (owl-classes (get-owl-classes sxml))
          (restrictions (get-class-property-restrictions sxml))
          (class-argument (to-dnf (cond ((not (null? rdf-resource))
                                         (list (string->symbol (text->name rdf-resource))
                                               argument))
                                        ((not (null? owl-classes)) (class-description->formula argument (car owl-classes)))
                                        ((not (null? restrictions)) (class-restriction->formula argument (car restrictions)))
                                        (else (error "disjoint-axiom->rules" "no class description found" sxml)))))
          (negated-argument (to-dnf (list 'not class-argument)))
          (rule-< (make-rule (gensym (string-append xml-base "disjoint-<-rule-"))
                             #f
                             (make-rule-head negated-argument)
                             (make-rule-body (list (string->symbol axiom-name) 
                                                   argument))))
          (rule-> (make-rule (gensym (string-append xml-base "disjoint->-rule-"))
                             #f
                             (make-rule-head (list 'not (list (string->symbol axiom-name) 
                                                              argument)))
                             (make-rule-body class-argument)))
          (rules (if (and disjoint?
                          (lconjunction? negated-argument)
                          (not existential?))
                     (list rule-< rule->)
                     (list rule->))))
     (set! existential? #f)
     rules))
 
 ; universal-restriction->rule : string symbol sxml -> (list-of rule)
 (define (universal-restriction->rule axiom-name argument restriction)
   (let* ((prop (text->name ((sxpath "owl:onProperty/@rdf:resource/text()" *namespaces*) restriction)))
          (allValues ((sxpath "owl:allValuesFrom" *namespaces*) restriction))
          (rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) allValues))
          (owl-classes (get-owl-classes allValues))
          (restrictions (get-class-property-restrictions allValues))
          (prop-var (string->symbol (string-append "?" (apply-namespaces prop *namespaces*))))
          (class-argument (cond ((not (null? rdf-resource)) 
                                 (list (string->symbol (text->name rdf-resource))
                                       prop-var))
                                ((not (null? owl-classes)) (class-description->formula prop prop-var (car owl-classes)))
                                ((not (null? restrictions)) (class-restriction->formula prop prop-var (car restrictions)))
                                ;((not (null? descriptions)) (rdf-description->formula prop (car descriptions)))
                                (else (error "universal-restriction->rule" "no class description found" restriction)))))
     (set! existential? #f)
     (make-rule (gensym (string-append xml-base "universal-property-rule-"))
                #f
                (make-rule-head class-argument)
                (make-rule-body (list 'and 
                                      (list (string->symbol axiom-name) argument)
                                      (list (string->symbol prop) argument prop-var))))))
 
 ; class-description->formula: symbol sxml -> formula
 (define (class-description->formula argument class-desc)  
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) class-desc))
          (rdf-about ((sxpath "@rdf:about/text()" *namespaces*) class-desc))
          ;(rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) class-desc))
          ;(rdf-type ((sxpath "@rdf:type/text()" *namespaces*) class-desc))          
          (class-name (cond ((not (null? rdf-id)) (car rdf-id))
                            ((not (null? rdf-about)) (text->name rdf-about))
                            ;((not (null? rdf-resource)) (string-trim (car rdf-resource) #\#))
                            (else #f)))
          (enumerations (get-class-enumerations class-desc))          
          (intersections (get-class-intersections class-desc))
          (unions (get-class-unions class-desc))
          (complements (get-class-complements class-desc)))     
     (cond (class-name (list (string->symbol class-name) argument))
           ((not (null? enumerations)) (enumeration->formula argument (car enumerations)))           
           ((not (null? intersections)) (intersection->formula argument (car intersections)))
           ((not (null? unions)) (union->formula argument (car unions)))
           ((not (null? complements)) (complement->formula argument (car complements)))
           (else (error "class-description->formula" "no valid class description found" class-desc)))))
 
 ; rdf-description->formula : symbol sxml -> formula
 (define (rdf-description->formula argument rdf-desc)
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) rdf-desc))
          (rdf-about ((sxpath "@rdf:about/text()" *namespaces*) rdf-desc))         
          (class-name (cond ((not (null? rdf-id)) (car rdf-id))
                            ((not (null? rdf-about)) (text->name rdf-about))                            
                            (else (error "rdf-description->formula" "no ID or about found" rdf-desc)))))
     (list (string->symbol class-name) argument)))
 
 ; class-restriction->formula : symbol sxml -> formula
 (define (class-restriction->formula argument class-restr)
   (let* ((prop (text->name ((sxpath "owl:onProperty/@rdf:resource/text()" *namespaces*) class-restr)))
          (allValues ((sxpath "owl:allValuesFrom" *namespaces*) class-restr))
          (someValues ((sxpath "owl:someValuesFrom" *namespaces*) class-restr))
          (hasValue ((sxpath "owl:hasValue" *namespaces*) class-restr)))     
     (cond ((not (null? someValues)) (some-values-restriction->formula prop argument (car someValues)))
           ((not (null? hasValue)) (has-value-restriction->formula prop argument (car hasValue)))
           (else (error "class-restriction->formula" "owl:someValuesFrom or owl:hasValue expected! other restrictions are not supported!" class-restr)))))
 

 ; some-values-restriction->formula : string symbol sxml -> formula
 (define (some-values-restriction->formula prop argument restriction)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) restriction))
          (owl-classes (get-owl-classes restriction))
          (restrictions (get-class-property-restrictions restriction))
          (prop-var (string->symbol (string-append "?" (apply-namespaces prop *namespaces*))))
          ;(descriptions (get-descriptions restriction))
          (class-argument (cond ((not (null? rdf-resource)) 
                                 (list (string->symbol (text->name rdf-resource))
                                       prop-var))
                                ((not (null? owl-classes)) (class-description->formula prop prop-var (car owl-classes)))
                                ((not (null? restrictions)) (class-restriction->formula prop prop-var (car restrictions)))
                                ;((not (null? descriptions)) (rdf-description->formula prop (car descriptions)))
                                (else (error "some-values-restriction->rule" "no class description found" restriction)))))
     (set! existential? #t) ; set flag for existentialy quantified variables
     (list 'and 
           (list (string->symbol prop)
                 argument
                 prop-var)
           class-argument)))
 
 ; has-value-restriction->formula : string symbol sxml -> formula
 (define (has-value-restriction->formula prop argument restriction)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) restriction))
          (data-value ((sxpath "/text()" '()) restriction))
          (value (cond ((not (null? rdf-resource)) (string->symbol (text->name rdf-resource)))
                       ((not (null? data-value)) (string->symbol (car data-value)))
                       (else (error "has-value-restriction->rule" "no resource or data-value found" restriction)))))     
     (list (string->symbol prop) argument value)))
 

 ; enumeration->formula : symbol sxml -> formula
 (define (enumeration->formula argument enum)
   (let* ((individuals ((sxpath "*/@rdf:about/text()" *namespaces*) enum))
          (l (map (lambda (i) (list '= argument (string->symbol (text->name (list i))))) individuals)))
     (if (= (length individuals) 1)
         l
         (cons 'or l))))
         
 
 ; intersection->formula : symbol sxml -> formula
 (define (intersection->formula argument intersect) 
   (let* ((owl-classes (get-owl-classes intersect))
          (restrictions (get-class-property-restrictions intersect))
          (descriptions (get-descriptions intersect))
          (class-arguments (append (map (lambda (c) (class-description->formula argument c)) owl-classes)
                                   (map (lambda (c) (class-restriction->formula argument c)) restrictions)
                                   (map (lambda (c) (rdf-description->formula argument c)) descriptions))))
     (cons 'and class-arguments)))
 
 ; union->formula : symbol sxml -> formula
 (define (union->formula argument union)
   (let* ((owl-classes (get-owl-classes union))
          (restrictions (get-class-property-restrictions union))
          (descriptions (get-descriptions union))
          (class-arguments (append (map (lambda (c) (class-description->formula argument c)) owl-classes)
                                   (map (lambda (c) (class-restriction->formula argument c)) restrictions)
                                   (map (lambda (c) (rdf-description->formula argument c)) descriptions))))
     (cons 'or class-arguments)))
 
 ; complement->formula : symbol sxml -> formula
 (define (complement->formula argument comp)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) comp))
          (owl-classes (get-owl-classes comp))
          (restrictions (get-class-property-restrictions comp))
          ;(descriptions (get-descriptions comp))
          (class-arguments (cond ((not (null? rdf-resource)) (list (string->symbol (text->name rdf-resource))
                                                                   argument))
                                 ((not (null? owl-classes)) (class-description->formula argument (car owl-classes)))
                                 ((not (null? restrictions)) (class-restriction->formula argument (car restrictions)))
                                 ;((not (null? descriptions)) (rdf-description->formula argument (car descriptions)))
                                 (else (error "complement->formula" "no class description found" comp)))))
     (list 'not class-arguments)))
 
 
 
 ; ----------------------
 ; property-conversion
 ; ----------------------
 
 ; property-axiom->rules : sxml (list-of symbol) -> (list-of rule)
 (define (property-axiom->rules axiom optionals)
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) axiom))
          (rdf-about ((sxpath "@rdf:about/text()" *namespaces*) axiom))         
          (property-name (cond ((not (null? rdf-id)) (car rdf-id))
                               ((not (null? rdf-about)) (text->name rdf-about))
                               (else (error "property-axiom->rule" "no property name found" axiom))))
          (property-type (car axiom))
          (subproperties (get-subproperties axiom))
          (domains (if (member 'domain optionals)
                       (get-domains axiom)
                       '()))
          (ranges (if (member 'range optionals)
                      (get-ranges axiom)
                      '()))          
          (equiv-props (get-equivalent-properties axiom))
          (inverse-props (get-inverse-properties axiom))
          (functional-props (get-functional-properties axiom))
          (inverse-functional-props (get-inverse-functional-properties axiom))
          (prop-types (get-types axiom))
          (subproperty-rules (map (lambda (s) (subproperty->rule property-name s)) subproperties))
          (domain-rules (map (lambda (d) (domain->rule property-name d)) domains))
          (range-rules (map (lambda (r) (range->rule property-name r)) ranges))
          (equiv-rules (flatmap (lambda (e) (equivalent-property->rules property-name e optionals)) equiv-props))
          (inverse-rules (flatmap (lambda (i) (inverse-property->rules property-name i optionals)) inverse-props))          
          (type-rules (filter (lambda (x) (not (null? x))) (map (lambda (t) (prop-type->rule property-name t optionals)) prop-types)))            
          )
     (cond ((eq? property-type (string->symbol (resolve-namespaces "owl::ObjectProperty" *namespaces*))) (add-object-property property-name))
           ((eq? property-type (string->symbol (resolve-namespaces "owl::DatatypeProperty" *namespaces*))) (add-data-property property-name))
           (else (error "property-axiom->rules" "unknown property type (not data- or object-property)" axiom)))
     (append subproperty-rules domain-rules range-rules equiv-rules inverse-rules type-rules)))
 
 ; property-axiom->rules : string sxml  -> rule
 (define (subproperty->rule property-name sub-prop)
   (let* ((rdf-resource (text->name ((sxpath "@rdf:resource/text()" *namespaces*) sub-prop)))
          (rule-head (list (string->symbol rdf-resource)
                           (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1"))
                           (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2"))))
          (rule-body (list (string->symbol property-name)
                           (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1"))
                           (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))))
     (make-rule (gensym (string-append xml-base "subproperty-rule-"))
                #f
                (make-rule-head rule-head)
                (make-rule-body rule-body))))
 
 ; domain->rule : string sxml  -> rule
 (define (domain->rule property-name domain)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) domain))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (owl-classes (get-owl-classes domain))
          (restrictions (get-class-property-restrictions domain))
          (rule-head (cond ((not (null? rdf-resource)) (list (string->symbol (text->name rdf-resource))
                                                             var1))
                           ((not (null? owl-classes)) (class-description->formula (string-append property-name "-1") (car owl-classes)))
                           ((not (null? restrictions)) (class-restriction->formula (string-append property-name "-1") (car restrictions)))
                           (else (error "domain->rule" "no class description found" domain))))          
          (rule-body (list (string->symbol property-name) var1 var2)))
     (make-rule (gensym (string-append xml-base "domain-rule-"))
                #f
                (make-rule-head rule-head)
                (make-rule-body rule-body))))
 
 ; range->rule : string sxml  -> rule
 (define (range->rule property-name range)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) range))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (owl-classes (get-owl-classes range))
          (restrictions (get-class-property-restrictions range))
          (rule-head (cond ((not (null? rdf-resource)) (list (string->symbol (text->name rdf-resource))
                                                             var2))
                           ((not (null? owl-classes)) (class-description->formula (string-append property-name "-2") (car owl-classes)))
                           ((not (null? restrictions)) (class-restriction->formula (string-append property-name "-2") (car restrictions)))
                           (else (error "range->rule" "no class description found" range))))          
          (rule-body (list (string->symbol property-name) var1 var2)))
     (make-rule (gensym (string-append xml-base "range-rule-"))
                #f
                (make-rule-head rule-head)
                (make-rule-body rule-body))))
 
 ; equivalent-property->rules : string sxml  -> (list-of rule)
 (define (equivalent-property->rules property-name equiv-prop optionals)
   (let* ((equivalent? (member 'equivalent optionals))
          (rdf-resource (string->symbol (text->name ((sxpath "@rdf:resource/text()" *namespaces*) equiv-prop))))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (prop (string->symbol property-name))
          (stmt1 (list prop var1 var2))
          (stmt2 (list rdf-resource var1 var2))
          (rule-> (make-rule (gensym (string-append xml-base "equiv->-rule-"))
                             #f
                             (make-rule-head stmt1)
                             (make-rule-head stmt2)))
          (rule-< (make-rule (gensym (string-append xml-base "equiv-<-rule-"))
                             #f
                             (make-rule-head stmt2)
                             (make-rule-head stmt1))))
     (if equivalent?
         (list rule-> rule-<)
         (list rule->))))
 
 ; inverse-property->rules : string sxml  -> (list-of rule)
 (define (inverse-property->rules property-name inverse-prop optionals)
   (let* ((inverse? (member 'inverse optionals))
          (rdf-resource (string->symbol (text->name ((sxpath "@rdf:resource/text()" *namespaces*) inverse-prop))))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (prop (string->symbol property-name))
          (stmt1 (list prop var1 var2))
          (stmt2 (list rdf-resource var2 var1))
          (rule-> (make-rule (gensym (string-append xml-base "inverse->-rule-"))
                             #f
                             (make-rule-head stmt1)
                             (make-rule-head stmt2)))
          (rule-< (make-rule (gensym (string-append xml-base "inverse-<-rule-"))
                             #f
                             (make-rule-head stmt2)
                             (make-rule-head stmt1))))
     (if inverse?
         (list rule-> rule-<)
         (list rule->))))
 
 ; prop-type->rule : string sxml (list-of symbol) -> rule
 (define (prop-type->rule property-name prop-type optionals)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) prop-type))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (var3 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-3")))
          (transitive-allowed? (exists (lambda (o) (eq? o 'transitive)) optionals))
          (symmetric-allowed? (exists (lambda (o) (eq? o 'symmetric)) optionals))
          (transitive? (and (not (null? rdf-resource))
                            (string=? (resolve-namespaces "owl:TransitiveProperty" *namespaces*) (car rdf-resource))))
          (symmetric? (and (not (null? rdf-resource))
                           (string=? (resolve-namespaces "owl:SymmetricProperty" *namespaces*) (car rdf-resource))))
          (functional? (and (not (null? rdf-resource))
                            (string=? (resolve-namespaces "owl:FunctionalProperty" *namespaces*) (car rdf-resource))))
          (inverse-functional? (and (not (null? rdf-resource))
                                    (string=? (resolve-namespaces "owl:InverseFunctionalProperty" *namespaces*) (car rdf-resource)))))
     (cond ((and transitive? transitive-allowed?)
            (make-rule (gensym (string-append xml-base "transitive-rule-"))
                       #f
                       (make-rule-head (list (string->symbol property-name)var1 var3))
                       (make-rule-body (list 'and
                                             (list (string->symbol property-name)var1 var2)
                                             (list (string->symbol property-name)var2 var3)))))
           ((and symmetric? symmetric-allowed?)
            (make-rule (gensym (string-append xml-base "symmetric-rule-"))
                       #f
                       (make-rule-head (list (string->symbol property-name)var2 var1))
                       (make-rule-body (list (string->symbol property-name)var1 var2))))
           (else (if (and *debug*
                          (not transitive?)
                          (not symmetric?))
                     (begin (display "prop-type->rule: only symmetric and transitive types supported")
                            (newline)
                            (display "found: ")
                            (display prop-type)
                            (newline)))
                 '()))))
 
 ; transitive-property-axiom->rules : sxml  -> (list-of rule)
 (define (transitive-property-axiom->rules axiom)
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) axiom))
          (rdf-about ((sxpath "@rdf:about/text()" *namespaces*) axiom))
          ;(rdf-type ((sxpath "@rdf:type/text()" *namespaces*) axiom))          
          (property-name (cond ((not (null? rdf-id)) (car rdf-id))
                               ((not (null? rdf-about)) (text->name rdf-about))
                               (else (error "transitive-property-axiom->rule" "no property name found" axiom))))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (var3 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-3")))
          (property-rules (property-axiom->rules axiom))
          (transitive-rule (gensym (string->symbol (string-append xml-base property-name "-transitive-rule-"))
                                      #f
                                      (make-rule-head (list (string->symbol property-name)var1 var3))
                                      (make-rule-body (list 'and
                                                            (list (string->symbol property-name)var1 var2)
                                                            (list (string->symbol property-name)var2 var3))))))
     (append property-rules (list transitive-rule))))
 
 ; symmetric-property-axiom->rules : sxml  -> (list-of rule)
 (define (symmetric-property-axiom->rules axiom)
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) axiom))
          (rdf-about ((sxpath "@rdf:about/text()" *namespaces*) axiom))
          ;(rdf-type ((sxpath "@rdf:type/text()" *namespaces*) axiom))          
          (property-name (cond ((not (null? rdf-id)) (car rdf-id))
                               ((not (null? rdf-about)) (text->name rdf-about))
                               (else (error "symmetric-property-axiom->rules" "no property name found" axiom))))
          (var1 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-1")))
          (var2 (string->symbol (string-append "?" (apply-namespaces property-name *namespaces*) "-2")))
          (property-rules (property-axiom->rules axiom))
          (symmetric-rule (make-rule (gensym (string-append xml-base "symmetric-rule-"))
                                     #f
                                     (make-rule-head (list (string->symbol property-name)var2 var1))
                                     (make-rule-body (list (string->symbol property-name)var1 var2)))))
     (append property-rules (list symmetric-rule))))
 
 
 ; ----------------------
 ; individual-conversion
 ; ----------------------
 
 ; individual-description->rules : sxml -> (list-of rule)
 (define (individual-description->rules desc)
   (let* ((rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) desc))
          (rdf-about((sxpath "@rdf:about/text()" *namespaces*) desc))
          (individual-name (cond ((not (null? rdf-id)) (car rdf-id))
                                 ((not (null? rdf-about)) (text->name rdf-about))
                                 (else (error "individual-description->rules" "no individual-name found" desc))))
          (types (get-types desc))
          (object-prop-values (get-object-property-values desc))
          (data-prop-values (get-data-property-values desc))
          (same-individuals (get-same-individuals desc))
          (different-individuals (get-different-individuals desc))
          (type-rules (map (lambda (t) (member-type->rule individual-name t)) types))
          (object-prop-value-rules (map (lambda (p) (object-property-value->rule individual-name p)) object-prop-values))
          (data-prop-value-rules (map (lambda (p) (data-property-value->rule individual-name p)) data-prop-values))
          (same-rules (map (lambda (s) (same-individual->rule individual-name s)) same-individuals))
          (different-rules (map (lambda (d) (different-individual->rule individual-name d)) different-individuals)))
     (append type-rules  object-prop-value-rules data-prop-value-rules same-rules different-rules)))
 
 ; class-members->rules : sxml -> (list-of rule)
 (define (class-members->rules class-members)
   (flatmap class-member->rules (cdr class-members)))
 
 ; class-member->rules : sxml -> (list-of rule)
 (define (class-member->rules class-member)
   (let* ((c-name (symbol->string (car class-member)))
          (hash-pos (string-contains c-name "#:"))
          (class-name (string->symbol (if hash-pos
                                          (string-replace c-name "#" hash-pos (+ 2 hash-pos))
                                          c-name)))
          ;(member (cdr class-member))
          (rdf-id ((sxpath "@rdf:ID/text()" *namespaces*) class-member))
          (rdf-about((sxpath "@rdf:about/text()" *namespaces*) class-member))
          (individual-name (cond ((not (null? rdf-id)) (car rdf-id))
                                 ((not (null? rdf-about)) (text->name rdf-about))
                                 (else (symbol->string (gensym "anonymous-individual-")))))          
          (types (get-types class-member))
          (object-prop-values (get-object-property-values class-member))
          (data-prop-values (get-data-property-values class-member))    
          (same-individuals (get-same-individuals class-member))  
          (different-individuals (get-different-individuals class-member))
          (type-rules (map (lambda (t) (member-type->rule individual-name t)) types))
          (object-prop-value-rules (flatmap (lambda (p) (object-property-values->rules individual-name p)) object-prop-values))
          (data-prop-value-rules (map (lambda (p) (data-property-value->rule individual-name p)) data-prop-values))
          (same-rules (map (lambda (s) (same-individual->rule individual-name s)) same-individuals))
          (different-rules (map (lambda (d) (different-individual->rule individual-name d)) different-individuals))
          (member-rule (make-rule (gensym (string-append xml-base "class-member-rule-"))
                                  #f
                                  (make-rule-head (list class-name (string->symbol individual-name)))
                                  '())))
     (if *debug*
         (begin (display "class-mamber->rule: ")
                (write c-name)
                (newline)
                (display "individual        : ")
                (write individual-name)
                (newline)
                (display "ind-object-props  : ")                
                (write object-prop-values)                
                (newline)))
     (append type-rules  object-prop-value-rules data-prop-value-rules (list member-rule) same-rules different-rules)))
 
 ; member-type->rule : string sxml -> rule
 (define (member-type->rule individual-name type)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) type))
          (owl-classes (get-owl-classes type))
          (restrictions (get-class-property-restrictions type))
          (rule-head (cond ((not (null? rdf-resource)) (list (string->symbol (text->name rdf-resource))
                                                             (string->symbol individual-name)))
                           ((not (null? owl-classes)) (class-description->formula (string->symbol individual-name) (car owl-classes)))
                           ((not (null? restrictions)) (class-restriction->formula (string->symbol individual-name) (car restrictions)))
                           (else (error "member-type->rule" "no class description found" type))))
          (rule-name (gensym (string-append xml-base "type-rule-"))))
     (make-rule rule-name
                #f
                (make-rule-head rule-head)
                '())))
  ; object-property-values->rule : string (list-of sxml) -> (list-of rule)
 (define (object-property-values->rules individual-name property-values)
   (if *debug* 
       (begin (display "object-property-values->rules : ")
              (display individual-name)
              (newline)
              (display "property-values : ")
              (display property-values)
              (newline)))
   (let ((property-name (resolve-namespaces (car property-values) (namespaces))))
     (map (lambda (p) (object-property-value->rule individual-name property-name p)) (cdr property-values))))
 
 ; object-property-value->rule : string sxml -> rule
 (define (object-property-value->rule individual-name property-name property-value)
   (if *debug*
         (begin (display "object-property-value->rule : ")
                (display individual-name)
                (newline)
                (display "property-value : ")
                (display property-value)
                (newline)))
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) property-value))
          (object (if (not (null? rdf-resource))
                      (string->symbol (text->name rdf-resource))
                      (error "object-property-value->rule" "no rdf:resource found" property-value)))
          (rule-name (gensym (string-append xml-base "object-property-rule-"))))
     (if *debug*
         (begin (display "rdf-resource : ")
                (display rdf-resource)
                (newline)))
     (make-rule rule-name
                #f
                (make-rule-head (list (string->symbol property-name)
                                      (string->symbol individual-name)
                                      object))
                '())))
 
 ; data-property-value->rule : string sxml -> rule
 (define (data-property-value->rule individual-name property-value)
   (let* ((property-name (resolve-namespaces (car property-value) *namespaces*))
          (prop-value (cdr property-value))
          (rdf-datatype ((sxpath "@rdf:datatype/text()" *namespaces*) prop-value))
          (text ((sxpath "text()" '()) prop-value))
          (data (if (null? text)
                    (error "data-property-value->rule" "no text found" prop-value)
                    (car text)))
          (rule-name (gensym (string-append xml-base "data-property-rule-"))))
     (make-rule rule-name
                #f
                (make-rule-head (list (string->symbol property-name)
                                      (string->symbol individual-name)
                                      data))
                '())))
 
 ; same-individual->rule : string sxml -> rule
 (define (same-individual->rule individual-name sameAs)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) sameAs))
          (object (if (not (null? rdf-resource))
                      (string->symbol (text->name rdf-resource))
                      (error "same-individual->rule" "no rdf:resource found" sameAs))))
     (make-rule (gensym (string-append xml-base "same-as-rule-"))
                #f
                (make-rule-head (list '= (string->symbol individual-name) object))
                '())))
 
 ; different-individual->rule : string sxml -> rule
 (define (different-individual->rule individual-name differentFrom)
   (let* ((rdf-resource ((sxpath "@rdf:resource/text()" *namespaces*) differentFrom))
          (object (if (not (null? rdf-resource))
                      (string->symbol (text->name rdf-resource))
                      (error "different-individual->rule" "no rdf:resource found" differentFrom))))
     (make-rule (gensym (string-append xml-base "different-from-rule-"))
                #f
                (make-rule-head (list 'not (list '= (string->symbol individual-name) object)))
                '())))
      
 
 ; -------------------------
 ; UTILS
 ; -------------------------
 
 (define local-gen 0)
 
 ; gensym: string -> symbol
 (define (gensym s)
   (set! local-gen (+ local-gen 1))
   (string->symbol (string-append s (number->string local-gen))))
 
 ; needed for making sure, that existentialy quantified
 ; variables don't appear in the head
 (define existential? #f)
 
 ; owl?: string -> boolean
 (define (owl? path)
  (let* ((doc (ssax:dtd-xml->sxml (open-input-resource path) '()))
         (rdf ((sxpath ontology-path *namespaces*) doc)))
    (not (null? rdf))))
 
 (define (clear-properties-and-classes)
   (set! classes '())
   (set! object-properties '())
   (set! data-properties '()))
 
 (define (flatmap f l) (apply append (map f l)))
 
 (define (one-of-prefixes? p s)
   (if (null? p)
       #f
       (or (string-prefix? (car p) s)
           (one-of-prefixes? (cdr p) s))))
 
 (define (resolve-namespaces s ns)
   (fold-left resolve-namespace s ns))
 
 ; "owl:foo"  |-> "http://www.w3.org/2002/07/owl#foo"
 ; "owl::foo" |-> "http://www.w3.org/2002/07/owl#:foo"
 (define (resolve-namespace s ns)
   (let ((prefix (string-append (symbol->string (car ns)) ":"))
         (uri (cdr ns)))
     (if (string-prefix? prefix s)
         (string-replace s uri 0 (string-length prefix))
         s)))
 
 (define (apply-namespaces s ns)
   (fold-left apply-namespace s ns))
 
 ; "http://www.w3.org/2002/07/owl#foo" |-> "owl:foo"
 (define (apply-namespace s ns)
   (let ((prefix (string-append (symbol->string (car ns)) ":"))
         (uri (cdr ns)))
     (if (string-prefix? uri s)
         (string-replace s prefix 0 (string-length uri))
         s)))
 
 (define (add-new-prefix uri)
   (let* ((hash-pos (or (string-index uri #\#)
                        (string-index-right uri #\\)))
          (ns (substring uri 0 (+ hash-pos 1)))
          (new-prefix (gensym "pre")))
     (namespaces (cons (cons new-prefix ns) (namespaces)))
     uri))
 
 (define (text->name txt)   
   (let ((name (cond 
                 ((one-of-prefixes? prefixes (car txt)) (string-trim (car txt) #\#))
                 ((equal? (string-ref (car txt) 0) #\#) 
                  (resolve-namespaces (string-append "base:" (string-trim (car txt) #\#)) *namespaces*))
                 (else (add-new-prefix (car txt))))))
     (if *debug* 
         (begin (display "text->name : ")
                (write txt)
                (newline)
                (display "           : ")
                (write name)
                (newline)))
     name))
 
 
 )
