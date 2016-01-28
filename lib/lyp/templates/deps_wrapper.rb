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
# lyp:input-filename      - the absolute path to the input file name
# lyp:input-dirname       - the absolute path to the input file directory name
# lyp:current-package-dir - the directory for the package currently being loaded
# lyp:package-refs        - a hash table mapping package refs to package entry 
#                           point absolute paths
# lyp:package-loaded      - a hash table for keeping track of loaded packages
# lyp:file-included       - a hash table for keeping track of include files

`
#(ly:set-option 'relative-includes #t)
\include "{{Lyp::LYP_LY_LIB_PATH}}"

#(begin
  (define lyp:input-filename "{{user_filename}}")
  (define lyp:input-dirname "{{user_dirname}}")
  (define lyp:current-package-dir "{{current_package_dir}}")
`

_[:package_refs].each do |spec, path|
`
  (hash-set! lyp:package-refs "{{spec}}" "{{path}}")`
end

_[:package_dirs].each do |package, path|
`
  (hash-set! lyp:package-dirs "{{package}}" "{{path}}")`
end


`
)

#(ly:debug "package loader is ready")
\include "{{user_filename}}"
`