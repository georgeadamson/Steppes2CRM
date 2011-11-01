require "rubygems"

# Use current merb-core sources if running from a typical dev checkout.
lib = File.expand_path('../../../merb-core/lib', __FILE__)
$LOAD_PATH.unshift(lib) if File.directory?(lib)
require 'merb-core'

# The lib under test
require "merb-param-protection"

# Satisfies Autotest and anyone else not using the Rake tasks
require 'spec'


Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
end

def new_controller(action = 'index', controller = nil, additional_params = {})
  request = OpenStruct.new
  request.params = {:action => action, :controller => (controller.to_s || "Test")}
  request.params.update(additional_params)
  request.cookies = {}
  request.accept ||= '*/*'
  
  yield request if block_given?
  
  response = OpenStruct.new
  response.read = ""
  (controller || Merb::Controller).build(request, response)
end
