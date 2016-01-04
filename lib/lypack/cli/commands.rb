command :list do |c|
  c.syntax =      "list [PATTERN]"
  c.description = "Lists installed versions of packages whose name matches PATTERN"
  c.action do |args, opts|
    Lypack::Package.list(args.first).each {|p| puts p}
  end
end

command :compile do |c|
  c.syntax = "compile <FILE>"
  c.description = "Resolves package dependencies and invokes lilypond"
  c.option '-c', '--config FILE', 'Set config file'
  c.action do |args, opts|
    raise "File not specified" if args.empty?

    Lypack::Lilypond.compile(ARGV[1..-1])
  end
end
