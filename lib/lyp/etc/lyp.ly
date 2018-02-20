#(begin
  ; file/path procedures based on code from oll-core:
  ;   https://github.com/openlilylib/oll-core/

  (use-modules
    (lily)
    (ice-9 regex)
    (ice-9 ftw))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;                  General utilities                     ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (lyp:coerce-string x)
    (if (symbol? x) (symbol->string x) x))

  (define (lyp:list-string-or-symbol? x)
    (or (list? x) (string? x) (symbol? x)))

  (define lyp:path-separator "/")
  (define (lyp:join-path . ls) (string-join ls lyp:path-separator))

  ; convert back-slashes to forward slashes (for use in lyp:split-path)
  (define (lyp:normalize-path path)
    (regexp-substitute/global #f "[\\]+" path 'pre "/" 'post))

  (define (lyp:split-path path)
    (string-split (lyp:normalize-path path) #\/))

  (define lyp:absolute-path-pattern
    (if (eq? PLATFORM 'windows) "^[a-zA-Z]:" "^/"))

  (define (lyp:absolute-path? path)
    (string-match lyp:absolute-path-pattern path))

  ; return an absolute path, resolving any . or .. parts
  (define (lyp:expand-path path)
    (let* (
      ; create a path list by joining the current directory
      (tmp-path (if (lyp:absolute-path? path)
                    path (lyp:join-path (ly-getcwd) path)))
      (src-list (lyp:split-path tmp-path))
      (dst-list '())
      (resolve (lambda (p)
        (cond
          ((eq? (length dst-list) 0) ; start of path
            (set! dst-list (list p)))
          ((or (string=? p "") (string=? p ".")) ; ignore empty part
            #f)
          ((string=? p "..") ; go up a level (remove last part from list)
            (set! dst-list (reverse (cdr (reverse dst-list)))))
          (else
            (set! dst-list (append dst-list (list p)))))))
    )
    (for-each resolve src-list)
    (apply lyp:join-path dst-list)))

  (define (lyp:for-each-matching-file pat proc)
    (let* (
        (startdir (lyp:find-pattern-start-dir pat))
        (pat-regexp (lyp:pattern->regexp pat))
        (proc (lambda (fn st flag)
          (begin
            (if (and (eq? flag 'regular) (string-match pat-regexp fn))
              (proc fn))
            #t
          )))
      )
      (ftw startdir proc)))

  ; convert a filename wildcard pattern to a regexp
  (define (lyp:pattern->regexp pat)
    (let* (
        (sub regexp-substitute/global)
        (pat (sub #f "\\." pat 'pre "\\." 'post))
        (pat (sub #f "\\*\\*/" pat 'pre "([^/]+/)@" 'post))
        (pat (sub #f "\\*" pat 'pre "[^/]+" 'post))
        (pat (sub #f "@" pat 'pre "*" 'post))
      )
      pat))

  ; find the start directory for a given filename pattern
  ; e.g. "abc/def/**/*.ly"  => "abc/def"
  ;      "/repo/docs/*"     => "/repo/docs"
  ;      "*.ly"             => "."
  ;      "../src/*.ly"      => "../src"
  ; if no start directory is found for the given pattern, returns "."
  (define (lyp:find-pattern-start-dir pat)
    (let* (
        (match (string-match "^(([^\\*]+)(/))" pat))
      )
      (if match (match:substring match 2) ".")))

  (define (lyp:directory? fn)
    (and (file-exists? fn)
         (eq? (stat:type (stat fn)) 'directory)))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;        package and include handling utilities          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; hash table mapping package refs to package names
  (define lyp:package-refs (make-hash-table))

  ; hash table mapping package names to package directories
  (define lyp:package-dirs (make-hash-table))

  ; hash table mapping package names to loaded state
  (define lyp:package-loaded? (make-hash-table))

  ; hash table mapping file paths to included state
  (define lyp:file-included? (make-hash-table))

  ; convert package ref to package name
  (define (lyp:ref->name ref) (let* (
      (clean-ref (car (string-split ref #\:)))
      (name (hash-ref lyp:package-refs clean-ref))
    )
    (or name (throw 'lyp:failure "lyp:ref->name"
      (format "Invalid package ref ~a" ref) #f))
  ))

  ; convert package reef to directory
  (define (lyp:name->dir name) (let (
      (dir (hash-ref lyp:package-dirs name))
    )
    (or dir (throw 'lyp-failure "lyp:name->dir"
      (format "Invalid package name ~a" ref) #f))
  ))

  ; Because the *location* in lilypond is kinda broken (it becomes unusable
  ; when using nested includes, even in > 2.19.22, we provide an alternative
  ; for keeping track of the current file, and thus be able to include files
  ; using relative path names (relative to the current file).
  (define lyp:last-this-file #f)
  (define (lyp:this-file) (or lyp:last-this-file lyp:input-filename))
  (define (lyp:this-dir) (dirname (lyp:this-file)))

  ; point to the entry point for the package being loaded
  (define lyp:this-package-entry-point #f)

  ; format include command for included file
  ; the template also sets the lyp:last-this-file to the
  ; included file, in order to keep track of file location
  (define (lyp:fmt-include path)
    (format "#(set! lyp:last-this-file \"~A\")\n\\include \"~A\"\n#(set! lyp:last-this-file \"~A\")\n"
      path path (lyp:this-file)))

  ; format include command for a package
  ; this template also sets the lyp:current-package-dir to the
  ; package entry point path, and resets it to its previous
  ; value after including the package files
  (define (lyp:fmt-require entry-point-path package-dir)
    (format "#(set! lyp:current-package-dir \"~A\")\n~A#(set! lyp:current-package-dir \"~A\")\n"
      package-dir (lyp:fmt-include entry-point-path) lyp:current-package-dir))

  ; helper function to cover API changes from 2.18 to 2.19
  (define (lyp:include-string str)
    (if (defined? '*parser*)
      (ly:parser-include-string str)
      (ly:parser-include-string parser str)))

  ; convert a path to an absolute path using the
  ; directory for the currently processed file
  (define (lyp:absolute-path-from-this-dir fn)
  (if (lyp:absolute-path? fn)
    fn
    (lyp:expand-path (lyp:join-path (lyp:this-dir) fn))))

  ; define list of finalizer lambdas to be called after the user's file has been
  ; processed. packages invoke (lyp:finalize proc) to add their own code.
  ; Finalizers are called in the order they were added.
  (define lyp:final-procs '())

  ; called after processing user's file, this procedure calls all registered
  ; finalizers.
  (define (lyp:call-finalizers)
    (for-each (lambda (p) (p)) lyp:final-procs))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;                      lyp API                           ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  (define (lyp:load:ref ref once)
    (let* (
        (ref (lyp:coerce-string ref))
      )
      (cond
        ((string-match "\\*" ref) (lyp:load:pattern pat once))
        ((lyp:directory? ref) (lyp:load:pattern (string-append ref "/*")  once))
        (else (lyp:load:file ref once)))
  ))

  (define (lyp:load:pattern pat once)
    (lyp:for-each-matching-file pat (lambda (fn) (lyp:load:file fn once))))

  (define (lyp:load:file fn once)
    (let* (
        (abs-fn (lyp:absolute-path-from-this-dir fn))
        (abs-fn-ly (string-append abs-fn ".ly"))
        (abs-fn-ily (string-append abs-fn ".ily"))
      )
      (cond
        ((file-exists? abs-fn) (lyp:load:include abs-fn once))
        ((and (file-exists? abs-fn-ly) (file-exists? abs-fn-ily)) 
          (throw 'lyp-failure "lyp:load:file"
            (format "Ambiguous filename ~a" fn) #f))
        ((file-exists? abs-fn-ly) (lyp:load:include abs-fn-ly once))
        ((file-exists? abs-fn-ily) (lyp:load:include abs-fn-ily once))
        (else (throw 'lyp-failure "lyp:load:file"
            (format "File not found: ~a" fn) #f)))))
  
  ; performs the include
  ; this procedure expects the path to be absolute
  ; and the file to exist
  (define (lyp:load:include path once)
    (if (not (and once (hash-ref lyp:file-included? path)))
      (begin
        (ly:debug "include ~a\n" path)
        (hash-set! lyp:file-included? path #t)
        (lyp:include-string (lyp:fmt-include path)))
      #f))

  ; load scheme file with correct relative path handling
  ; (deprecated?)
  (define (lyp:load path) (let* (
      (current-file (lyp:this-file))
      (current-dir  (dirname current-file))
      (abs-path     (if (lyp:absolute-path? path)
                        path
                        (lyp:expand-path (lyp:join-path current-dir path))))
    )
    (if (not (file-exists? abs-path))
      (throw 'lyp:failure "lyp:load"
        (format "File not found ~a" abs-path) #f)
    )
    (ly:debug (format "lyp:load ~a\n" abs-path))
    (set! lyp:last-this-file abs-path)
    (load abs-path)
    (set! lyp:last-this-file current-file)
  ))

  ; add a finalizer to be called after user's file is processed
  (define (lyp:finalize proc)
    (set! lyp:final-procs (append lyp:final-procs (list proc))))

  (define (lyp:require ref)
    (let* (
        (ref (lyp:coerce-string ref))
        (name (lyp:ref->name ref))
        (package-dir (lyp:name->dir name))
        (entry-point-path (lyp:join-path package-dir "package.ly"))
        (loaded? (hash-ref lyp:package-loaded? name))
        (last-package-entry-point lyp:this-package-entry-point)
      )
      (if (not loaded?) (begin
        (ly:debug "Loading package ~a at ~a" name package-dir)
        (hash-set! lyp:package-loaded? name #t)
        (set! lyp:this-package-entry-point entry-point-path)
        (lyp:include-string (lyp:fmt-require entry-point-path package-dir))
        (set! lyp:this-package-entry-point last-package-entry-point)))))

)

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
