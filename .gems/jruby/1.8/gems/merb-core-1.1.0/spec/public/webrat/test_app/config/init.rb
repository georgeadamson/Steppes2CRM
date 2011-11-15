# Go to http://wiki.merbivore.com/pages/init-rb
 
::Gem.clear_paths; ::Gem.path.unshift(File.dirname(__FILE__) + "/../gems/")

Merb::BootLoader.before_app_loads do
  require Merb.framework_root / ".." / ".." / "merb-helpers" / "lib" / "merb-helpers.rb"
end
 
use_test :rspec
use_template_engine :erb

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = 'aac0966e584824077b8c4e0442dca5a97f91d007'  # required for cookie session store
  # c[:session_id_key] = '_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
end
