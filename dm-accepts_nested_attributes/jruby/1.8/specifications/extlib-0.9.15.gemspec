# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "extlib"
  s.version = "0.9.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Kubb"]
  s.date = "2010-05-18"
  s.description = "Support library for DataMapper and Merb"
  s.email = "dan.kubb@gmail.com"
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
  s.files = ["LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/datamapper/extlib"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "extlib"
  s.rubygems_version = "1.8.11"
  s.summary = "Support library for DataMapper and Merb"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<json_pure>, ["~> 1.4"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3"])
    else
      s.add_dependency(%q<json_pure>, ["~> 1.4"])
      s.add_dependency(%q<rspec>, ["~> 1.3"])
    end
  else
    s.add_dependency(%q<json_pure>, ["~> 1.4"])
    s.add_dependency(%q<rspec>, ["~> 1.3"])
  end
end
