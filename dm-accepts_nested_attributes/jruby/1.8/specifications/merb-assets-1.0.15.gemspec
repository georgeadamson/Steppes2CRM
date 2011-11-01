# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "merb-assets"
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ezra Zygmuntowicz"]
  s.date = "2009-11-04"
  s.description = "Merb plugin that provides the helpers for assets and asset bundling"
  s.email = "ez@engineyard.com"
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["README", "LICENSE", "TODO"]
  s.homepage = "http://merbivore.com"
  s.require_paths = ["lib"]
  s.rubyforge_project = "merb"
  s.rubygems_version = "1.8.11"
  s.summary = "Merb plugin that provides the helpers for assets and asset bundling"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-core>, ["~> 1.0.15"])
    else
      s.add_dependency(%q<merb-core>, ["~> 1.0.15"])
    end
  else
    s.add_dependency(%q<merb-core>, ["~> 1.0.15"])
  end
end
