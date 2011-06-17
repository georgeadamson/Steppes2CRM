# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb-assets}
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ezra Zygmuntowicz"]
  s.date = %q{2010-07-11}
  s.description = %q{Merb plugin for supporting assets}
  s.email = %q{ez@engineyard.com}
  s.homepage = %q{http://merbivore.com/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Merb plugin that provides helpers for assets and asset bundling}

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
