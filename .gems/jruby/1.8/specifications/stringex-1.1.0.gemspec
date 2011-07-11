# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{stringex}
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Russell Norris"]
  s.date = %q{2009-10-12}
  s.description = %q{Some [hopefully] useful extensions to Ruby’s String class. Stringex is made up of three libraries: ActsAsUrl [permalink solution with better character translation], Unidecoder [Unicode to Ascii transliteration], and StringExtensions [miscellaneous helper methods for the String class].}
  s.email = %q{rsl@luckysneaks.com}
  s.files = ["test/acts_as_url_test.rb", "test/string_extensions_test.rb", "test/unidecoder_test.rb"]
  s.homepage = %q{http://github.com/rsl/stringex}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{stringex}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Some [hopefully] useful extensions to Ruby’s String class}
  s.test_files = ["test/acts_as_url_test.rb", "test/string_extensions_test.rb", "test/unidecoder_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
