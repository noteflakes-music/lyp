#(begin
  (define lyp:path-separator "/")
  (define (lyp:file-join . ls) (string-join ls lyp:path-separator))

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
  
  ; converts a package-relative path to absolute path. If the package is null,
  ; uses lyp:current-package-dir (which value is valid only on package loading)
  (define (lyp:package-file-path package path) (let* (
      (base-path (if (null? package) 
        lyp:current-package-dir (lyp:name->dir package)))
    )
    (lyp:file-join base-path path)
  ))
  
  ; converts a package file reference to absolute path
  (define (lyp:fileref->path ref) (let* (
      (split (string-split ref #\:))
      (qualified? (eq? (length split) 2))
      (package (if qualified? (list-ref split 0) %nil))
      (path (if qualified? (list-ref split 1) (list-ref split 0)))
    )
    (lyp:package-file-path package path)
  ))
  
  (define (lyp:load ref) (load (lyp:fileref->path ref)))
  
  (define (lyp:include-ly-file path once-only?) (let* (
      (included? (and once-only? (hash-ref lyp:file-included? path)))
    )
    (if (not (file-exists? path))
      (throw 'lyp:failure "lyp:include-ly-file"
        (format "File not found ~a" path) #f)
    )
    (if (not included?) (begin
      (hash-set! lyp:file-included? path #t)
      #{ \include #path #}
    ))
  ))
  
  (define (lyp:include ref)
    (lyp:include-ly-file (lyp:fileref->path ref) #f))
  (define (lyp:include-once ref)
    (lyp:include-ly-file (lyp:fileref->path ref) #t))
  
  (define (lyp:require ref) (let* (
      (name (lyp:ref->name ref))
      (package-dir (lyp:name->dir name))
      (entry-point-path (lyp:file-join package-dir "package.ly"))
      (loaded? (hash-ref lyp:package-loaded? name))
      (prev-package-dir lyp:current-package-dir)
    )
    (if (not loaded?) (begin
      (ly:debug "Loading package ~a at ~a" name package-dir)
      (set! lyp:current-package-dir package-dir)
      (hash-set! lyp:package-loaded? name #t)
      #{ \include #entry-point-path #}
      (set! lyp:current-package-dir prev-package-dir)
    ))
  ))
)

% command form
require = #(define-void-function (parser location ref)(string?)
  (lyp:require ref))


pinclude = #(define-void-function (parser location ref)(string?)
  (lyp:include ref))

pincludeOnce = #(define-void-function (parser location ref)(string?)
  (lyp:include-once ref))

