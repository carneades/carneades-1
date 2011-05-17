#!r6rs

(library
 
 (carneades lkif2 lkif2-export)
 
 (export lkif-export)
 
 (import (rnrs)         
         (carneades base)
         (carneades lkif2 lkif2-base)
         
         (carneades lkif2 lkif2-import) ; only for testing
         
         (carneades argument)
         (prefix (carneades statement) statement:)
         (carneades rule)
         (prefix (carneades table) table:)
         (carneades unify)
         (carneades system)
         (carneades lib xml sxml serializer)
         (carneades lib xml ssax util))
 
 
 ; --------------------------------
 ; misc functions
 
 (define *debug* #f)
 
 ; generates a new ID
 (define (new-id prefix)
   (symbol->string (gensym prefix)))
 
 ; functor? is needed to seperate Expressions in LKIF from Atoms.
 ; Expressions seen as s-expressions look the same compared to
 ; atoms seen as s-expressions. Therefor, if the predicate is a
 ; functor (in the sense of functor?) the s-expression is a LKIF-
 ; Expression.
 ;
 ; TODO:
 ;        - expand the list of functors
 ;        - is there a simpler way to define functor? ?
 (define (functor? f)
   (or (eq? f '+)
       (eq? f '-)
       (eq? f '*)
       (eq? f '/)
       (eq? f 'list)
       (eq? f 'cons)))
 
 #;(define axioms-table (table:make-table statement:statement-hash statement:statement=? null))
 
 
 ; --------------------------------
 ; export function
 
 
 ; lkif-export: struct:lkif-data (port | filename) -> void
 ; If `port-or-filename' is not supplied, the function writes the lkif-representation
 ; of the `export-data' to the current output-port.
 ; If `port-or-filename' is supplied and is a port, the function writes the
 ; lkif-representation of `export-data' to this port and returns an
 ; unspecified result.
 ; If `port-or-filename' is supplied and is a string, this string is treated as
 ; an output filename, the lkif-representation of `export-data' is written to
 ; that filename and an unspecified result is returned. If a file with the given
 ; name already exists, the effect is unspecified.
 
 (define (lkif-export imports export-data . port-or-filename)
   (let ((sxml-obj (lkif-data->sxml imports export-data)))
     (if *debug*
         (begin (write sxml-obj)
                (newline)
                (newline)))
     (if (null? port-or-filename)
         (srl:sxml->xml sxml-obj (current-output-port))
         (begin (if (and (string? (car port-or-filename))
                         (file-exists? (car port-or-filename)))
                    (delete-file (car port-or-filename)))
                (srl:sxml->xml sxml-obj (car port-or-filename))))))
 
 
 ; --------------------------------
 ; Conversion functions
 
 
 ; element->sxml: element-name element-value -> sxml
 (define (element->sxml name value)
   (list name value))
 
 ; elements->attributes: (list-of sxml) -> sxml
 (define (elements->attributes l)
   (cons '^ l))
 
 ; lkif-data->sxml: struct:lkif-data -> sxml
 (define (lkif-data->sxml import-list data)
   (let ((sources (lkif-data->sources data))
         (theory (lkif-data->theory import-list data))
         (argument-graphs (lkif-data->argument-graphs data)))
     (define lkif (list 'lkif))
     (if (not (null? sources))
         (set! lkif (append lkif (list sources))))
     (if (not (null? theory))
         (set! lkif (append lkif (list theory))))
     (if (not (null? argument-graphs))
         (set! lkif (append lkif (list argument-graphs))))
     lkif))
 
 
 
 ; lkif-data->sources: struct:lkif-data -> sxml
 (define (lkif-data->sources data)
   (let ((sources (lkif-data-sources data)))
     (if (null? sources)
         '()
         (cons 'sources (map source->sxml sources)))))
 
 ; source->sxml: struct:source -> sxml
 (define (source->sxml source)
   (list 'source
         (elements->attributes (list (element->sxml 'uri (source-uri source))
                                     (element->sxml 'element (source-element source))))))
 
 ; lkif-data->theory: struct:lkif-data -> sxml
 (define (lkif-data->theory import-list data)
   (let* ((attributes (elements->attributes (list (element->sxml 'id (new-id "theory")))))
          (imports (import-list->imports import-list))
          (rb (lkif-data-rulebase data))
          (splitted-rb (split-rulebase rb))
          (rules-with-body (car splitted-rb))
          (rules-without-body (cadr splitted-rb))
          (axioms (rules->axioms rules-without-body))
          (rules (rules->lkif-rules rules-with-body)))
     (define theory (list 'theory attributes))
     (if (not (null? axioms))
         (set! theory (append theory (list (cons 'axioms axioms)))))
     (if (not (null? imports))
         (set! theory (append theory imports)))
     (if (not (null? rules))
         (set! theory (append theory (list rules))))
     (if (= (length theory) 2)
         '()
         theory)))
 
 (define (import-list->imports import-list)
   (list (cons 'imports (map import->lkif import-list))))
 
 (define (import->lkif import)
   (let ((attributes (elements->attributes (list (element->sxml 'uri import)
                                                 (element->sxml 'prefix "")))))
     (list 'import attributes)))
 
 (define (split-rulebase rb)
   (divide-rules (rulebase-rules rb) '() '()))
 
 (define (divide-rules rules wb wob)
   (if (null? rules)
       (list wb wob)
       (let* ((r (car rules))
              (b (rule-body r)))
         (if (null? b)
             (divide-rules (cdr rules) wb (append wob (list r)))
             (divide-rules (cdr rules) (append wb (list r)) wob)))))
 
 (define (rules->axioms rules)
   (if (null? rules)
       '()
       (let* ((r (car rules))
              (h (rule-head r))
              (l (map (lambda (s)
                        (let* ((id (new-id "a"))
                               (attributes (elements->attributes (list (element->sxml 'id id))))
                               (wff (wff->sxml s)))
                          (list 'axiom attributes wff)))
                      h)))
         (append l (rules->axioms (cdr rules))))))
 
 
 ; context->axioms: context -> sxml
 #;(define (context->axioms context)
     (let ((axioms (table:keys (context-status context))))
       (let ((a (map (lambda (a) (axiom->sxml a (context-status context))) axioms)))
         (if (null? a)
             '()
             (cons 'axioms a)))))
 
 ; axiom->sxml: axiom table:statement->status -> sxml
 #;(define (axiom->sxml a t)
     (let* ((id (new-id "a"))
            (attributes (elements->attributes (list (element->sxml 'id id))))
            (wff (if (eq? (table:lookup t a 'accepted) 'rejected)
                     (list 'not (wff->sxml a))
                     (wff->sxml a))))
       (set! axioms-table (table:insert axioms-table a id))
       (list 'axiom
             attributes
             wff)))
 
 (define (parse-format expr l b)
   (cond ((null? l)
          '())
         ((and b
               (pair? (cdr l))
               (string=? (car l) ""))
          (cons (car expr)
                (cons (substring (cadr l) 1 (string-length (cadr l)))
                      (parse-format (cdr expr) (cddr l) #f))))
         ((and (not b)
               (char=? (string-ref (car l) 0) #\a))
          (cons (car expr) 
                (cons (substring (car l) 1 (string-length (car l)))
                      (parse-format (cdr expr) (cdr l) #f))))
         (else (cons (car l) (parse-format expr (cdr l) #f)))))
 
 (define (combine-expression-format expr fs)
   (let* ((l (string-split fs '(#\~)))
          (p (parse-format (cdr expr) l #t)))
     (filter (lambda (s)
               (not (and (string? s)
                         (string=? s ""))))
             (map text/term->sxml p))))
 
 (define (has-attributes? s)
   (and (pair? (cdr s))
        (pair? (cadr s))
        (eq? (caadr s) '^)))
 
 ; wff->sxml: wff -> sxml
 (define (wff->sxml f)
   (cond ((string? f) (list 's f))
         ((symbol? f) (list 's f))
         ((statement:fatom? f) (append (list 's
                                             (elements->attributes 
                                              (list (element->sxml 'pred (symbol->string (statement:statement-predicate f))))))
                                       (combine-expression-format (statement:fatom-term f)
                                                                  (statement:fatom-form f))))                                     
         ((pair? f) (case (car f)
                      ((not) (list 'not (wff->sxml (cadr f))))
                      ((and or if iff) (cons (car f) (map wff->sxml (cdr f))))
                      ((assuming) (let ((s (wff->sxml (cadr f))))
                                    (cons (car s)
                                          (if (has-attributes? s)
                                              (cons (elements->attributes (cons (element->sxml 'assumable "true")
                                                                                (cdadr s)))
                                                    (cddr s))
                                              (cons (elements->attributes (list (element->sxml 'assumable "true")))
                                                    (cdr s))))))
                      ((unless) (append (list 'not
                                              (elements->attributes (list (element->sxml 'exception "true"))))
                                        (map wff->sxml (cdr f))))
                      (else ; the wff is an atom
                       (append (list 's
                                     (elements->attributes (list (element->sxml 'pred (symbol->string (car f))))))
                               (map text/term->sxml (cdr f))))))
         (else (display "Error: unknown wff - ")
               (display f)
               (newline)
               '())))
 
 ; text/term->sxml: any -> sxml
 ;
 ; text/term->sxml converts the arguments of an predicate
 ; to the according sxml-object.
 ; An argument can be a text or a term.
 ; Texts are left as they are.
 ; For terms there will be no difference between constants and
 ; individuals as there is no correspondence for individuals
 ; in carneades and even in the lkif-import the additional
 ; information for individuals is lost. So every symbol will
 ; be a constant
 ; TODO:
 ;       - can constants be strings?
 ;       - and if, is a string a text or a constant?
 (define (text/term->sxml t)
   (cond ((boolean? t) (list 'c (if t "true" "false")))
         ((number? t) (list 'c t))
         ((string? t) t)
         ((statement:fatom? t) (append (list 's
                                             (elements->attributes 
                                              (list (element->sxml 'pred (symbol->string (statement:statement-predicate t))))))
                                       (combine-expression-format (statement:fatom-term t)
                                                                  (statement:fatom-form t))))
         ((variable? t) (let ((s (symbol->string t)))
                          (element->sxml 'v (substring s 1 (string-length s)))))
         ((symbol? t) (list 'c (symbol->string t)))
         ((pair? t) (let ((p (car t)))
                      (cond ((functor? p) (append (element->sxml 'expr
                                                                 (elements->attributes (list (element->sxml 'functor (symbol->string p)))))
                                                  (map text/term->sxml (cdr t)))) ; maybe write a term->sxml function
                            (else
                             (append (list 's
                                           (elements->attributes (list (element->sxml 'pred (symbol->string p)))))
                                     (map text/term->sxml (cdr t)))))))
         (else (display "Error: unknown text/term - ")
               (display t)
               (newline)
               '())))
 
 ; rulebase->rules: rulebase -> sxml
 (define (rules->lkif-rules rules)
   (let ((r (map rule->sxml rules)))
     (if (null? r)
         '()
         (cons 'rules r))))
 
 ; rule->sxml: struct:rule -> sxml
 (define (rule->sxml r)
   (let ((conj->sxml (lambda (c) (if (= (length c) 1)
                                     (wff->sxml (car c))
                                     (cons 'and (map wff->sxml c))))))
     (let ((attributes (elements->attributes (list (element->sxml 'id (symbol->string (rule-id r)))
                                                   (element->sxml 'strict (if (rule-strict r)
                                                                              "true"
                                                                              "false")))))
           (head (list 'head (conj->sxml (rule-head r))))
           (body (let ((b (rule-body r)))
                   (if (null? b)
                       '()
                       (if (= (length b) 1)
                           (list 'body (conj->sxml (car b)))
                           (list 'body (cons 'or (map conj->sxml b))))))))
       (if (null? body)
           (list 'rule
                 attributes
                 head)
           (list 'rule
                 attributes
                 head
                 body)))))
 
 
 
 ; lkif-data->argument-graphs: struct:lkif-data -> sxml
 #;(define (lkif-data->argument-graphs data)
     (let ((stages (lkif-data-stages data)))
       (if (null? stages)
           '()
           (cons 'argument-graphs (map stage->sxml stages)))))
 
 (define (lkif-data->argument-graphs data)
   (let ((args (lkif-data-argument-graphs data)))
     (if (null? args)
         '()
         (cons 'argument-graphs (map argument-graph->sxml args)))))
 
 ; stage->sxml: struct:stage -> sxml
 #;(define (stage->sxml s)
     (let* ((ag (stage-argument-graph s))
            (c (stage-context s))
            (statements-table (nodes->table (argument-graph-nodes ag)))
            (id (symbol->string (argument-graph-id ag)))
            (title (argument-graph-title ag))
            (issue-statement (table:lookup statements-table (argument-graph-main-issue ag) #f))
            (main-issue (begin (if *debug*
                                   (begin (display "table: ")
                                          (display (argument-graph-nodes ag))
                                          (newline)
                                          (display "issue: ")
                                          (display (argument-graph-main-issue ag))
                                          (display " - ")
                                          (display issue-statement)                              
                                          (newline)))
                               (if issue-statement
                                   (statement-id issue-statement)
                                   "")))
            (statements (apply-context c statements-table (table:objects (argument-graph-arguments ag))))
            (arguments (arguments->sxml (table:objects (argument-graph-arguments ag)) statements-table (context-substitutions c))))
       (list 'argument-graph
             (elements->attributes (list (element->sxml 'id id)
                                         (element->sxml 'title title)
                                         (element->sxml 'main-issue main-issue)
                                         ))
             statements
             arguments)))
 
 (define (argument-graph->sxml ag)
   (let* ((statements-table (nodes->table (list-nodes ag)))
          (id (symbol->string (argument-graph-id ag)))
          (title (argument-graph-title ag))
          (issue-statement (table:lookup statements-table (argument-graph-main-issue ag) #f))
          (main-issue (begin (if *debug*
                                 (begin (display "table: ")
                                        (display (list-nodes ag))
                                        (newline)
                                        (display "issue: ")
                                        (display (argument-graph-main-issue ag))
                                        (display " - ")
                                        (display issue-statement)                              
                                        (newline)))
                             (if issue-statement
                                 (statement-id issue-statement)
                                 "")))
          (statements (apply-status/standard ag statements-table (table:objects (argument-graph-arguments ag))))
          (arguments (arguments->sxml (table:objects (argument-graph-arguments ag)) statements-table)))
     (list 'argument-graph
           (elements->attributes (list (element->sxml 'id id)
                                       (element->sxml 'title title)
                                       (element->sxml 'main-issue main-issue)
                                       ))
           statements
           arguments)))
 
 ; nodes->table: (list-of node) -> table:atom->struct:statement
 (define (nodes->table n)
   (fold-left (lambda (t s)
                (insert-statement t s))
              (table:make-table statement:statement-hash statement:statement=? null)
              (map node-statement n)))
 
 ; insert-statement: table statement -> table
 (define (insert-statement tbl s)
   (let ((statement (statement->record s)))
     (table:insert tbl (statement-atom statement) statement)))
 
 ; statement->record: statement -> struct:statement
 (define (statement->record s)
   (let ((id (new-id "s"))
         (value "unknown")
         (assumption "false")
         (standard "BA")
         (atom s))
     (make-statement id
                     value
                     assumption
                     standard
                     atom)))
 
 ; status->value: 'stated|'questioned|'accepted|'rejected -> "unknown"|"true" |"false"
 (define (status->value st)
   (case st
     ((stated questioned) "unknown")
     ((accepted) "true")
     ((rejected) "false")
     (else "unknown")))
 
 ; status->assumption: 'stated|'questioned|'accepted|'rejected -> "true" |"false"
 (define (status->assumption st)
   (case st
     ((stated) "true")
     (else "false")))
 
 ; checks if the statement s is used as an assumption in any argument of args
 ; assumption-premise?: statement (list-of struct:argument) -> bool
 (define (assumption-premise? s args)
   (find (lambda (a)
           (let ((premises (argument-premises a)))
             (let ((prm (find (lambda (p)
                                (statement:statement=? (premise-statement p) s))
                              premises)))
               (and prm (assumption? prm)))))
         args)) 
 
 ; atom->sxml: atom (list-of struct:argument) substitutions -> sxml
 (define (atom->sxml a args)
   (cond ((string? a) (if (assumption-premise? a args)
                          (list 's
                                (elements->attributes (list (element->sxml 'assumable "true")))
                                a)
                          (list 's a)))
         ((statement:fatom? a) (append (list 's
                                             (elements->attributes 
                                              (list (element->sxml 'pred (symbol->string (statement:statement-predicate a))))))
                                       (combine-expression-format (statement:fatom-term a)
                                                                  (statement:fatom-form a))))
         ((symbol? a) (if (assumption-premise? a args)
                          (list 's
                                (elements->attributes (list (element->sxml 'assumable "true")))
                                (symbol->string a))                           
                          (list 's (symbol->string a))))
         ((pair? a) (if (assumption-premise? a args)
                        (append (list 's
                                      (elements->attributes (list (element->sxml 'pred (symbol->string (car a)))
                                                                  (element->sxml 'assumable "true"))))
                                (map text/term->sxml (cdr a)))
                        (append (list 's
                                      (elements->attributes (list (element->sxml 'pred (symbol->string (car a))))))
                                (map text/term->sxml (cdr a)))))
         
         (else (display "Error: unknown atom - ")
               (display a)
               (newline)
               '())))
 
 ; apply-context: context table:atom->struct:statement (list-of struct:argument) -> sxml
 (define (apply-status/standard ag t args)
   (let ((statement->sxml (lambda (a)
                            (let ((s (table:lookup t a #f))
                                  (st (status ag a)))
                              (list 'statement
                                    (elements->attributes 
                                     (list (element->sxml 'id (statement-id s))
                                           (element->sxml 'value (status->value st))
                                           (element->sxml 'assumption (status->assumption st))
                                           (element->sxml 'standard (string-upcase (symbol->string (proof-standard ag a))))))
                                    (atom->sxml a args)))))
         (l (table:keys t))) ; filter axioms
     (cons 'statements (map statement->sxml l))))
 
 ; arguments->sxml: (list-of argument) table:atom->struct:statement -> sxml
 (define (arguments->sxml args t)
   (let* ((premise->sxml (lambda (p)
                           (let* ((polarity (if (positive-premise? p)
                                                "positive"
                                                "negative"))
                                  (type (cond ((exception? p) "exception")
                                              ((assumption? p) "assumption")
                                              (else "ordinary")))
                                  (role (premise-role p))                                  
                                  (statement (statement-id (table:lookup t (premise-atom p) #f))))
                             (list 'premise
                                   (elements->attributes
                                    (list (element->sxml 'polarity polarity)
                                          (element->sxml 'type type)
                                          (element->sxml 'role role)
                                          (element->sxml 'statement statement)))))))
          (argument->sxml (lambda (a)
                            (let* ((conclusion (list 'conclusion
                                                     (elements->attributes 
                                                      (list (element->sxml 'statement
                                                                           (statement-id (table:lookup
                                                                                              t 
                                                                                              (argument-conclusion a)
                                                                                              #f)))))))
                                   (premises (cons 'premises
                                                   (map premise->sxml (argument-premises a)))))
                              (list 'argument
                                    (elements->attributes
                                     (list (element->sxml 'id (symbol->string (argument-id a)))
                                           (element->sxml 'title "")
                                           (element->sxml 'direction (symbol->string (argument-direction a)))
                                           (element->sxml 'scheme (argument-scheme a))
                                           (element->sxml 'weight 0.5)))
                                    conclusion
                                    premises)))))                                        
     (cons 'arguments (map argument->sxml args))))
 

 ;  ----------------------------------
 ;  Testing Code
 ; 
 ; (define import-data (lkif-import "C:\\test.xml")) 
 ; 
 ; (define s (lkif-data->sources import-data)) 
 ; 
 ; (define c (lkif-data-context import-data))
 ; 
 ; (define a (context->axioms c))
 ; 
 ; (define r (rulebase->rules (lkif-data-rulebase import-data)))
 
 )

