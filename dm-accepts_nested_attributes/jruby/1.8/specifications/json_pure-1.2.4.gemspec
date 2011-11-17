# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "json_pure"
  s.version = "1.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2010-04-07"
  s.description = "This is a JSON implementation in pure Ruby."
  s.email = "flori@ping.de"
  s.executables = ["edit_json.rb", "prettify_json.rb"]
  s.extra_rdoc_files = ["README"]
  s.files = ["bin/edit_json.rb", "bin/prettify_json.rb", "README"]
  s.homepage = "http://flori.github.com/json"
  s.rdoc_options = ["--title", "JSON -- A JSON implemention", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "json"
  s.rubygems_version = "1.8.11"
  s.summary = "A JSON implementation in Ruby"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
