#(load lyp:scm-path)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                  Lilypond commands                     %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lyp-load = #(define-void-function (parser location ref)(lyp:list-string-or-symbol?)
  (if (list? ref)
    (for-each (lambda (r) (lyp:load:ref r #f)) ref)
    (lyp:load:ref ref #f)))

lyp-include = #(define-void-function (parser location ref)(lyp:list-string-or-symbol?)
  (if (list? ref)
    (for-each (lambda (r) (lyp:load:ref r #t)) ref)
    (lyp:load:ref ref #t)))

lyp-require = #(define-void-function (parser location ref)(lyp:list-string-or-symbol?)
  (if (list? ref)
    (for-each (lambda (r) (lyp:require r) ref))
    (lyp:require ref)))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%             Deprecated Lilypond commands               %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#(begin
  (define (lyp:show-deprecated-msg location msg)
    (if (not lyp:this-package-entry-point)
      (begin
        (if lyp:verbose 
          (ly:input-warning location msg)
          (ly:debug msg)
        )
        ; (ly:input-message location msg)
        ;(lyp:show-deprecated-docs-msg)
      )))
  
  (define lyp:deprecated-docs-msg-shown #f)

  (define (lyp:show-deprecated--docs-msg)
    (if (not lyp:deprecated-docs-msg-shown)
    (begin
      (set! lyp:deprecated-docs-msg-shown #t)
      (lyp:finalize (lambda ()
        (ly:debug lyp:msg:deprecated:docs))))))

  (define lyp:msg:deprecated:pinclude
    "\\pinclude is deprecated. Please use \\lyp-load instead.")

  (define lyp:msg:deprecated:pincludeOnce
    "\\pincludeOnce is deprecated. Please use \\lyp-include instead.")
  
  (define lyp:msg:deprecated:pcondInclude
    "\\pcondInclude is deprecated. Please wrap your \\lyp-load call with a scheme expression.")
  
  (define lyp:msg:deprecated:pcondIncludeOnce
    "\\pcondIncludeOnce is deprecated. Please wrap your \\lyp-include call with a scheme expression.")
  
  (define lyp:msg:deprecated:require
    "\\require is deprecated. Please use \\lyp-require instead.")

  (define lyp:msg:deprecated:docs
    "\n****************************************\nThe code in your file and/or packages you use include deprecated commands that will be removed in a future version of lyp. For more information on deprecated commands see the lyp user guide:\n  http://lyp.noteflakes.com/\n****************************************\n")
)

pinclude = #(define-void-function (parser location ref)(string-or-symbol?)
  (begin
    (lyp:show-deprecated-msg location lyp:msg:deprecated:pinclude)
    (lyp:load:ref ref #f)))

pincludeOnce = #(define-void-function (parser location path)(string-or-symbol?)
  (begin
    (lyp:show-deprecated-msg location lyp:msg:deprecated:pincludeOnce)
    (lyp:load:ref path #t)))

pcondInclude = #(define-void-function (parser location expr path)(scheme? string-or-symbol?)
  (begin
    (lyp:show-deprecated-msg location lyp:msg:deprecated:pcondInclude)
    (if expr (lyp:load:ref path #f))
  ))

pcondIncludeOnce = #(define-void-function (parser location expr path)(scheme? string-or-symbol?) 
  (begin
    (lyp:show-deprecated-msg location lyp:msg:deprecated:pcondIncludeOnce)
    (if expr (lyp:load:ref path #t))))

require = #(define-void-function (parser location ref)(string-or-symbol?)
  (begin
    (lyp:show-deprecated-msg location lyp:msg:deprecated:require)
    (lyp:require ref)))
