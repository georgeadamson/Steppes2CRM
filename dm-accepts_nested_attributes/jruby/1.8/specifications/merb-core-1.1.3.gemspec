# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb-core}
  s.version = "1.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ezra Zygmuntowicz"]
  s.date = %q{2010-07-11}
  s.default_executable = %q{merb}
  s.description = %q{Merb. Pocket rocket web framework.}
  s.email = %q{ez@engineyard.com}
  s.executables = ["merb"]
  s.files = ["bin/merb"]
  s.homepage = %q{http://merbivore.com/}
  s.post_install_message = %q{
(::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::)

                     (::)   U P G R A D I N G    (::)

Thank you for installing merb-core 1.1.3

The planned route for upgrading from merb 1.1.x to 1.2 will involve
changes which may break existing merb apps.  Fear not, fixes for
apps broken by 1.2 should be trivial. Please be sure to read
http://wiki.github.com/merb/merb/release-120 for the details
regarding usage of the upcoming 1.2 release.

(::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::)
}
  s.require_paths = ["lib"]
  s.requirements = ["Install the json gem to get faster json parsing."]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Merb plugin that provides caching (page, action, fragment, object)}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<extlib>, [">= 0.9.13"])
      s.add_runtime_dependency(%q<erubis>, [">= 2.6.2"])
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 1.16"])
      s.add_runtime_dependency(%q<bundler>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_development_dependency(%q<webrat>, [">= 0.3.1"])
    else
      s.add_dependency(%q<extlib>, [">= 0.9.13"])
      s.add_dependency(%q<erubis>, [">= 2.6.2"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<mime-types>, [">= 1.16"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
      s.add_dependency(%q<webrat>, [">= 0.3.1"])
    end
  else
    s.add_dependency(%q<extlib>, [">= 0.9.13"])
    s.add_dependency(%q<erubis>, [">= 2.6.2"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<mime-types>, [">= 1.16"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
    s.add_dependency(%q<webrat>, [">= 0.3.1"])
  end
end
