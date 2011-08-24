source 'http://rubygems.org'

# Top tip: use "jruby -S bundle check" to verify dependencies.
# Top tip: Install missing gems with "jruby -S bundle install"

# dependencies are generated using a strict version, don't forget to edit the gem versions when upgrading.
#merb_gems_version = "1.0.15"  # "1.0.15" "1.1.0"
#dm_gems_version   = "0.10.2"  # "0.10.2" "0.10.3"
#dm_gems_version   = "1.0.2"
#do_gems_version   = "0.10.1"  # "0.10.1" "0.10.2"
merb_gems_version = "1.1.3"
dm_gems_version   = "1.1.0"
do_gems_version   = "0.10.2"

gem "jruby-win32ole"

gem "merb-core", merb_gems_version 
gem "merb-action-args", merb_gems_version
gem "merb-assets", merb_gems_version  

gem "merb-helpers", merb_gems_version 
gem "merb-mailer", merb_gems_version  
gem "merb-slices", merb_gems_version  
gem "merb-auth-core", "1.1.1"
gem "merb-auth-more", "1.1.1"
gem "merb-auth-slice-password", "1.1.1"
gem "merb-param-protection", merb_gems_version
gem "merb-exceptions", merb_gems_version
gem "merb_datamapper", merb_gems_version

gem "data_objects", do_gems_version
gem "do_sqlserver", do_gems_version
gem "dm-core", dm_gems_version         
gem "dm-aggregates", dm_gems_version   
gem "dm-migrations", dm_gems_version   
gem "dm-timestamps", dm_gems_version   
gem "dm-types", dm_gems_version        
gem "dm-validations", dm_gems_version  
gem "dm-serializer", dm_gems_version   
gem "dm-sqlserver-adapter", dm_gems_version
#gem "dm-accepts_nested_attributes"
#gem "dm-accepts_nested_attributes", :git => 'https://github.com/snusnu/dm-accepts_nested_attributes.git'

gem "merb-parts", "0.9.8" #merb_gems_version
#gem "uuidtools", "2.1.1"


# Added to satisfy bundler: (By George 16 Jul 2010)
gem "merb-cache",       merb_gems_version
gem "merb-action-args", merb_gems_version
gem "mongrel",			"1.1.5"