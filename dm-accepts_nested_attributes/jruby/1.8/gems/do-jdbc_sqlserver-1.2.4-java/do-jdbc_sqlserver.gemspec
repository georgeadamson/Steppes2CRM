# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{do-jdbc_sqlserver}
  s.version = "1.2.4"
  s.platform = %q{java}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["alin_sinpalean", "bheineman", "ickzon"]
  s.date = %q{2010-01-11}
  s.description = %q{JDBC Driver for SQL Server (jTDS), packaged as a Gem}
  s.email = %q{}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "LGPL-LICENSE",
     "README.markdown",
     "Rakefile",
     "do-jdbc_sqlserver.gemspec",
     "lib/do_jdbc/sqlserver.rb",
     "lib/do_jdbc/sqlserver_version.rb",
     "lib/jtds-1.2.4.jar"
  ]
  s.homepage = %q{http://jtds.sourceforge.net/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dorb}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{SQL Server JDBC (jTDS) Driver}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

