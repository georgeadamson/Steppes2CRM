# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "merb-auth-core"
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam French, Daniel Neighman"]
  s.date = "2009-11-04"
  s.description = "An Authentication framework for Merb"
  s.email = "has.sox@gmail.com"
  s.extra_rdoc_files = ["README.textile", "LICENSE", "TODO"]
  s.files = ["README.textile", "LICENSE", "TODO"]
  s.homepage = "http://merbivore.com/"
  s.require_paths = ["lib"]
  s.rubyforge_project = "merb"
  s.rubygems_version = "1.8.11"
  s.summary = "An Authentication framework for Merb"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-core>, ["~> 1.0.15"])
      s.add_runtime_dependency(%q<extlib>, [">= 0"])
    else
      s.add_dependency(%q<merb-core>, ["~> 1.0.15"])
      s.add_dependency(%q<extlib>, [">= 0"])
    end
  else
    s.add_dependency(%q<merb-core>, ["~> 1.0.15"])
    s.add_dependency(%q<extlib>, [">= 0"])
  end
end
