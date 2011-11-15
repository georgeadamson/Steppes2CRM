# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "jruby-win32ole"
  s.version = "0.8.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas E. Enebo"]
  s.date = "2011-08-21"
  s.description = "A Gem for win32ole support on JRuby"
  s.email = "tom.enebo@gmail.com"
  s.executables = ["make_data.rb", "sample"]
  s.files = ["bin/make_data.rb", "bin/sample"]
  s.homepage = "http://github.com/enebo/jruby-win32ole"
  s.require_paths = ["lib"]
  s.rubyforge_project = "jruby-win32ole"
  s.rubygems_version = "1.8.11"
  s.summary = "A Gem for win32ole support on JRuby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
