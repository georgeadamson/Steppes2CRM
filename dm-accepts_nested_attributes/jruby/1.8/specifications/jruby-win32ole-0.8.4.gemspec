# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{jruby-win32ole}
  s.version = "0.8.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Thomas E. Enebo"]
  s.date = %q{2011-07-06}
  s.description = %q{A Gem for win32ole support on JRuby}
  s.email = %q{tom.enebo@gmail.com}
  s.executables = ["make_data.rb", "sample"]
  s.files = ["bin/make_data.rb", "bin/sample"]
  s.homepage = %q{http://github.com/enebo/jruby-win32ole}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{jruby-win32ole}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{A Gem for win32ole support on JRuby}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
