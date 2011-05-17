; Module header is generated automatically
;#cs(module common mzscheme

;; For PLT Schemes v.200

;(require 
;  (lib "defmacro.ss")
;  (lib "string.ss")
;  (rename (lib "pretty.ss") pp pretty-print))

#!r6rs

(library
 
 (carneades lib xml ssax common)
 
 (export and-let*)
 
 (import (rnrs))
 
 
 ; already in r6rs
 #;(define (command-line)
   (cons "plt" (vector->list (current-command-line-arguments)
                             ;	argv
                             )))
 
 ;(define (call-with-input-string str fun)
 ;   (fun (open-input-string str)))
 ;
 ;(define (call-with-output-string fun)
 ;  (let ((outs (open-output-string)))
 ;  (fun outs)
 ;  (get-output-string outs)))
 
 ; no get-output-string function in r6rs
 ;(define close-output-string get-output-string)
 
 ; already in r6rs
 #;(define (filter pred lis)			
   (let rpt ((l lis))		
     (if (null? l) 
         '()
         (if (pred (car l))
             (cons (car l) (rpt (cdr l)))
             (rpt (cdr l))))))
 
 (define-syntax and-let*                                                            
   (syntax-rules ()                   
     ((and-let* () body ...)
      (begin body ...))
     ((and-let* ((var expr) clauses ...) body ...) 
      (let ((var expr))
        (if var (and-let* (clauses ...) body ...) #f)))
     ((and-let* ((expr) clauses ...) body ...)
      (if expr (and-let* (clauses ...) body ...) #f))
     ((and-let* (var clauses ...) body ...)
      (if var (and-let* (clauses ...) body ...) #f))
     ))                  
 
 
 )
