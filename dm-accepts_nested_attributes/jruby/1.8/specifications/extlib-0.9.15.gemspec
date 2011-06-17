# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{extlib}
  s.version = "0.9.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Kubb"]
  s.date = %q{2010-05-18}
  s.description = %q{Support library for DataMapper and Merb}
  s.email = %q{dan.kubb@gmail.com}
  s.files = ["spec/array_spec.rb", "spec/blank_spec.rb", "spec/byte_array_spec.rb", "spec/class_spec.rb", "spec/datetime_spec.rb", "spec/hash_spec.rb", "spec/hook_spec.rb", "spec/inflection/plural_spec.rb", "spec/inflection/singular_spec.rb", "spec/inflection_extras_spec.rb", "spec/lazy_array_spec.rb", "spec/lazy_module_spec.rb", "spec/mash_spec.rb", "spec/module_spec.rb", "spec/object_space_spec.rb", "spec/object_spec.rb", "spec/pooling_spec.rb", "spec/simple_set_spec.rb", "spec/spec_helper.rb", "spec/string_spec.rb", "spec/struct_spec.rb", "spec/symbol_spec.rb", "spec/time_spec.rb", "spec/try_call_spec.rb", "spec/try_dup_spec.rb", "spec/virtual_file_spec.rb"]
  s.homepage = %q{http://github.com/datamapper/extlib}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{extlib}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Support library for DataMapper and Merb}
  s.test_files = ["spec/array_spec.rb", "spec/blank_spec.rb", "spec/byte_array_spec.rb", "spec/class_spec.rb", "spec/datetime_spec.rb", "spec/hash_spec.rb", "spec/hook_spec.rb", "spec/inflection/plural_spec.rb", "spec/inflection/singular_spec.rb", "spec/inflection_extras_spec.rb", "spec/lazy_array_spec.rb", "spec/lazy_module_spec.rb", "spec/mash_spec.rb", "spec/module_spec.rb", "spec/object_space_spec.rb", "spec/object_spec.rb", "spec/pooling_spec.rb", "spec/simple_set_spec.rb", "spec/spec_helper.rb", "spec/string_spec.rb", "spec/struct_spec.rb", "spec/symbol_spec.rb", "spec/time_spec.rb", "spec/try_call_spec.rb", "spec/try_dup_spec.rb", "spec/virtual_file_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<json_pure>, ["~> 1.4"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3"])
    else
      s.add_dependency(%q<json_pure>, ["~> 1.4"])
      s.add_dependency(%q<rspec>, ["~> 1.3"])
    end
  else
    s.add_dependency(%q<json_pure>, ["~> 1.4"])
    s.add_dependency(%q<rspec>, ["~> 1.3"])
  end
end
