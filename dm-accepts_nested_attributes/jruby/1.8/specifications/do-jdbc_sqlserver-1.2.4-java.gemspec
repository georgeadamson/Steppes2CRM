# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "do-jdbc_sqlserver"
  s.version = "1.2.4"
  s.platform = "java"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["alin_sinpalean", "bheineman", "ickzon"]
  s.date = "2010-01-10"
  s.description = "JDBC Driver for SQL Server (jTDS), packaged as a Gem"
  s.email = ""
  s.extra_rdoc_files = ["README.markdown"]
  s.files = ["README.markdown"]
  s.homepage = "http://jtds.sourceforge.net/"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "dorb"
  s.rubygems_version = "1.8.11"
  s.summary = "SQL Server JDBC (jTDS) Driver"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
