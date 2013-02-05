require "rubygems"

# Use current merb-core sources if running from a typical dev checkout.
lib = File.expand_path('../../../../merb/merb-core/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-core'

# Use current merb-slices sources if running from a typical dev checkout.
lib = File.expand_path('../../../../merb/merb-slices/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-slices'

# Use current merb-auth-core sources if running from a typical dev checkout.
lib = File.expand_path('../../../merb-auth-core/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-auth-core'

# Use current merb-auth-more sources if running from a typical dev checkout.
lib = File.expand_path('../../../merb-auth-more/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-auth-more'

# Satisfies Autotest and anyone else not using the Rake tasks
require 'spec'


# Add mauth_password_slice.rb to the search path
Merb::Plugins.config[:merb_slices][:auto_register] = true
Merb::Plugins.config[:merb_slices][:search_path]   = File.join(File.dirname(__FILE__), '..', 'lib', 'merb-auth-slice-password.rb')

# Using Merb.root below makes sure that the correct root is set for
# - testing standalone, without being installed as a gem and no host application
# - testing from within the host application; its root will be used
Merb.start_environment(
  :testing => true,
  :adapter => 'runner',
  :environment => ENV['MERB_ENV'] || 'test',
  :merb_root => Merb.root,
  :session_store => 'memory'
)

module Merb
  module Test
    module SliceHelper

      # The absolute path to the current slice
      def current_slice_root
        @current_slice_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
      end

      # Whether the specs are being run from a host application or standalone
      def standalone?
        Merb.root == ::MerbAuthSlicePassword.root
      end

    end
  end
end

Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
  config.include(Merb::Test::SliceHelper)
end