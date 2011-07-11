# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-serializer}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Guy van den Berg"]
  s.date = %q{2011-03-16}
  s.description = %q{DataMapper plugin for serializing Resources and Collections}
  s.email = %q{vandenberg.guy [a] gmail [d] com}
  s.files = ["spec/fixtures/cow.rb", "spec/fixtures/planet.rb", "spec/fixtures/quan_tum_cat.rb", "spec/fixtures/vehicle.rb", "spec/lib/serialization_method_shared_spec.rb", "spec/public/serializer_spec.rb", "spec/public/to_csv_spec.rb", "spec/public/to_json_spec.rb", "spec/public/to_xml_spec.rb", "spec/public/to_yaml_spec.rb", "spec/spec_helper.rb"]
  s.homepage = %q{http://github.com/datamapper/dm-serializer}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{datamapper}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataMapper plugin for serializing Resources and Collections}
  s.test_files = ["spec/fixtures/cow.rb", "spec/fixtures/planet.rb", "spec/fixtures/quan_tum_cat.rb", "spec/fixtures/vehicle.rb", "spec/lib/serialization_method_shared_spec.rb", "spec/public/serializer_spec.rb", "spec/public/to_csv_spec.rb", "spec/public/to_json_spec.rb", "spec/public/to_xml_spec.rb", "spec/public/to_yaml_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, ["~> 1.1.0"])
      s.add_runtime_dependency(%q<fastercsv>, ["~> 1.5.4"])
      s.add_runtime_dependency(%q<json>, ["~> 1.4.6"])
      s.add_development_dependency(%q<dm-validations>, ["~> 1.1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3.1"])
    else
      s.add_dependency(%q<dm-core>, ["~> 1.1.0"])
      s.add_dependency(%q<fastercsv>, ["~> 1.5.4"])
      s.add_dependency(%q<json>, ["~> 1.4.6"])
      s.add_dependency(%q<dm-validations>, ["~> 1.1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_dependency(%q<rspec>, ["~> 1.3.1"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 1.1.0"])
    s.add_dependency(%q<fastercsv>, ["~> 1.5.4"])
    s.add_dependency(%q<json>, ["~> 1.4.6"])
    s.add_dependency(%q<dm-validations>, ["~> 1.1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rake>, ["~> 0.8.7"])
    s.add_dependency(%q<rspec>, ["~> 1.3.1"])
  end
end
