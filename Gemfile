source 'http://rubygems.org'

# Top tip: use "jruby -S bundle check" to verify dependencies.
# Top tip: Install missing gems with "jruby -S bundle install"

# Gems should install to the /.gems folder (ignored by git)
# Bundler's installation folder is configured in /.bundle/config


# dependencies are generated using a strict version, don't forget to edit the gem versions when upgrading.
merb_gems_version = "1.1.0"  # "1.0.15" "1.1.0"
dm_gems_version   = "0.10.2"  # "0.10.2" "0.10.3"
do_gems_version   = "0.10.1"  # "0.10.1" "0.10.2"

gem "merb-core", merb_gems_version 
gem "merb-action-args", merb_gems_version
gem "merb-assets", merb_gems_version  

gem "merb-helpers", merb_gems_version 
gem "merb-mailer", merb_gems_version  
gem "merb-slices", merb_gems_version  
gem "merb-auth-core", merb_gems_version
gem "merb-auth-more", merb_gems_version
gem "merb-auth-slice-password", merb_gems_version
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

gem "merb-parts", "0.9.8" #merb_gems_version
gem "uuidtools", "2.1.1"


# Added to satisfy bundler: (By George 16 Jul 2010)
gem "merb-cache",       merb_gems_version
gem "merb-action-args", merb_gems_version
gem "mongrel",			"1.1.5"

gem "rake",				"0.9.2.2"

gem "jruby-win32ole"

gem "rspec", "1.3.2"	# Stick with rspec v1.x for now. 
                        # v2 changed require syntax from "spec" to "rspec" so with our version of Merb, 
                        # higher versions or rspec cause error: "no such file to load -- spec"
                        # For more info see https://www.relishapp.com/rspec/rspec-core/v/2-4/docs/upgrade

gem "webrat"			# Added to fix error. See http://groups.google.com/group/merb/browse_thread/thread/ab4dcc2309f12d12
