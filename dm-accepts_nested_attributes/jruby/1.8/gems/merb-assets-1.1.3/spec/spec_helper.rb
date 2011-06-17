require "rubygems"
require "json"

# Use current merb-core sources if running from a typical dev checkout.
lib = File.expand_path('../../../merb-core/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-core'

# The lib under test
require "merb-assets"

# Satisfies Autotest and anyone else not using the Rake tasks
require 'spec'

Merb.start :environment => 'test'

Merb::Plugins.config[:asset_helpers][:max_hosts] = 4
Merb::Plugins.config[:asset_helpers][:asset_domain] = "assets%d"
Merb::Plugins.config[:asset_helpers][:domain] = "my-awesome-domain.com"

Spec::Runner.configure do |config|
  config.include Merb::Test::RequestHelper  
end
