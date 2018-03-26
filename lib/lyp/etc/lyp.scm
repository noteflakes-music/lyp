;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                  Lyp scheme API                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-modules
  (lily)
  (ice-9 ftw)
  (ice-9 popen)
  (ice-9 rdelim)
  (ice-9 regex))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                       Utilities                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; file/path procedures based on code from oll-core:
;;;   https://github.com/openlilylib/oll-core/

(define (lyp:coerce-string x)
  (if (symbol? x) (symbol->string x) x))

(define (lyp:list-string-or-symbol? x)
  (or (list? x) (string? x) (symbol? x)))

(define lyp:path-separator "/")
(define (lyp:join-path . ls) (string-join ls lyp:path-separator))

;;; Convert back-slashes to forward slashes (for use in lyp:split-path)
(define (lyp:normalize-path path)
  (regexp-substitute/global #f "[\\]+" path 'pre "/" 'post))

(define (lyp:split-path path)
  (string-split (lyp:normalize-path path) #\/))

(define lyp:absolute-path-pattern
  (if (eq? PLATFORM 'windows) "^[a-zA-Z]:" "^/"))

(define (lyp:absolute-path? path)
  (string-match lyp:absolute-path-pattern path))

;;; Calculate absolute path, resolving any . or .. parts
(define (lyp:expand-path path)
  (let* ((tmp-path (if (lyp:absolute-path? path)
                       path 
                       (lyp:join-path (ly-getcwd) path)))
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
               (set! dst-list (append dst-list (list p))))))))
    (for-each resolve src-list)
    (apply lyp:join-path dst-list)))

;;; Iterate over files matching pattern
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

;;; Convert a filename wildcard pattern to a regexp
(define (lyp:pattern->regexp pat)
  (let* (
      (sub regexp-substitute/global)
      (pat (sub #f "\\." pat 'pre "\\." 'post))
      (pat (sub #f "\\*\\*/" pat 'pre "([^/]+/)@" 'post))
      (pat (sub #f "\\*" pat 'pre "[^/]+" 'post))
      (pat (sub #f "@" pat 'pre "*" 'post))
    )
    pat))

;;; find the start directory for a given filename pattern
;;; e.g. "abc/def/**/*.ly"  => "abc/def"
;;;      "/repo/docs/*"     => "/repo/docs"
;;;      "*.ly"             => "."
;;;      "../src/*.ly"      => "../src"
;;; if no start directory is found for the given pattern, returns "."
(define (lyp:find-pattern-start-dir pat)
  (let* (
      (match (string-match "^(([^\\*]+)(/))" pat))
    )
    (if match (match:substring match 2) ".")))

(define (lyp:directory? fn)
  (and (file-exists? fn)
        (eq? (stat:type (stat fn)) 'directory)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     File loading                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; hash table mapping file paths to included state
(define lyp:file-included? (make-hash-table))

;;; Because *location* in lilypond is kinda broken (it becomes unusable for
;;; keeping track of the current file, and thus be able to include files using
;;; relative path names (relative to the current file).
(define lyp:last-this-file #f)

(define (lyp:this-file) (or lyp:last-this-file lyp:input-filename))
(define (lyp:this-dir) (dirname (lyp:this-file)))

(define lyp:fmt-include-template
  "#(set! lyp:last-this-file \"~A\")\n\\include \"~A\"\n#(set! lyp:last-this-file \"~A\")\n")

;;; Format include command for included file. the template also sets
;;; lyp:last-this-file to the included file, in order to keep track of file 
;;; location.
(define (lyp:fmt-include path)
  (format lyp:fmt-include-template path path (lyp:this-file)))

; helper function to cover API changes from 2.18 to 2.19
(define (lyp:include-string str)
  (if (defined? '*parser*)
    (ly:parser-include-string str)
    (ly:parser-include-string parser str)))

;;; Convert a path to an absolute path using the
;;; directory for the currently processed file
(define (lyp:absolute-path-from-this-dir fn)
  (if (lyp:absolute-path? fn)
      fn
      (lyp:expand-path (lyp:join-path (lyp:this-dir) fn))))

(define (lyp:load-ref ref once)
  (let* ((ref (lyp:coerce-string ref)))
    (cond
      ((string-match "\\*" ref)
        (lyp:load-pattern pat once))
      ((lyp:directory? ref)
        (lyp:load-pattern (string-append ref "/*")  once))
      (else
        (lyp:load-file ref once)))))

(define (lyp:load-pattern pat once)
  (lyp:for-each-matching-file pat
    (lambda (fn) (lyp:load-file fn once))))

(define (lyp:load-file fn once)
  (let* ((abs-fn (lyp:absolute-path-from-this-dir fn))
         (abs-fn-ly (string-append abs-fn ".ly"))
         (abs-fn-ily (string-append abs-fn ".ily")))
    (cond
      ((file-exists? abs-fn)
        (lyp:load-perform abs-fn once))
      ((and (file-exists? abs-fn-ly) (file-exists? abs-fn-ily))
        (throw 'lyp-failure "lyp:load-file"
          (format "Ambiguous filename ~a" fn) #f))
      ((file-exists? abs-fn-ly)
        (lyp:load-perform abs-fn-ly once))
      ((file-exists? abs-fn-ily)
        (lyp:load-perform abs-fn-ily once))
      (else
        (throw 'lyp-failure "lyp:load-file"
          (format "File not found: ~a" fn) #f)))))

;;; Perform file loading
;;; expects the path to be absolute and the file to exist
(define (lyp:load-perform path once)
  (if (not (and once (hash-ref lyp:file-included? path)))
      (begin
        (ly:debug "include ~a\n" path)
        (hash-set! lyp:file-included? path #t)
        (lyp:include-string (lyp:fmt-include path)))
      #f))

; load scheme file with correct relative path handling
; (deprecated?)
(define (lyp:load-scm path)
  (let* ((current-file (lyp:this-file))
         (current-dir (dirname current-file))
         (abs-path (if (lyp:absolute-path? path)
                       path
                       (lyp:expand-path (lyp:join-path current-dir path)))))
    (if (not (file-exists? abs-path))
        (throw 'lyp:failure "lyp:load"
          (format "File not found ~a" abs-path) #f))
    (set! lyp:last-this-file abs-path)
    (load abs-path)
    (set! lyp:last-this-file current-file)))

(define lyp:load lyp:load-scm)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                      Finalizers                      ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Define list of finalizer lambdas to be called after the user's file has 
;;; been processed. packages use lyp:finalize to add their own code.
;;; Finalizers are called in the order they were added.
(define lyp:final-procs '())

;;; Invoke finalizers after processing user's file
(define (lyp:call-finalizers)
  (for-each (lambda (p) (p)) lyp:final-procs))

;;; Add a finalizer to be called after user's file is processed
(define (lyp:finalize proc)
  (set! lyp:final-procs (append lyp:final-procs (list proc))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;             Package reference resolution             ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Run given command and return its output
(define (lyp:pread cmd)
  (let* ((port (open-input-pipe cmd))
         (output (read-delimited "" port)))
    (close-pipe port)
    (if (string? output)
        output
        (throw 'lyp:failure "lyp:pread"
          (format "Command failed: ~a" cmd) #f))))

;;; Format external resolver command
;;; (expects lyp:resolver-path to be set)
(define (lyp:format-resolver-cmd ref)
  (string-append lyp:resolver-path " " ref))

;;; Resolve package ref by running external resolver
;;; returns an alist containing the following keys
;;;   'name
;;;   'version
;;;   'path
(define (lyp:resolve-package-ref ref)
  (catch #t
    (lambda ()
      (eval-string (lyp:pread (lyp:format-resolver-cmd ref))))
    (lambda (key . parameters)
      (throw 'lyp:failure "lyp:resolve-package-ref"
        (format "Failed to resolve package reference ~a" ref) #f))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                   Package loading                    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Variable pointing to the entry point for the package being loaded
(define lyp:current-package-entry-point #f)

;;; Hash of package info as received from resolver
(define lyp:package-info (make-hash-table))

(define (lyp:require ref)
  (let* ((ref (lyp:coerce-string ref))
         (package-info (lyp:resolve-package-ref ref))
         (package-name (assq-ref package-info 'name))
         (package-version (assq-ref package-info 'version))
         (entry-point (assq-ref package-info 'path))
         (package-dir (dirname entry-point))
         (old-package-info (hash-ref lyp:package-info package-name)))

    (cond
      ; load package if not already loaded
      ((not old-package-info) 
        (begin
          (ly:message "Loading package ~a at ~a" package-name package-dir)
          (hash-set! lyp:package-info package-name package-info)
          (lyp:include-string 
            (lyp:fmt-require entry-point package-dir))))
      ; check for version mismatch
      ((not (string=? package-version (hash-ref old-package-info 'version)))
        (throw 'lyp:failure "lyp:require"
          (format "Conflicting versions encountered for package ref ~a" ref) #f))
      (else #f))))

(define lyp:fmt-require-template "
  #(set! lyp:current-package-entry-point \"~A\")
  #(set! lyp:current-package-dir \"~A\")
  ~A
  #(set! lyp:current-package-entry-point \"~A\")
  #(set! lyp:current-package-dir \"~A\")")

(define (lyp:fmt-require entry-point-path package-dir)
  (format lyp:fmt-require-template
    entry-point-path
    package-dir
    (lyp:fmt-include entry-point-path)
    lyp:current-package-entry-point
    lyp:current-package-dir))
