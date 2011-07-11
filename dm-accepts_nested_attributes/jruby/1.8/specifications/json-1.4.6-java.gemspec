# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{json}
  s.version = "1.4.6"
  s.platform = %q{java}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Luz"]
  s.date = %q{2010-08-12}
  s.description = %q{A JSON implementation as a JRuby extension.}
  s.email = %q{dev+ruby@mernen.com}
  s.homepage = %q{http://json-jruby.rubyforge.org/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{json-jruby}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{JSON implementation for JRuby}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
