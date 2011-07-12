# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-serializer}
  s.version = "0.10.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Guy van den Berg"]
  s.date = %q{2009-12-11}
  s.description = %q{DataMapper plugin for serializing Resources and Collections}
  s.email = %q{vandenberg.guy [a] gmail [d] com}
  s.homepage = %q{http://github.com/datamapper/dm-more/tree/master/dm-serializer}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{datamapper}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataMapper plugin for serializing Resources and Collections}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, ["~> 0.10.2"])
      s.add_runtime_dependency(%q<fastercsv>, ["~> 1.5.0"])
      s.add_runtime_dependency(%q<json_pure>, ["~> 1.2.0"])
      s.add_development_dependency(%q<nokogiri>, ["~> 1.4.1"])
      s.add_development_dependency(%q<rspec>, ["~> 1.2.9"])
      s.add_development_dependency(%q<yard>, ["~> 0.4.0"])
    else
      s.add_dependency(%q<dm-core>, ["~> 0.10.2"])
      s.add_dependency(%q<fastercsv>, ["~> 1.5.0"])
      s.add_dependency(%q<json_pure>, ["~> 1.2.0"])
      s.add_dependency(%q<nokogiri>, ["~> 1.4.1"])
      s.add_dependency(%q<rspec>, ["~> 1.2.9"])
      s.add_dependency(%q<yard>, ["~> 0.4.0"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 0.10.2"])
    s.add_dependency(%q<fastercsv>, ["~> 1.5.0"])
    s.add_dependency(%q<json_pure>, ["~> 1.2.0"])
    s.add_dependency(%q<nokogiri>, ["~> 1.4.1"])
    s.add_dependency(%q<rspec>, ["~> 1.2.9"])
    s.add_dependency(%q<yard>, ["~> 0.4.0"])
  end
end
