# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{do-jdbc_sqlserver}
  s.version = "1.2.4"
  s.platform = %q{java}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["alin_sinpalean", "bheineman", "ickzon"]
  s.date = %q{2010-01-10}
  s.description = %q{JDBC Driver for SQL Server (jTDS), packaged as a Gem}
  s.email = %q{}
  s.homepage = %q{http://jtds.sourceforge.net/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dorb}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{SQL Server JDBC (jTDS) Driver}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
