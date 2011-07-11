# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-types}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Kubb"]
  s.date = %q{2011-03-16}
  s.description = %q{DataMapper plugin providing extra data types}
  s.email = %q{dan.kubb [a] gmail [d] com}
  s.files = ["spec/fixtures/article.rb", "spec/fixtures/bookmark.rb", "spec/fixtures/invention.rb", "spec/fixtures/network_node.rb", "spec/fixtures/person.rb", "spec/fixtures/software_package.rb", "spec/fixtures/ticket.rb", "spec/fixtures/tshirt.rb", "spec/integration/bcrypt_hash_spec.rb", "spec/integration/comma_separated_list_spec.rb", "spec/integration/enum_spec.rb", "spec/integration/file_path_spec.rb", "spec/integration/flag_spec.rb", "spec/integration/ip_address_spec.rb", "spec/integration/json_spec.rb", "spec/integration/slug_spec.rb", "spec/integration/uri_spec.rb", "spec/integration/uuid_spec.rb", "spec/integration/yaml_spec.rb", "spec/shared/flags_shared_spec.rb", "spec/shared/identity_function_group.rb", "spec/spec_helper.rb", "spec/unit/bcrypt_hash_spec.rb", "spec/unit/csv_spec.rb", "spec/unit/enum_spec.rb", "spec/unit/epoch_time_spec.rb", "spec/unit/file_path_spec.rb", "spec/unit/flag_spec.rb", "spec/unit/ip_address_spec.rb", "spec/unit/json_spec.rb", "spec/unit/paranoid_boolean_spec.rb", "spec/unit/paranoid_datetime_spec.rb", "spec/unit/regexp_spec.rb", "spec/unit/uri_spec.rb", "spec/unit/uuid_spec.rb", "spec/unit/yaml_spec.rb"]
  s.homepage = %q{http://github.com/datamapper/dm-types}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{datamapper}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataMapper plugin providing extra data types}
  s.test_files = ["spec/fixtures/article.rb", "spec/fixtures/bookmark.rb", "spec/fixtures/invention.rb", "spec/fixtures/network_node.rb", "spec/fixtures/person.rb", "spec/fixtures/software_package.rb", "spec/fixtures/ticket.rb", "spec/fixtures/tshirt.rb", "spec/integration/bcrypt_hash_spec.rb", "spec/integration/comma_separated_list_spec.rb", "spec/integration/enum_spec.rb", "spec/integration/file_path_spec.rb", "spec/integration/flag_spec.rb", "spec/integration/ip_address_spec.rb", "spec/integration/json_spec.rb", "spec/integration/slug_spec.rb", "spec/integration/uri_spec.rb", "spec/integration/uuid_spec.rb", "spec/integration/yaml_spec.rb", "spec/shared/flags_shared_spec.rb", "spec/shared/identity_function_group.rb", "spec/spec_helper.rb", "spec/unit/bcrypt_hash_spec.rb", "spec/unit/csv_spec.rb", "spec/unit/enum_spec.rb", "spec/unit/epoch_time_spec.rb", "spec/unit/file_path_spec.rb", "spec/unit/flag_spec.rb", "spec/unit/ip_address_spec.rb", "spec/unit/json_spec.rb", "spec/unit/paranoid_boolean_spec.rb", "spec/unit/paranoid_datetime_spec.rb", "spec/unit/regexp_spec.rb", "spec/unit/uri_spec.rb", "spec/unit/uuid_spec.rb", "spec/unit/yaml_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bcrypt-ruby>, ["~> 2.1.4"])
      s.add_runtime_dependency(%q<dm-core>, ["~> 1.1.0"])
      s.add_runtime_dependency(%q<fastercsv>, ["~> 1.5.4"])
      s.add_runtime_dependency(%q<json>, ["~> 1.4.6"])
      s.add_runtime_dependency(%q<stringex>, ["~> 1.2.0"])
      s.add_runtime_dependency(%q<uuidtools>, ["~> 2.1.2"])
      s.add_development_dependency(%q<dm-validations>, ["~> 1.1.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3.1"])
    else
      s.add_dependency(%q<bcrypt-ruby>, ["~> 2.1.4"])
      s.add_dependency(%q<dm-core>, ["~> 1.1.0"])
      s.add_dependency(%q<fastercsv>, ["~> 1.5.4"])
      s.add_dependency(%q<json>, ["~> 1.4.6"])
      s.add_dependency(%q<stringex>, ["~> 1.2.0"])
      s.add_dependency(%q<uuidtools>, ["~> 2.1.2"])
      s.add_dependency(%q<dm-validations>, ["~> 1.1.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_dependency(%q<rspec>, ["~> 1.3.1"])
    end
  else
    s.add_dependency(%q<bcrypt-ruby>, ["~> 2.1.4"])
    s.add_dependency(%q<dm-core>, ["~> 1.1.0"])
    s.add_dependency(%q<fastercsv>, ["~> 1.5.4"])
    s.add_dependency(%q<json>, ["~> 1.4.6"])
    s.add_dependency(%q<stringex>, ["~> 1.2.0"])
    s.add_dependency(%q<uuidtools>, ["~> 2.1.2"])
    s.add_dependency(%q<dm-validations>, ["~> 1.1.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rake>, ["~> 0.8.7"])
    s.add_dependency(%q<rspec>, ["~> 1.3.1"])
  end
end
