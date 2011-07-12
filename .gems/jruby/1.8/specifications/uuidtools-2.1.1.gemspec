# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{uuidtools}
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bob Aman"]
  s.date = %q{2009-10-13}
  s.description = %q{A simple universally unique ID generation library.
}
  s.email = %q{bob@sporkmonger.com}
  s.homepage = %q{http://uuidtools.rubyforge.org/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{uuidtools}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{UUID generator}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.8.3"])
      s.add_development_dependency(%q<rspec>, [">= 1.1.11"])
      s.add_development_dependency(%q<launchy>, [">= 0.3.2"])
    else
      s.add_dependency(%q<rake>, [">= 0.8.3"])
      s.add_dependency(%q<rspec>, [">= 1.1.11"])
      s.add_dependency(%q<launchy>, [">= 0.3.2"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.8.3"])
    s.add_dependency(%q<rspec>, [">= 1.1.11"])
    s.add_dependency(%q<launchy>, [">= 0.3.2"])
  end
end
