- Add post about using custom fonts
- Add post about compiling with lyp

- Add `install_lilypond` / `il` command:

```ruby
  desc "install_lilypond VERSION", "Install a version of Lilypond."
  method_option :default, aliases: '-d', type: :boolean, desc: 'Set default Lilypond version'
  def install_lilypond
    $cmd_options = options

    Lyp::System.test_installed_status!
    args.each do |version|
      Lyp::Lilypond.install(version, options)
    end
  end
```

- Specs for CLI commands.

- Specs for lilypond command.

