# DO NOT MODIFY THIS FILE
# Generated by Bundler 0.9.26

require 'digest/sha1'
require 'yaml'
require 'pathname'
require 'rubygems'
Gem.source_index # ensure Rubygems is fully loaded in Ruby 1.9

module Gem
  class Dependency
    if !instance_methods.map { |m| m.to_s }.include?("requirement")
      def requirement
        version_requirements
      end
    end
  end
end

module Bundler
  class Specification < Gem::Specification
    attr_accessor :relative_loaded_from

    def self.from_gemspec(gemspec)
      spec = allocate
      gemspec.instance_variables.each do |ivar|
        spec.instance_variable_set(ivar, gemspec.instance_variable_get(ivar))
      end
      spec
    end

    def loaded_from
      return super unless relative_loaded_from
      source.path.join(relative_loaded_from).to_s
    end

    def full_gem_path
      Pathname.new(loaded_from).dirname.expand_path.to_s
    end
  end

  module SharedHelpers
    attr_accessor :gem_loaded

    def default_gemfile
      gemfile = find_gemfile
      gemfile or raise GemfileNotFound, "Could not locate Gemfile"
      Pathname.new(gemfile)
    end

    def in_bundle?
      find_gemfile
    end

    def env_file
      default_gemfile.dirname.join(".bundle/environment.rb")
    end

  private

    def find_gemfile
      return ENV['BUNDLE_GEMFILE'] if ENV['BUNDLE_GEMFILE']

      previous = nil
      current  = File.expand_path(Dir.pwd)

      until !File.directory?(current) || current == previous
        filename = File.join(current, 'Gemfile')
        return filename if File.file?(filename)
        current, previous = File.expand_path("..", current), current
      end
    end

    def clean_load_path
      # handle 1.9 where system gems are always on the load path
      if defined?(::Gem)
        me = File.expand_path("../../", __FILE__)
        $LOAD_PATH.reject! do |p|
          next if File.expand_path(p).include?(me)
          p != File.dirname(__FILE__) &&
            Gem.path.any? { |gp| p.include?(gp) }
        end
        $LOAD_PATH.uniq!
      end
    end

    def reverse_rubygems_kernel_mixin
      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias rubygems_require require
          alias require gem_original_require
        end

        undef gem
      end
    end

    def cripple_rubygems(specs)
      reverse_rubygems_kernel_mixin

      executables = specs.map { |s| s.executables }.flatten
      Gem.source_index # ensure RubyGems is fully loaded

     ::Kernel.class_eval do
        private
        def gem(*) ; end
      end

      ::Kernel.send(:define_method, :gem) do |dep, *reqs|
        if executables.include? File.basename(caller.first.split(':').first)
          return
        end
        opts = reqs.last.is_a?(Hash) ? reqs.pop : {}

        unless dep.respond_to?(:name) && dep.respond_to?(:requirement)
          dep = Gem::Dependency.new(dep, reqs)
        end

        spec = specs.find  { |s| s.name == dep.name }

        if spec.nil?
          e = Gem::LoadError.new "#{dep.name} is not part of the bundle. Add it to Gemfile."
          e.name = dep.name
          e.version_requirement = dep.requirement
          raise e
        elsif dep !~ spec
          e = Gem::LoadError.new "can't activate #{dep}, already activated #{spec.full_name}. " \
                                 "Make sure all dependencies are added to Gemfile."
          e.name = dep.name
          e.version_requirement = dep.requirement
          raise e
        end

        true
      end

      # === Following hacks are to improve on the generated bin wrappers ===

      # Yeah, talk about a hack
      source_index_class = (class << Gem::SourceIndex ; self ; end)
      source_index_class.send(:define_method, :from_gems_in) do |*args|
        source_index = Gem::SourceIndex.new
        source_index.spec_dirs = *args
        source_index.add_specs(*specs)
        source_index
      end

      # OMG more hacks
      gem_class = (class << Gem ; self ; end)
      gem_class.send(:define_method, :bin_path) do |name, *args|
        exec_name, *reqs = args

        spec = nil

        if exec_name
          spec = specs.find { |s| s.executables.include?(exec_name) }
          spec or raise Gem::Exception, "can't find executable #{exec_name}"
        else
          spec = specs.find  { |s| s.name == name }
          exec_name = spec.default_executable or raise Gem::Exception, "no default executable for #{spec.full_name}"
        end

        gem_bin = File.join(spec.full_gem_path, spec.bindir, exec_name)
        gem_from_path_bin = File.join(File.dirname(spec.loaded_from), spec.bindir, exec_name)
        File.exist?(gem_bin) ? gem_bin : gem_from_path_bin
      end
    end

    extend self
  end
