# Go to http://wiki.merbivore.com/pages/init-rb
  
$KCODE    = 'u'    # Equivalent to the jruby -Ku switch. Does not seem to make a difference :(
#ENV['TZ'] = 'UTC' # This affects times in logs etc but does not fix DataMapper date field timezone problem.
  
require 'rubygems'
require 'config/dependencies.rb'

# Also see PDFKit.configure (below)
require 'pdfkit'

use_orm :datamapper
use_test :rspec
use_template_engine :erb

# Ensure merb knows about our custom modules in the /lib folder:
Merb.push_path(:lib, Merb.root / 'lib', '**/*.rb')

# Tell merb about css mimetypes: (Necessary for the dynamically generated timeline_styles)
Merb.add_mime_type :css, :to_css, %w[text/css]	#, "Content-Encoding" => "gzip"		# gzip seems to break the output!

# Tell merb about document mime types:
Merb.add_mime_type :doc, :to_doc, %w[application/msword]
Merb.add_mime_type :pdf, :to_pdf, %w[application/pdf]
Merb.add_mime_type :csv, :to_csv, %w[application/excel]
Merb.add_mime_type :jpg, :to_jpg, %w[image/jpeg]


Merb::Config.use do |c|

  c[:use_mutex]      = false
  c[:session_store]  = 'datamapper'	# can also be 'cookie', 'memory', 'memcache', 'container', 'datamapper'
  c[:session_expiry] = 2419200			# Seconds: 604800 = 1week, 2419200 = 4weeks

  # cookie session store configuration
  c[:session_secret_key] = '016283bfb73ac35d7c55b4bfedd3814864c035fd' # required for cookie session store
  c[:session_id_key]     = '_crm_session_id'									        # cookie session id key, defaults to "_session_id"

end

Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
  puts "PROCESS ID IN TASK MANAGER: #{ Process.pid }"
end

Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  #DataObjects::Sqlserver.logger = DataObjects::Logger.new(STDOUT, 0) 
  DataObjects::Sqlserver.logger = DataObjects::Logger.new('log/dm.log', 0) 
end

#Merb::Cache.setup do
#  register( MemcachedStore )
#end

# The following were attempts to display Windows PID when app shuts down, but these commands are not relevant in jruby:
#Merb::BootLoader.before_worker_shutdown do
#  puts "PROCESS ID IN TASK MANAGER: #{ Process.pid }"
#end
#Merb::BootLoader.before_master_shutdown do
#  puts "PROCESS ID IN TASK MANAGER: #{ Process.pid }"
#end

Extlib::Inflection.plural_word 'status', 'statuses' # This does not seem to fix DataMapper "TripStatu" problem :(


# For exporting pages as PDF:
# See also "use PDFKit::Middleware" added to config/rack.rb
# More info: https://github.com/pdfkit/pdfkit
# To make this work in Merb/Windows we had to hack the code a little:
# See changes in 
# - C:\jruby-1.6.4\lib\ruby\gems\1.8\gems\pdfkit-0.5.3\lib\pdfkit\pdfkit.rb
# - C:\jruby-1.6.4\lib\ruby\gems\1.8\gems\pdfkit-0.5.3\lib\pdfkit\middleware.rb
# Useful commands/syntax for debugging:
# p=PDFKit.new("<html><body>test</body></html>",{})
# IO.popen "\"D:/SteppesCRM/wkhtmltopdf/wkhtmltopdf.exe\""
# IO.popen "\"D:/SteppesCRM/wkhtmltopdf/wkhtmltopdf.exe\" \"--page-size\" \"Legal\" \"--print-media-type\" \"--quiet\" \"-\" \"-\""
# kit = PDFKit.new(File.new('c:\temp\test.html'))
# kit.to_file('c:\temp\test.pdf')
PDFKit.configure do |config|
  config.wkhtmltopdf = 'D:/SteppesCRM/wkhtmltopdf/wkhtmltopdf.exe'
  config.default_options = {
    :page_size => 'Legal',
    :print_media_type => true # Necessary for skipping a couple of screen-only css files that seem to upset wkhtmltopdf.
  }
  # config.root_url = "http://localhost" # Use only if your external hostname is unavailable on the server.
end

#@pdfkit = PDFKit::Middleware.new
#Merb::Rack::Middleware.new(@pdfkit)

#PDFKit::Middleware::initialize
#Merb::Config.use PDFKit::Middleware
#Merb::Rack::Middleware.use PDFKit::Middleware
#Merb::Rack::Middleware::Config.use do |config|
#  c.middleware.use PDFKit::Middleware
#end