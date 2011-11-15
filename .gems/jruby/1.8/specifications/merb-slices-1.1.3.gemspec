# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb-slices}
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fabien Franzen"]
  s.date = %q{2010-07-11}
  s.default_executable = %q{slice}
  s.description = %q{Merb plugin that supports reusable application 'slices'.}
  s.email = %q{info@fabien.be}
  s.executables = ["slice"]
  s.files = ["bin/slice"]
  s.homepage = %q{http://merbivore.com/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Merb plugin for using and creating application 'slices' which help you modularize your application.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-core>, ["~> 1.1.3"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<merb-core>, ["~> 1.1.3"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<merb-core>, ["~> 1.1.3"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end
