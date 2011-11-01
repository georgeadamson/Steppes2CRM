# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "thor"
  s.version = "0.9.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz"]
  s.date = "2008-12-15"
  s.description = "A gem that maps options to a class"
  s.email = "wycats@gmail.com"
  s.executables = ["thor", "rake2thor"]
  s.extra_rdoc_files = ["README.markdown", "LICENSE", "CHANGELOG.rdoc"]
  s.files = ["bin/thor", "bin/rake2thor", "README.markdown", "LICENSE", "CHANGELOG.rdoc"]
  s.homepage = "http://yehudakatz.com"
  s.require_paths = ["lib"]
  s.rubyforge_project = "thor"
  s.rubygems_version = "1.8.11"
  s.summary = "A gem that maps options to a class"

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
