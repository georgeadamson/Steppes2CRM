# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_datamapper}
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jason Toy", "Jonathan Stott"]
  s.date = %q{2011-05-03 00:00:00.000000000Z}
  s.description = %q{Merb plugin that provides support for datamapper}
  s.email = %q{jonathan.stott@gmail.com}
  s.homepage = %q{http://github.com/merb/merb_datamapper}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Merb plugin that allows you to use datamapper with your merb app}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-core>, ["~> 1.1"])
      s.add_runtime_dependency(%q<dm-core>, [">= 1.0"])
      s.add_runtime_dependency(%q<dm-migrations>, [">= 1.0"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<merb-core>, ["~> 1.1"])
      s.add_dependency(%q<dm-core>, [">= 1.0"])
      s.add_dependency(%q<dm-migrations>, [">= 1.0"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<merb-core>, ["~> 1.1"])
    s.add_dependency(%q<dm-core>, [">= 1.0"])
    s.add_dependency(%q<dm-migrations>, [">= 1.0"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end
