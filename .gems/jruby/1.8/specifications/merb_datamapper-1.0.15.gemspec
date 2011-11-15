# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_datamapper}
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jason Toy"]
  s.date = %q{2009-11-04}
  s.description = %q{DataMapper plugin providing DataMapper support for Merb}
  s.email = %q{jtoy@rubynow.com}
  s.homepage = %q{http://merbivore.com}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataMapper plugin providing DataMapper support for Merb}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, ["~> 0.10"])
      s.add_runtime_dependency(%q<dm-migrations>, ["~> 0.10"])
      s.add_runtime_dependency(%q<merb-core>, ["~> 1.0.15"])
    else
      s.add_dependency(%q<dm-core>, ["~> 0.10"])
      s.add_dependency(%q<dm-migrations>, ["~> 0.10"])
      s.add_dependency(%q<merb-core>, ["~> 1.0.15"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 0.10"])
    s.add_dependency(%q<dm-migrations>, ["~> 0.10"])
    s.add_dependency(%q<merb-core>, ["~> 1.0.15"])
  end
end
