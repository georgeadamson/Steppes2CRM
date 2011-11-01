# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "stringex"
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Russell Norris"]
  s.date = "2009-10-12"
  s.description = "Some [hopefully] useful extensions to Ruby\342\200\231s String class. Stringex is made up of three libraries: ActsAsUrl [permalink solution with better character translation], Unidecoder [Unicode to Ascii transliteration], and StringExtensions [miscellaneous helper methods for the String class]."
  s.email = "rsl@luckysneaks.com"
  s.extra_rdoc_files = ["MIT-LICENSE", "README.rdoc"]
  s.files = ["MIT-LICENSE", "README.rdoc"]
  s.homepage = "http://github.com/rsl/stringex"
  s.rdoc_options = ["--main", "README.rdoc", "--charset", "utf-8", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "stringex"
  s.rubygems_version = "1.8.11"
  s.summary = "Some [hopefully] useful extensions to Ruby\342\200\231s String class"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
