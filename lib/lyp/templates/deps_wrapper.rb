# Expect _ to be a hash of the form:
# {
#   user_file: <path>
#   package_paths: {
#     <specifier> => <package path>
#     ...
#   }
# }

if _[:opts][:lilypond_version]
`
\version "{{_[:opts][:lilypond_version]}}"
`
end

user_filename = File.expand_path(_[:user_file])
user_dirname = File.dirname(user_filename)

quote_path = lambda do |path|
  path = path.gsub("\\", "/") if Lyp::WINDOWS
  path.inspect
end

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

if _[:opts][:snippet_paper_preamble]
`
\paper {
  indent = 0\mm
  oddHeaderMarkup = ""
  evenHeaderMarkup = ""
  oddFooterMarkup = ""
  evenFooterMarkup = ""
}
`
end

`
#(ly:set-option 'relative-includes #t)
\include "{{Lyp::LYP_LY_LIB_PATH}}"

#(begin
  (define lyp:cwd {{quote_path[FileUtils.pwd]}})
  (define lyp:input-filename {{quote_path[user_filename]}})
  (define lyp:input-dirname {{quote_path[user_dirname]}})
  (define lyp:current-package-dir {{quote_path[current_package_dir]}})
`

_[:package_refs].each do |spec, name|
`
  (hash-set! lyp:package-refs "{{spec}}" "{{name}}")`
end

_[:package_dirs].each do |package, path|
`
  (hash-set! lyp:package-dirs "{{package}}" {{quote_path[path]}})`
end

`
)

#(ly:debug "package loader is ready")
`

if _[:preload]
  _[:preload].each do |package|
`
\require "{{package}}"
`
  end
end

`
\include {{quote_path[user_filename]}}

#(lyp:call-finalizers)
`
