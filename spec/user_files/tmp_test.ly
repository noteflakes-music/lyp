% test file for testing scheme interface from command line.
%
%   $ bin/lilypond spec/user_files/tmp_test.ly

\version "2.18.2"
\require "assert@0.2.0"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lyp:input-filename, lyp:input-dirname
#(assert:string=? (basename lyp:input-filename) "tmp_test.ly")
#(assert:string=? lyp:input-dirname (dirname lyp:input-filename))
#(assert:string=? lyp:input-filename 
  (string-append lyp:input-dirname "/" "tmp_test.ly"))

%lyp:current-package-dir defaults to working directory
#(assert:string=? lyp:current-package-dir lyp:cwd)

% lyp:package-refs
#(assert (hash-table? lyp:package-refs))
#(assert:string=? (hash-ref lyp:package-refs "assert@0.2.0") "assert")
#(assert:string=? (lyp:ref->name "assert@0.2.0") "assert")

#(assert:throw (lambda () (lyp:ref->name "assert>=0.1.3")))

% lyp:package-dirs
#(assert (hash-table? lyp:package-dirs))

% should raise on unknown package name
#(assert:throw (lambda () (lyp:name->dir "null")))

#(assert:throw (lambda () (lyp:load "blah.scm")))
#(assert:throw (lambda () (lyp:load "assert/blah.scm")))

#(display (format "last-this-file: ~a\n" lyp:last-this-file))

% lyp:load
#(lyp:load "null/inc.scm")
#(assert (defined? 'null:test))
#(assert:throw (lambda () (lyp:load "null/ff.scm")))
#(assert:throw (lambda () (lyp:load "abc/ff.scm")))

#(define null:counter0 0)
#(define null:counter1 0)
#(define null:counter2 0)
#(define null:counter3 0)

% \pinclude
\pinclude "null/include.ly"
\pinclude "null/include.ly"
#(assert:eq? null:counter1 2)
#(assert:throw (lambda () (pinclude "null/abc.ly")))
#(assert:throw (lambda () (pinclude "abc/def.ly")))

% \pincludeOnce
\pincludeOnce "null/include_once.ly"
\pincludeOnce "null/include_once.ly"
#(assert:eq? null:counter2 1)
#(assert:throw (lambda () (pincludeOnce "null/abc.ly")))
#(assert:throw (lambda () (pincludeOnce "abc/def.ly")))

#(hash-clear! lyp:file-included?)

\pinclude "null/include.ly"
\pinclude "null/include.ly"
#(assert:eq? null:counter1 4)

\pincludeOnce "null/include_once.ly"
\pincludeOnce "null/include_once.ly"
#(assert:eq? null:counter2 2)

#(set! lyp:current-package-dir (string-append lyp:cwd "/spec/user_files"))

\pinclude "./counter3.ly"
\pinclude "./counter3.ly"
#(assert:eq? null:counter3 2)

#(hash-set! lyp:package-refs "null" "null")
#(hash-set! lyp:package-refs "null@0.1.2" "null")
#(hash-set! lyp:package-dirs "null" (string-append lyp:cwd "/spec/user_files/null"))

% \require
\require "null@0.1.2"

% form used for package testing, providing a relative path for the package
\require "null:.."
#(assert:eq? null:counter0 1)
#(assert:throw (lambda () (require "null>=0.1.2"))) % invalid ref
#(assert:throw (lambda () (require "abc"))) % invalid ref

#(hash-clear! lyp:package-loaded?)

\require "null@0.1.2"
\require "null@0.1.2"
#(assert:eq? null:counter0 2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#(assert:string=? (lyp:join-path "." "x" "y") "./x/y")
#(assert:equal? (lyp:split-path "./x/y") '("." "x" "y"))
#(assert:equal? (lyp:split-path "abc/def\\ghi") '("abc" "def" "ghi"))


#(assert (not(lyp:absolute-path? "./x")))
#(assert (not(lyp:absolute-path? "x")))
#(assert (not(lyp:absolute-path? "../x/y")))

#(assert (lyp:absolute-path? "/x"))
#(assert (lyp:absolute-path? "/x/y"))

#(assert:string=? (lyp:expand-path "x/y") (lyp:join-path lyp:cwd "x/y"))
#(assert:string=? (lyp:expand-path "/x/y") "/x/y")
#(assert:string=? (lyp:expand-path "x/../y") (lyp:join-path lyp:cwd "y"))
#(assert:string=?
  (lyp:expand-path (lyp:join-path lyp:cwd "x/../y")) (lyp:join-path lyp:cwd "y"))

#(assert:string=? (lyp:this-file)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files/tmp_test.ly")))

#(assert:string=? (lyp:this-dir)
  (lyp:expand-path (lyp:join-path lyp:cwd "spec/user_files")))
  
\pinclude "inc/scheme_interface_test_contd.ly"