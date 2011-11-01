# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "merb-exceptions"
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Andy Kent"]
  s.date = "2009-11-04"
  s.description = "Email and web hook exceptions for Merb."
  s.email = "andy@new-bamboo.co.uk"
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["README.markdown", "LICENSE"]
  s.homepage = "http://merbivore.com"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Email and web hook exceptions for Merb."

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
