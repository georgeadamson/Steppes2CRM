require "spec"
require File.join(File.dirname(__FILE__), "..", "lib", "merb-core")

def startup_merb(opts = {})
  default_options = {
    :environment => 'test',
    :adapter => 'runner',
    :gemfile => File.join(File.dirname(__FILE__), "Gemfile"),
    :log_level => :error
  }
  options = default_options.merge(opts)
  Merb.start_environment(options)
end

# -- Global custom matchers --

# A better +be_kind_of+ with more informative error messages.
#
# The default +be_kind_of+ just says
#
#   "expected to return true but got false"
#
# This one says
#
#   "expected File but got Tempfile"

module Merb
  module Test
    module RspecMatchers
      class IncludeLog
        def initialize(expected)
          @expected = expected
        end
        
        def matches?(target)
          target.rewind
          @text = target.read
          @text =~ (String === @expected ? /#{Regexp.escape @expected}/ : @expected)
        end
        
        def failure_message
          "expected to find `#{@expected}' in the log but got:\n" <<
          @text.split("\n").map {|s| "  #{s}" }.join
        end
        
        def negative_failure_message
          "exected not to find `#{@expected}' in the log but got:\n" <<
          @text.split("\n").map {|s| "  #{s}" }.join
        end
        
        def description
          "include #{@text} in the log"
        end
      end
      
      class BeKindOf
        def initialize(expected) # + args
          @expected = expected
        end

        def matches?(target)
          @target = target
          @target.kind_of?(@expected)
        end

        def failure_message
          "expected #{@expected} but got #{@target.class}"
        end

        def negative_failure_message
          "expected #{@expected} to not be #{@target.class}"
        end

        def description
          "be_kind_of #{@target}"
        end
      end

      def be_kind_of(expected) # + args
        BeKindOf.new(expected)
      end
      
      def include_log(expected)
        IncludeLog.new(expected)
      end
    end

    module Helper
      def running(&blk) blk; end

      def executing(&blk) blk; end

      def doing(&blk) blk; end

      def calling(&blk) blk; end
    end
  end
end

# Helper to extract cookies from headers
#
# This is needed in some specs for sessions and cookies
module Merb::Test::CookiesHelper
  def extract_cookies(header)
    header['Set-Cookie'] ? header['Set-Cookie'].split(Merb::Const::NEWLINE) : []
  end
end

Spec::Runner.configure do |config|
  config.include Merb::Test::Helper
  config.include Merb::Test::RspecMatchers
  config.include ::Webrat::Matchers
  config.include ::Webrat::HaveTagMatcher
  config.include Merb::Test::RequestHelper
  config.include Merb::Test::RouteHelper
  config.include Merb::Test::WebratHelper

  def reset_dependency(name, const = nil)
    Object.send(:remove_const, const) if const && Object.const_defined?(const)
    Merb::BootLoader::Dependencies.dependencies.delete_if do |d|
      d.name == name
    end
    $LOADED_FEATURES.delete("#{name}.rb")
  end

  def with_level(level)
    Merb::Config[:log_stream] = StringIO.new
    Merb::Config[:log_level] = level
    Merb.reset_logger!
    yield
    Merb::Config[:log_stream]
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  alias silence capture
end
