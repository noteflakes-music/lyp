\version "2.18.2"
\require "assert@0.2.0"

% lyp:input-filename, lyp:input-dirname
#(assert:string=? (basename lyp:input-filename) "scheme_interface_test.ly")
#(assert:string=? lyp:input-dirname (dirname lyp:input-filename))
#(assert:string=? lyp:input-filename 
  (string-append lyp:input-dirname "/" "scheme_interface_test.ly"))

%lyp:current-package-dir defaults to working directory
#(assert:string=? lyp:current-package-dir (getcwd))

% lyp:package-refs
#(assert (hash-table? lyp:package-refs))
#(assert:string=? (hash-ref lyp:package-refs "assert@0.2.0") "assert")
#(assert:string=? (lyp:ref->name "assert@0.2.0") "assert")

#(assert:throw (lambda () (lyp:ref->name "assert>=0.1.3")))

#(define tmp:assert-dir
  (string-append (getcwd) "/spec/package_setups/tmp/assert@0.2.0"))

% lyp:package-dirs
#(assert (hash-table? lyp:package-dirs))
#(assert:string=? (hash-ref lyp:package-dirs "assert") tmp:assert-dir)

#(assert:string=? (lyp:name->dir "assert") tmp:assert-dir)
% should raise on unknown package name
#(assert:throw (lambda () (lyp:name->dir "null")))

% lyp:package-file-path
#(assert:string=? (lyp:package-file-path "assert" "inc/blah.ly")
  (string-append tmp:assert-dir "/inc/blah.ly"))
% should raise on unknown package name
#(assert:throw (lambda () (lyp:package-file-path "abc" "def")))

% lyp:fileref->path
#(assert:string=? (lyp:fileref->path "blah.ly")
  (string-append lyp:current-package-dir "/blah.ly"))
#(assert:string=? (lyp:fileref->path "assert:blah.ly")
  (string-append tmp:assert-dir "/blah.ly"))
% should raise on unknown package name
#(assert:throw (lambda () (lyp:fileref->path "abc:def.ly")))

#(assert:throw (lambda () (lyp:load "blah.scm")))
#(assert:throw (lambda () (lyp:load "assert:blah.scm")))



#(hash-set! lyp:package-refs "null" "null")
#(hash-set! lyp:package-refs "null@0.1.2" "null")
#(hash-set! lyp:package-dirs "null" (string-append (getcwd) "/spec/user_files/null"))



% lyp:load
#(lyp:load "null:inc.scm")
#(assert (defined? 'null:test))
#(assert:throw (lambda () (lyp:load "null:ff.scm")))
#(assert:throw (lambda () (lyp:load "abc:ff.scm")))

%
#(define null:counter0 0)
#(define null:counter1 0)
#(define null:counter2 0)
#(define null:counter3 0)

% lyp:include
#(lyp:include "null:include.ly")
#(lyp:include "null:include.ly")
#(assert:eq? null:counter1 2)
#(assert:throw (lambda () (lyp:include "null:abc.ly")))
#(assert:throw (lambda () (lyp:include "abc:def.ly")))

% lyp:include-once
#(lyp:include-once "null:include_once.ly")
#(lyp:include-once "null:include_once.ly")
#(assert:eq? null:counter2 1)
#(assert:throw (lambda () (lyp:include-once "null:abc.ly")))
#(assert:throw (lambda () (lyp:include-once "abc:def.ly")))

#(hash-clear! lyp:file-included?)

\pinclude "null:include.ly"
\pinclude "null:include.ly"

#(assert:eq? null:counter1 4)

\pincludeOnce "null:include_once.ly"
\pincludeOnce "null:include_once.ly"

#(assert:eq? null:counter2 2)

#(set! lyp:current-package-dir (string-append (getcwd) "/spec/user_files"))

\pinclude "./counter3.ly"
\pinclude "./counter3.ly"
#(assert:eq? null:counter3 2)

% % lyp:require
#(lyp:require "null@0.1.2")

% form used for package testing, providing a relative path for the package
#(lyp:require "null:..")
#(assert:eq? null:counter0 1)
#(assert:throw (lambda () (lyp:require "null>=0.1.2"))) % invalid ref
#(assert:throw (lambda () (lyp:require "abc"))) % invalid ref

#(hash-clear! lyp:package-loaded?)

\require "null@0.1.2"
\require "null@0.1.2"
#(assert:eq? null:counter0 2)
