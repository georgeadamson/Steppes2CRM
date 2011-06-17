require "rubygems"

# Use current merb-core sources if running from a typical dev checkout.
lib = File.expand_path('../../../merb-core/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-core'

# Use current merb-gen sources if running from a typical dev checkout.
lib = File.expand_path('../../../merb-gen/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-gen'

# The lib under test
require "merb-mailer"

# Satisfies Autotest and anyone else not using the Rake tasks
require 'spec'

Merb::Config.use do |c|
  c[:session_store] = :memory
end


Merb.start :environment => 'test'
