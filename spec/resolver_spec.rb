require File.expand_path('spec_helper', File.dirname(__FILE__))

RSpec.describe Lyp::DependencyResolver do
  def dep(*args)
    Lyp::DependencyLeaf.new(*args)
  end

  def tree(*args)
    Lyp::DependencyLeaf.new(*args)
  end

  def spec(*args)
    Lyp::DependencySpec.new(*args)
  end

  def package(*args)
    Lyp::DependencyPackage.new(*args)
  end

  def resolver(tree = Lyp::DependencyLeaf.new, opts = {})
    Lyp::DependencyResolver.new(tree, opts)
  end

  it "returns an empty dependency array for an empty tree" do
    deps = tree().resolve
    expect(deps).to eq([])
  end

  it "correctly resolves versions for a dependency tree" do
    t = tree(
      a: spec('a@>=0.1',
        :'a@0.1' => dep(
          b: spec('b@>=0.2.0',
            :'b@0.2' => dep,
            :'b@0.3' => dep
          )
        ),
        :'a@0.2' => dep(
          b: spec('b@~>0.3.0',
            :'b@0.3' => dep
          )
        )
      ),
      c: spec('c@~>0.1.0',
        :'c@0.1' => dep(
          b: spec('b@~>0.2.0',
            :'b@0.2' => dep
          )
        )
      )
    )
    deps = t.resolve
    expect(deps).to eq(['a@0.1', 'b@0.2', 'c@0.1'])
  end

  it "correctly selects higher versions from multiple options" do
    select = lambda do |o|
      r = resolver(tree())
      r.select_highest_versioned_permutation(o, [])
    end

    opts = [
      ['a@0.1'], ['a@0.1.1']
    ]
    expect(select[opts]).to eq(['a@0.1.1'])

    opts = [
      ['a@0.1'], ['a']
    ]
    expect(select[opts]).to eq(['a@0.1'])

    opts = [
      ['a@0.1', 'c@0.2'], ['a@0.2', 'c@0.1']
    ]
    # In this case the result can be considered arbitrary, it depends on the
    # order of permutations in the input array
    expect(select[opts]).to eq(['a@0.2', 'c@0.1'])

    opts = [
      ['a@0.1', 'b@0.2', 'c@0.1'], ['a@0.1', 'b@0.2.3', 'c@0.1']
    ]
    expect(select[opts]).to eq(['a@0.1', 'b@0.2.3', 'c@0.1'])
  end

  it "lists all available packages" do
    with_packages(:simple) do
      o = resolver.available_packages
      expect(o.keys.sort).to eq(%w{a@0.1 a@0.2 b@0.1 b@0.2 b@0.2.2 c@0.1 c@0.3})
    end
  end

  it "lists available packages matching a package reference" do
    with_packages(:simple) do
      r = resolver
      o = r.find_matching_packages('b')
      expect(o.keys.sort).to eq(%w{b@0.1 b@0.2 b@0.2.2})

      o = r.find_matching_packages('a@0.1')
      expect(o.keys).to eq(%w{a@0.1})

      o = r.find_matching_packages('a@>=0.1')
      expect(o.keys.sort).to eq(%w{a@0.1 a@0.2})

      o = r.find_matching_packages('b@~>0.1.0')
      expect(o.keys).to eq(%w{b@0.1})

      o = r.find_matching_packages('b@~>0.2.0')
      expect(o.keys.sort).to eq(%w{b@0.2 b@0.2.2})

      o = r.find_matching_packages('c@~>0.1.0')
      expect(o.keys).to eq(%w{c@0.1})

      o = r.find_matching_packages('c@>=0.2')
      expect(o.keys).to eq(%w{c@0.3})
    end
  end

  it "returns a prepared hash of dependencies for a package reference" do
    with_packages(:simple) do
      o = dep()
      r = resolver
      r.find_package_versions('b@>=0.2', o)

      expect(o.dependencies['b'].clause).to eq('b@>=0.2')
      expect(o.dependencies['b'].versions['b@0.2'].path).to eq("#{$packages_dir}/b@0.2/package.ly")
      expect(o.dependencies['b'].versions['b@0.2.2'].path).to eq("#{$packages_dir}/b@0.2.2/package.ly")
    end
  end

  it "processes a user's file and resolves all its dependencies" do
    with_packages(:simple) do
      resolver = resolver('spec/user_files/simple.ly')
      o = resolver.compile_dependency_tree
      expect(o.dependencies.keys).to eq(%w{a c})

      expect(o.dependencies['a'].versions.keys).to eq(%w{a@0.1 a@0.2})
      expect(o.dependencies['c'].versions.keys).to eq(%w{c@0.1})

      expect(o.dependencies['a'].versions['a@0.1'].dependencies.keys).to eq(%w{b})

      expect(o.dependencies['a'].versions['a@0.1'].dependencies['b'].versions.keys.sort).to eq(%w{b@0.1 b@0.2 b@0.2.2})

      r = resolver.resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.1 c@0.1})
      expect(r[:package_refs]).to eq({
        "a" => "a",
        "b@>=0.1.0" => "b",
        "b@~>0.2.0" => "b",
        "b~>0.1.0" => "b",
        "c" => "c"
      })

      expect(r[:package_dirs]["a"]).to eq(
        "#{$packages_dir}/a@0.1"
      )
      expect(r[:package_dirs]["b"]).to eq(
        "#{$packages_dir}/b@0.1"
      )
      expect(r[:package_dirs]["c"]).to eq(
        "#{$packages_dir}/c@0.1"
      )
    end
  end

  it "correctly resolves a circular dependency" do
    with_packages(:circular) do
      r = resolver('spec/user_files/circular.ly').resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.2 c@0.3})
    end
  end

  it "correctly resolves a transitive dependency" do
    with_packages(:transitive) do
      r = resolver('spec/user_files/circular.ly').resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.2 c@0.3})
    end
  end

  it "correctly resolves dependencies with include files" do
    with_packages(:includes) do
      r = resolver('spec/user_files/circular.ly').resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.2 c@0.3 d@0.4})
    end
  end

  it "returns no dependencies for file with no requires" do
    with_packages(:simple) do
      r = resolver('spec/user_files/no_require.ly').resolve_package_dependencies
      expect(r[:definite_versions]).to eq([])
    end
  end

  it "raises error on an unavailable dependency" do
    with_packages(:simple) do
      r = resolver('spec/user_files/not_found.ly')

      expect {r.resolve_package_dependencies}.to raise_error
    end
  end

  it "raises error on an invalid circular dependency" do
    with_packages(:circular_invalid) do
      r = resolver('spec/user_files/circular.ly')
      # here it should not raise, since a@0.2 satisfies the dependency
      # requirements
      expect(r.resolve_package_dependencies[:definite_versions]).to eq(
        ["a@0.2", "b@0.2", "c@0.3"]
      )

      # When the user specifies a@0.1, we should raise!
      r = resolver('spec/user_files/circular_invalid.ly')
      expect {r.resolve_package_dependencies}.to raise_error
    end
  end

  it "handles requires in include files" do
    with_packages(:simple) do
      r = resolver('spec/user_files/include1.ly').resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.1 b@0.1 c@0.1})
    end
  end

  it "handles external requires (supplied on command line using -r/--require)" do
    with_packages(:simple) do
      r = resolver('spec/user_files/no_require.ly',ext_require: ['a']).
        resolve_package_dependencies
      expect(r[:definite_versions]).to eq(%w{a@0.2 b@0.2.2})
      expect(r[:preload]).to eq(['a'])
    end
  end

  it "handles a big package setup" do
    with_packages(:big) do
      r = resolver('spec/user_files/simple.ly').resolve_package_dependencies
      expect(r[:definite_versions].sort).to eq(
        %w{a@0.3.2 b@0.3.2 c@0.3.2 d@0.3.2 e@0.3.2 f@0.2.1 g@0.3.2 h@0.3.2 i@0.3.2 j@0.3.2}
      )
    end
  end

  it "raises error for missing file" do
    with_packages(:big) do
      r = resolver('spec/user_files/does_not_exist.ly')

      expect do
        r.resolve_package_dependencies
      end.to raise_error
    end
  end

  it "respects forced package paths" do
    with_packages(:simple) do
      b_path = "#{$spec_dir}/user_files/fake_b"

      r = resolver('spec/user_files/include1.ly', {
        forced_package_paths: {
          'b' => b_path
        }
      }).resolve_package_dependencies

      expect(r[:definite_versions]).to eq(%w{a@0.2 b@forced c@0.3})
      expect(r[:package_dirs]['b']).to eq(b_path)
    end
  end

  it "handles non-numeric versions" do
    with_packages(:tagged) do
      r = resolver('spec/user_files/b_abc.ly').resolve_package_dependencies

      expect(r[:definite_versions]).to eq(%w{b@abc})
      expect(r[:package_refs]).to eq({"b@abc" => "b"})
      expect(r[:package_dirs]['b']).to eq(
        "#{$packages_dir}/b@abc"
      )

      r = resolver('spec/user_files/b.ly').resolve_package_dependencies

      expect(r[:definite_versions]).to eq(%w{b@def c@0.3.0})
      expect(r[:package_refs]).to eq({"b" => "b", "c" => "c"})
      expect(r[:package_dirs]['b']).to eq(
        "#{$packages_dir}/b@def"
      )

      r = resolver('spec/user_files/b_def.ly').resolve_package_dependencies

      expect(r[:definite_versions]).to eq(%w{b@def c@0.3.0})
      expect(r[:package_refs]).to eq({"b@def" => "b", "c" => "c"})
      expect(r[:package_dirs]['b']).to eq(
        "#{$packages_dir}/b@def"
      )
    end
  end

  it "supports forcing a package path using from require command" do
    with_packages(:testing) do
      r = resolver("#{$packages_dir}/b/test/require.ly").resolve_package_dependencies

      expect(r[:definite_versions]).to eq(%w{b@forced})
      expect(r[:package_refs]).to eq({"b" => "b"})
      expect(r[:package_dirs]['b']).to eq(
        "#{$packages_dir}/b"
      )
    end
  end
end
