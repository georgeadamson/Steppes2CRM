# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "merb-core"
  s.version = "1.0.15"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ezra Zygmuntowicz"]
  s.date = "2009-11-04"
  s.description = "Merb. Pocket rocket web framework."
  s.email = "ez@engineyard.com"
  s.executables = ["merb"]
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["bin/merb", "README", "LICENSE", "TODO"]
  s.homepage = "http://merbivore.com"
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.requirements = ["install the json gem to get faster json parsing"]
  s.rubygems_version = "1.8.11"
  s.summary = "Merb. Pocket rocket web framework."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<extlib>, [">= 0.9.8"])
      s.add_runtime_dependency(%q<erubis>, [">= 2.6.2"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<json_pure>, [">= 0"])
      s.add_runtime_dependency(%q<rspec>, [">= 0"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, ["~> 0.9.9"])
      s.add_development_dependency(%q<webrat>, [">= 0.3.1"])
    else
      s.add_dependency(%q<extlib>, [">= 0.9.8"])
      s.add_dependency(%q<erubis>, [">= 2.6.2"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<json_pure>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<mime-types>, [">= 0"])
      s.add_dependency(%q<thor>, ["~> 0.9.9"])
      s.add_dependency(%q<webrat>, [">= 0.3.1"])
    end
  else
    s.add_dependency(%q<extlib>, [">= 0.9.8"])
    s.add_dependency(%q<erubis>, [">= 2.6.2"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<json_pure>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<mime-types>, [">= 0"])
    s.add_dependency(%q<thor>, ["~> 0.9.9"])
    s.add_dependency(%q<webrat>, [">= 0.3.1"])
  end
end
