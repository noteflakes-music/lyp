#(begin
  ; file/path procedures based on code from oll-core:
  ;   https://github.com/openlilylib/oll-core/

  (use-modules
    (lily)
    (ice-9 regex))

  (define lyp:path-separator "/")
  (define (lyp:join-path . ls) (string-join ls lyp:path-separator))

  ; convert back-slashes to forward slashes (for use in lyp:split-path)
  (define (lyp:normalize-path path)
    (regexp-substitute/global #f "[\\]+" path 'pre "/" 'post)
  )

  (define (lyp:split-path path)
    (string-split (lyp:normalize-path path) #\/))

  (define lyp:absolute-path-pattern
    (if (eq? PLATFORM 'windows) "^[a-zA-Z]:" "^/"))

  (define (lyp:absolute-path? path)
    (string-match lyp:absolute-path-pattern path))

  ; return an absolute path, resolving any . or .. parts
  (define (lyp:expand-path path) (let* (
      ; create a path list by joining the current directory
      (tmp-path (if (lyp:absolute-path? path)
                    path (lyp:join-path (ly-getcwd) path)))
      (src-list (lyp:split-path tmp-path))
      (dst-list '())
    )
    (for-each
      (lambda (p)
        (cond
          ((eq? (length dst-list) 0) ; start of path
            (set! dst-list (list p)))
          ((or (string=? p "") (string=? p ".")) ; ignore empty part
            #f)
          ((string=? p "..") ; go up a level (remove last part from list)
            (set! dst-list (reverse (cdr (reverse dst-list)))))
          (else
            (set! dst-list (append dst-list (list p))))))
      src-list)
    (apply lyp:join-path dst-list)
  ))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    (set! lyp:last-this-file abs-path)
    (load abs-path)
    (set! lyp:last-this-file current-file)
  ))

  (define (lyp:include-ly-file path once-only?) (let* (
      (current-file (lyp:this-file))
      (current-dir  (dirname current-file))
      (abs-path     (if (lyp:absolute-path? path)
                        path
                        (lyp:expand-path (lyp:join-path current-dir path))))
      (included?    (and once-only? (hash-ref lyp:file-included? abs-path)))
    )
    (ly:debug (format "lyp:include ~a\n" abs-path))
    (if (not (file-exists? abs-path))
      (throw 'lyp:failure "lyp:include-ly-file"
        (format "File not found ~a" abs-path) #f)
    )
    (if (not included?) (begin
      (hash-set! lyp:file-included? abs-path #t)
      (set! lyp:last-this-file abs-path)
      #{ \include #abs-path #}
      (set! lyp:last-this-file current-file)
    ))))

  (define (lyp:include      path) (lyp:include-ly-file path #f))
  (define (lyp:include-once path) (lyp:include-ly-file path #t))

  (define (lyp:require ref) (let* (
      (name (lyp:ref->name ref))
      (package-dir (lyp:name->dir name))
      (entry-point-path (lyp:join-path package-dir "package.ly"))
      (loaded? (hash-ref lyp:package-loaded? name))
      (prev-package-dir lyp:current-package-dir)
    )
    (if (not loaded?) (begin
      (ly:debug "Loading package ~a at ~a" name package-dir)
      (set! lyp:current-package-dir package-dir)
      (hash-set! lyp:package-loaded? name #t)
      (lyp:include entry-point-path)
      (set! lyp:current-package-dir prev-package-dir)
    ))))
)

% command form
require = #(define-void-function (parser location ref)(string?)
  (lyp:require ref))

pinclude = #(define-void-function (parser location ref)(string?)
  (lyp:include ref))

pincludeOnce = #(define-void-function (parser location ref)(string?)
  (lyp:include-once ref))
