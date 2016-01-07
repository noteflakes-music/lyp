# Expect _ to be a hash of the form:
# {
#   user_file: <path>
#   package_paths: {
#     <specifier> => <package path>
#     ...
#   }
# }

# define mapping of requested packages to actual file names
# package-refs is a hash table with an entry for each package reference made
# using \require, either in user files or in package files (for transitive dependencies).

`\version "2.19.31"

#(begin
  (define package-refs (make-hash-table))`

_[:package_paths].each do |spec, path|
`
  (hash-set! package-refs "{{spec}}" "{{path}}")`
end

# package-loaded is hash table used for tracking loaded packages, so each
# package is loaded only once.
`
  (define package-loaded (make-hash-table))
)
`

# define the \require command
`
require = #(define-void-function (parser location package)(string?)
  (let* 
    (
      (path (hash-ref package-refs package))
      (loaded? (hash-ref package-loaded path))
      (package-dir (dirname path))
    )
    (if (and path (not loaded?)) (begin
      (if (not (file-exists? path)) (
        (ly:error "Failed to load package ~a (file not found ~a)" package path)
      ))
      (ly:debug "Loaded package ~a at ~a" package package-dir)
      (hash-set! package-loaded path #t)
      #{ \include #path #}
    ))
  )
)
`

# load the user's file

`
#(ly:debug "package loader is ready")
#(ly:set-option 'relative-includes #t)
\include "{{_[:user_file]}}"
`