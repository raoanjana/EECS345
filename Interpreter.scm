;Anthony Dario, Anjana Rao, James Flinn
;Interpreter Project

(load "simpleParser.scm")

(define interpret
  (lambda (filename)
    (interpret-help (parser filename) '(() ()))))
  
(define interpret-help
  (lambda (tree state)
    (cond
      ((null? tree) (error 'empty-tree))
      ((eq? (identifier tree) 'var) (interpret-help (cdr tree) (MSdeclare (variable tree) (cddar tree) state)))
      ((eq? (identifier tree) '=) (interpret-help (cdr tree) (MSassign (variable tree) (expression-stmt tree) state)))
      ((eq? (identifier tree) 'if) (interpret-help (cdr tree) (if (MVcondition (condition-stmt tree) state)
                                                                  (interpret-help (then-stmt tree) state)
                                                                  (if (else? (car tree))
                                                                      (interpret-help (else-stmt tree) state)
                                                                      state))))
      ((eq? (identifier tree) 'return) (MVreturn (return-stmt tree) state))
      (else (error 'bad-identifier)))))

;This is gonna return the value of an expression
(define MVexpression
  (lambda (expression state)
       (cond
         ((number? expression) expression)
         ((eq? 'true expression) #t)
         ((eq? 'false expression) #f)
         ((variable? expression) (MVvariable expression state))
         ((eq? '+ (operator expression)) (+ (MVexpression (leftoperand expression) state)
                                            (MVexpression (rightoperand expression) state)))
         ((eq? '- (operator expression)) 
               (cond
                 ((unary? expression) (* (MVexpression (leftoperand expression) state) -1))
                 (else (- (MVexpression (leftoperand expression) state)
                          (MVexpression (rightoperand expression) state)))))
         ((eq? '* (operator expression)) (* (MVexpression (leftoperand expression) state)
                                            (MVexpression (rightoperand expression) state)))
         ((eq? '/ (operator expression)) (quotient (MVexpression (leftoperand expression) state)
                                                   (MVexpression (rightoperand expression) state)))
         ((eq? '% (operator expression)) (remainder (MVexpression (leftoperand expression) state)
                                                    (MVexpression (rightoperand expression) state)))
        (else (error 'bad-operator)))
       ))

;This should return the value of a condition
(define MVcondition
  (lambda (condition state)
    (cond
      ((number? condition) condition)
      ((variable? condition) (MVvariable condition))
      ((eq? 'true condition ) #t)
      ((eq? 'false condition ) #f)
      ((eq? '! (operator condition)) (not (MVcondition (leftoperand condition) state)))
      ((eq? '> (operator condition)) (> (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      ((eq? '>= (operator condition)) (>= (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      ((eq? '< (operator condition)) (< (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      ((eq? '<= (operator condition)) (<= (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      ((eq? '== (operator condition)) (eq? (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      ((eq? '!= (operator condition)) (not (eq? (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state))))
      ((eq? '&& (operator condition)) (and (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      ((eq? '|| (operator condition)) (or (MVcondition (leftoperand condition) state) (MVcondition (rightoperand condition) state)))
      (else (error 'bad-operator)))))

;This should return the value of a return statement
(define MVreturn
  (lambda (expression state) (MVexpression expression state)))

;this should return the value of a variable
(define MVvariable
  (lambda (variable state)
    (cond
      ((null? (namelist state)) (error 'undeclared-variable))
      ((eq? (car (namelist state)) variable) (car (valuelist state)))
      (else (MVvariable variable (cons (cdr (namelist state)) (cons (cdr (valuelist state)) '())))))))
                                             
;this updates the state after a declaration
(define MSdeclare
  (lambda (variable expression state)
    (cond
      ((null? expression) (cons (append (cons variable '()) (namelist state)) (cons (cons 'error '()) (valuelist state))))
      (else (MSassign variable (car expression) (MSdeclare variable '() state))))))

;this updates the state after an assignment
;trouble with the else statment
(define MSassign
  (lambda (variable expression state)
    (cond
      ((null? (namelist state)) (error 'undeclared-variable))
      ((eq? (car (namelist state)) variable) (cons (namelist state) (cons (cons (MVexpression expression state) (cdr (valuelist state))) '() )))
      (else (cons (cons (car (namelist state)) (namelist (MSassign variable expression (cons (cdr (namelist state)) (cons (cdr (valuelist state)) '() )))))
                  (cons (cons 
                         (car (valuelist state)) 
                         (valuelist (MSassign variable expression (cons 
                                                                   (cdr (namelist state)) 
                                                                   (cons (cdr (valuelist state)) '() ))))) '())
                                                                       )))))

(define MSassign2
  (lambda (variable expression state)
    (lambda (namelist valuelist)
      (append namelist valuelist)
      )
    (namelist state) (valuelist state)))

;ABSTRACTIONS
; the helper functions to determine where the operator and operands are depending on the 
(define operator car)

(define leftoperand cadr)

(define rightoperand caddr)

;these helper functions grab the variable name list or the value list from the state
(define namelist car)

(define valuelist cadr)

;these identify parse tree elements
(define identifier caar)
(define variable cadar)
(define expression-stmt caddar)
(define condition-stmt cadr)
(define then-stmt caddr)
(define else-stmt cadddr)
(define return-stmt cadar)

;this determines if an expression is unary
(define unary? 
  (lambda (l)
    (cond
      ((null? (cddr l)) #t)
      (else #f))))

;determines if an expression is a variable
(define variable?
  (lambda (var)
    (cond
      ((not (list? var)) #t)
      (else #f))))

; return true if if stmt has an else
(define else?
  (lambda (stmt)
    (cond
      ((null? (cdddr stmt)) #f)
      (else #t))))
