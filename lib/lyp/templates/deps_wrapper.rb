# Expect _ to be a hash of the form:
# {
#   user_file: <path>
#   package_paths: {
#     <specifier> => <package path>
#     ...
#   }
# }

require 'fileutils'

user_filename = File.expand_path(_[:user_file])
user_dirname = File.dirname(user_filename)

current_package_dir = _[:current_package_dir] || FileUtils.pwd

# The wrapper defines a few global variables:
# 
# lyp-input-filename      - the absolute path to the input file name
# lyp-input-dirname       - the absolute path to the input file directory name
# lyp-cwd                 - the current working directory
# lyp-current-package-dir - the directory for the package currently being loaded
# lyp-package-refs        - a hash table mapping package refs to package entry 
#                           point absolute paths
# lyp-package-loaded      - a hash table for keeping track of loaded packages
# lyp-file-included       - a hash table for keeping track of include files

`
#(begin
  (define lyp-input-filename "{{user_filename}}")
  (define lyp-input-dirname "{{user_dirname}}")
  (define lyp-cwd "{{FileUtils.pwd}}")
  (define lyp-current-package-dir "{{current_package_dir}}")
  (define lyp-package-refs (make-hash-table))`

_[:package_paths].each do |spec, path|
`
  (hash-set! lyp-package-refs "{{spec}}" "{{path}}")`
end

# package-loaded is hash table used for tracking loaded packages, so each
# package is loaded only once.

# package-loaded is hash table used for tracking loaded packages, so each
# package is loaded only once.

`
  (define lyp-package-loaded (make-hash-table))
  (define lyp-file-included (make-hash-table))
)
`

# define the \require command for loading packages
`
require = #(define-void-function (parser location package)(string?)
  (let* 
    (
      (path (hash-ref lyp-package-refs package))
      (loaded? (hash-ref lyp-package-loaded path))
      (package-dir (dirname path))
      (prev-package-dir lyp-current-package-dir)
    )
    (if (and path (not loaded?)) (begin
      (if (not (file-exists? path)) (
        (ly:error "Failed to load package ~a (file not found ~a)" package path)
      ))
      (ly:debug "Loading package ~a at ~a" package package-dir)
      (set! lyp-current-package-dir package-dir)
      (hash-set! lyp-package-loaded path #t)
      #{ \include #path #}
      (set! lyp-current-package-dir prev-package-dir)
    ))
  )
)
`

# define the \pinclude command for including files inside the current package

`
pinclude = #(define-void-function (parser location path)(string?)
  (let* 
    (
      (full-path (format "~a/~a" lyp-current-package-dir path))
      (loaded? (hash-ref lyp-file-included full-path))
    )
    (if (and full-path (not loaded?)) (begin
      (if (not (file-exists? full-path)) (
        (ly:error "File not found ~a" full-path)
      ))
      (hash-set! lyp-file-included full-path #t)
      #{ \include #full-path #}
    ))
  )
)
`

# define the \pload scheme function, for loading scheme files inside the current
# package
`
#(define (pload path)
  (let* 
    (
      (full-path (format "~a/~a" lyp-current-package-dir path))
    )
    (load full-path)
  )
)
`

# load the user's file
`
#(ly:set-option 'relative-includes #t)
#(ly:debug "package loader is ready")
\include "{{user_filename}}"
`