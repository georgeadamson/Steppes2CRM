# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-sqlserver-adapter}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Clifford Heath"]
  s.date = %q{2011-03-16}
  s.description = %q{Microsoft SQL Server Adapter for DataMapper}
  s.email = %q{dan.kubb@gmail.com}
  s.files = ["spec/adapter_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/datamapper/dm-sqlserver-adapter}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{datamapper}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Microsoft SQL Server Adapter for DataMapper}
  s.test_files = ["spec/adapter_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<do_sqlserver>, ["~> 0.10.2"])
      s.add_runtime_dependency(%q<dm-do-adapter>, ["~> 1.1.0"])
      s.add_development_dependency(%q<dm-migrations>, ["~> 1.1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3.1"])
    else
      s.add_dependency(%q<do_sqlserver>, ["~> 0.10.2"])
      s.add_dependency(%q<dm-do-adapter>, ["~> 1.1.0"])
      s.add_dependency(%q<dm-migrations>, ["~> 1.1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_dependency(%q<rspec>, ["~> 1.3.1"])
    end
  else
    s.add_dependency(%q<do_sqlserver>, ["~> 0.10.2"])
    s.add_dependency(%q<dm-do-adapter>, ["~> 1.1.0"])
    s.add_dependency(%q<dm-migrations>, ["~> 1.1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rake>, ["~> 0.8.7"])
    s.add_dependency(%q<rspec>, ["~> 1.3.1"])
  end
end