end

module Bundler
  ENV_LOADED   = true
  LOCKED_BY    = '0.9.26'
  FINGERPRINT  = "15a12f033e6436983b3e7d76dadfd964898b8bac"
  HOME         = 'C:/Users/george/.bundle/jruby/1.8/bundler'
  AUTOREQUIRES = {:default=>[["data_objects", false], ["dm-core", false], ["dm-aggregates", false], ["dm-migrations", false], ["dm-serializer", false], ["dm-timestamps", false], ["uuidtools", false], ["dm-types", false], ["dm-validations", false], ["do_sqlserver", false], ["merb-core", false], ["merb-action-args", false], ["merb-assets", false], ["merb-auth-core", false], ["merb-auth-more", false], ["merb-slices", false], ["merb-auth-slice-password", false], ["merb-cache", false], ["merb-exceptions", false], ["merb-helpers", false], ["merb-mailer", false], ["merb-param-protection", false], ["merb-parts", false], ["merb_datamapper", false], ["mongrel", false]]}
  SPECS        = [
        {:name=>"rake", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/rake-0.8.7/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/rake-0.8.7.gemspec"},
        {:name=>"ZenTest", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/ZenTest-4.2.1/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/ZenTest-4.2.1.gemspec"},
        {:name=>"RubyInline", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/RubyInline-3.8.4/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/RubyInline-3.8.4.gemspec"},
        {:name=>"sexp_processor", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/sexp_processor-3.0.3/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/sexp_processor-3.0.3.gemspec"},
        {:name=>"ParseTree", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/ParseTree-3.0.4/lib", "C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/ParseTree-3.0.4/test"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/ParseTree-3.0.4.gemspec"},
        {:name=>"abstract", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/abstract-1.0.0/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/abstract-1.0.0.gemspec"},
        {:name=>"addressable", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/addressable-2.1.1/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/addressable-2.1.1.gemspec"},
        {:name=>"data_objects", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/data_objects-0.10.1/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/data_objects-0.10.1.gemspec"},
        {:name=>"extlib", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/extlib-0.9.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/extlib-0.9.15.gemspec"},
        {:name=>"dm-core", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-core-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-core-0.10.2.gemspec"},
        {:name=>"dm-aggregates", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-aggregates-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-aggregates-0.10.2.gemspec"},
        {:name=>"dm-migrations", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-migrations-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-migrations-0.10.2.gemspec"},
        {:name=>"fastercsv", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/fastercsv-1.5.0/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/fastercsv-1.5.0.gemspec"},
        {:name=>"json_pure", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/json_pure-1.2.0/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/json_pure-1.2.0.gemspec"},
        {:name=>"dm-serializer", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-serializer-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-serializer-0.10.2.gemspec"},
        {:name=>"dm-timestamps", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-timestamps-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-timestamps-0.10.2.gemspec"},
        {:name=>"stringex", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/stringex-1.1.0/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/stringex-1.1.0.gemspec"},
        {:name=>"uuidtools", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/uuidtools-2.1.1/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/uuidtools-2.1.1.gemspec"},
        {:name=>"dm-types", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-types-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-types-0.10.2.gemspec"},
        {:name=>"dm-validations", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/dm-validations-0.10.2/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/dm-validations-0.10.2.gemspec"},
        {:name=>"do-jdbc_sqlserver", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/do-jdbc_sqlserver-1.2.4-java/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/do-jdbc_sqlserver-1.2.4-java.gemspec"},
        {:name=>"do_jdbc", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/do_jdbc-0.10.1-java/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/do_jdbc-0.10.1-java.gemspec"},
        {:name=>"do_sqlserver", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/do_sqlserver-0.10.1-java/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/do_sqlserver-0.10.1-java.gemspec"},
        {:name=>"erubis", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/erubis-2.6.5/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/erubis-2.6.5.gemspec"},
        {:name=>"gem_plugin", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/gem_plugin-0.2.3/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/gem_plugin-0.2.3.gemspec"},
        {:name=>"mime-types", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/mime-types-1.16/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/mime-types-1.16.gemspec"},
        {:name=>"mailfactory", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/mailfactory-1.4.0/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/mailfactory-1.4.0.gemspec"},
        {:name=>"rack", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/rack-1.0.1/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/rack-1.0.1.gemspec"},
        {:name=>"rspec", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/rspec-1.3.0/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/rspec-1.3.0.gemspec"},
        {:name=>"thor", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/thor-0.9.9/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/thor-0.9.9.gemspec"},
        {:name=>"merb-core", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-core-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-core-1.0.15.gemspec"},
        {:name=>"ruby_parser", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/ruby_parser-2.0.4/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/ruby_parser-2.0.4.gemspec"},
        {:name=>"ruby2ruby", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/ruby2ruby-1.2.4/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/ruby2ruby-1.2.4.gemspec"},
        {:name=>"merb-action-args", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-action-args-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-action-args-1.0.15.gemspec"},
        {:name=>"merb-assets", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-assets-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-assets-1.0.15.gemspec"},
        {:name=>"merb-auth-core", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-auth-core-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-auth-core-1.0.15.gemspec"},
        {:name=>"merb-auth-more", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-auth-more-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-auth-more-1.0.15.gemspec"},
        {:name=>"merb-slices", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-slices-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-slices-1.0.15.gemspec"},
        {:name=>"merb-auth-slice-password", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-auth-slice-password-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-auth-slice-password-1.0.15.gemspec"},
        {:name=>"merb-cache", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-cache-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-cache-1.0.15.gemspec"},
        {:name=>"merb-exceptions", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-exceptions-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-exceptions-1.0.15.gemspec"},
        {:name=>"merb-helpers", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-helpers-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-helpers-1.0.15.gemspec"},
        {:name=>"merb-mailer", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-mailer-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-mailer-1.0.15.gemspec"},
        {:name=>"merb-param-protection", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-param-protection-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-param-protection-1.0.15.gemspec"},
        {:name=>"merb-parts", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb-parts-0.9.8/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb-parts-0.9.8.gemspec"},
        {:name=>"merb_datamapper", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/merb_datamapper-1.0.15/lib"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/merb_datamapper-1.0.15.gemspec"},
        {:name=>"mongrel", :load_paths=>["C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/mongrel-1.1.5-java/lib", "C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/gems/mongrel-1.1.5-java/ext"], :loaded_from=>"C:/Program Files (x86)/jruby-1.4.0/lib/ruby/gems/1.8/specifications/mongrel-1.1.5-java.gemspec"},
      ].map do |hash|
    if hash[:virtual_spec]
      spec = eval(hash[:virtual_spec], TOPLEVEL_BINDING, "<virtual spec for '#{hash[:name]}'>")
    else
      dir = File.dirname(hash[:loaded_from])
      spec = Dir.chdir(dir){ eval(File.read(hash[:loaded_from]), TOPLEVEL_BINDING, hash[:loaded_from]) }
    end
    spec.loaded_from = hash[:loaded_from]
    spec.require_paths = hash[:load_paths]
    if spec.loaded_from.include?(HOME)
      Bundler::Specification.from_gemspec(spec)
    else
      spec
    end
  end

  extend SharedHelpers

  def self.configure_gem_path_and_home(specs)
    # Fix paths, so that Gem.source_index and such will work
    paths = specs.map{|s| s.installation_path }
    paths.flatten!; paths.compact!; paths.uniq!; paths.reject!{|p| p.empty? }
    ENV['GEM_PATH'] = paths.join(File::PATH_SEPARATOR)
    ENV['GEM_HOME'] = paths.first
    Gem.clear_paths
  end

  def self.match_fingerprint
    lockfile = File.expand_path('../../Gemfile.lock', __FILE__)
    lock_print = YAML.load(File.read(lockfile))["hash"] if File.exist?(lockfile)
    gem_print = Digest::SHA1.hexdigest(File.read(File.expand_path('../../Gemfile', __FILE__)))

    unless gem_print == lock_print
      abort 'Gemfile changed since you last locked. Please run `bundle lock` to relock.'
    end

    unless gem_print == FINGERPRINT
      abort 'Your bundled environment is out of date. Run `bundle install` to regenerate it.'
    end
  end

  def self.setup(*groups)
    match_fingerprint
    clean_load_path
    cripple_rubygems(SPECS)
    configure_gem_path_and_home(SPECS)
    SPECS.each do |spec|
      Gem.loaded_specs[spec.name] = spec
      spec.require_paths.each do |path|
        $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
      end
    end
    self
  end

  def self.require(*groups)
    groups = [:default] if groups.empty?
    groups.each do |group|
      (AUTOREQUIRES[group.to_sym] || []).each do |file, explicit|
        if explicit
          Kernel.require file
        else
          begin
            Kernel.require file
          rescue LoadError
          end
        end
      end
    end
  end

  # Set up load paths unless this file is being loaded after the Bundler gem
  setup unless defined?(Bundler::GEM_LOADED)
end
