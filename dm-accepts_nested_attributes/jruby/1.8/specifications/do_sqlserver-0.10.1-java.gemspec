# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "do_sqlserver"
  s.version = "0.10.1"
  s.platform = "java"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alex Coles"]
  s.date = "2010-01-08"
  s.description = "Implements the DataObjects API for Microsoft SQL Server"
  s.email = "alex@alexcolesportfolio.com"
  s.extra_rdoc_files = ["README.markdown", "ChangeLog.markdown", "INSTALL.markdown", "FAQS.markdown", "LICENSE"]
  s.files = ["README.markdown", "ChangeLog.markdown", "INSTALL.markdown", "FAQS.markdown", "LICENSE"]
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "dorb"
  s.rubygems_version = "1.8.11"
  s.summary = "DataObjects SQL Server Driver"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<data_objects>, ["= 0.10.1"])
      s.add_runtime_dependency(%q<do_jdbc>, ["= 0.10.1"])
      s.add_runtime_dependency(%q<do-jdbc_sqlserver>, ["~> 1.2.4"])
      s.add_development_dependency(%q<bacon>, ["~> 1.1"])
      s.add_development_dependency(%q<rake-compiler>, ["~> 0.7"])
    else
      s.add_dependency(%q<data_objects>, ["= 0.10.1"])
      s.add_dependency(%q<do_jdbc>, ["= 0.10.1"])
      s.add_dependency(%q<do-jdbc_sqlserver>, ["~> 1.2.4"])
      s.add_dependency(%q<bacon>, ["~> 1.1"])
      s.add_dependency(%q<rake-compiler>, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<data_objects>, ["= 0.10.1"])
    s.add_dependency(%q<do_jdbc>, ["= 0.10.1"])
    s.add_dependency(%q<do-jdbc_sqlserver>, ["~> 1.2.4"])
    s.add_dependency(%q<bacon>, ["~> 1.1"])
    s.add_dependency(%q<rake-compiler>, ["~> 0.7"])
  end
end
