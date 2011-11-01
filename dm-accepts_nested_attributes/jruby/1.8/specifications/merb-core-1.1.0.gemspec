# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "merb-core"
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ezra Zygmuntowicz"]
  s.date = "2010-03-22"
  s.description = "Merb. Pocket rocket web framework."
  s.email = "ez@engineyard.com"
  s.executables = ["merb"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README", "TODO"]
  s.files = ["bin/merb", "CHANGELOG", "LICENSE", "README", "TODO"]
  s.homepage = "http://merbivore.com/"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Merb plugin that provides caching (page, action, fragment, object)"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bundler>, [">= 0.9.3"])
      s.add_runtime_dependency(%q<extlib>, [">= 0.9.13"])
      s.add_runtime_dependency(%q<erubis>, [">= 2.6.2"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 1.16"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<webrat>, [">= 0.3.1"])
    else
      s.add_dependency(%q<bundler>, [">= 0.9.3"])
      s.add_dependency(%q<extlib>, [">= 0.9.13"])
      s.add_dependency(%q<erubis>, [">= 2.6.2"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<mime-types>, [">= 1.16"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<webrat>, [">= 0.3.1"])
    end
  else
    s.add_dependency(%q<bundler>, [">= 0.9.3"])
    s.add_dependency(%q<extlib>, [">= 0.9.13"])
    s.add_dependency(%q<erubis>, [">= 2.6.2"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<mime-types>, [">= 1.16"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<webrat>, [">= 0.3.1"])
  end
end
