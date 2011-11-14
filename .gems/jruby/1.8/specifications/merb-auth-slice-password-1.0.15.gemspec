# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb-auth-slice-password}
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Neighman"]
  s.date = %q{2009-11-04}
  s.description = %q{Merb Slice that provides UI for password strategy of merb-auth.}
  s.email = %q{has.sox@gmail.com}
  s.homepage = %q{http://merbivore.com/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Merb Slice that provides UI for password strategy of merb-auth.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-slices>, [">= 1.0.15"])
      s.add_runtime_dependency(%q<merb-auth-core>, [">= 1.0.15"])
      s.add_runtime_dependency(%q<merb-auth-more>, [">= 1.0.15"])
    else
      s.add_dependency(%q<merb-slices>, [">= 1.0.15"])
      s.add_dependency(%q<merb-auth-core>, [">= 1.0.15"])
      s.add_dependency(%q<merb-auth-more>, [">= 1.0.15"])
    end
  else
    s.add_dependency(%q<merb-slices>, [">= 1.0.15"])
    s.add_dependency(%q<merb-auth-core>, [">= 1.0.15"])
    s.add_dependency(%q<merb-auth-more>, [">= 1.0.15"])
  end
end