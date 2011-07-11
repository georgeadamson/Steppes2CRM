# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{data_objects}
  s.version = "0.10.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dirkjan Bussink"]
  s.date = %q{2010-01-08}
  s.description = %q{Provide a standard and simplified API for communicating with RDBMS from Ruby}
  s.email = %q{d.bussink@gmail.com}
  s.files = ["spec/command_spec.rb", "spec/connection_spec.rb", "spec/do_mock.rb", "spec/do_mock2.rb", "spec/pooling_spec.rb", "spec/reader_spec.rb", "spec/result_spec.rb", "spec/spec_helper.rb", "spec/transaction_spec.rb", "spec/uri_spec.rb"]
  s.homepage = %q{http://github.com/datamapper/do}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dorb}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataObjects basic API and shared driver specifications}
  s.test_files = ["spec/command_spec.rb", "spec/connection_spec.rb", "spec/do_mock.rb", "spec/do_mock2.rb", "spec/pooling_spec.rb", "spec/reader_spec.rb", "spec/result_spec.rb", "spec/spec_helper.rb", "spec/transaction_spec.rb", "spec/uri_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, ["~> 2.1"])
      s.add_development_dependency(%q<bacon>, ["~> 1.1"])
      s.add_development_dependency(%q<mocha>, ["~> 0.9"])
      s.add_development_dependency(%q<yard>, ["~> 0.5"])
    else
      s.add_dependency(%q<addressable>, ["~> 2.1"])
      s.add_dependency(%q<bacon>, ["~> 1.1"])
      s.add_dependency(%q<mocha>, ["~> 0.9"])
      s.add_dependency(%q<yard>, ["~> 0.5"])
    end
  else
    s.add_dependency(%q<addressable>, ["~> 2.1"])
    s.add_dependency(%q<bacon>, ["~> 1.1"])
    s.add_dependency(%q<mocha>, ["~> 0.9"])
    s.add_dependency(%q<yard>, ["~> 0.5"])
  end
end
