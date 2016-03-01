% original code: 
%   https://github.com/openlilylib/oll-core/blob/master/internal/predicates.scm

#(begin
  (define (lilypond-version-string)
    (string-join
      (map (lambda (elt) (if (integer? elt) (number->string elt) elt))
        (ly:version))
     "."))

  (display (format "~a\n~a\n" (lilypond-version-string) (ly:get-option 'datadir)))
)


