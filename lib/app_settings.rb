#
# This file provides helpers for accessing the app_settings model.
#

# Prepare a globally shared hash of settings:
# Important: These hard-coded values may get overridden by values from the app_settings table.
# Beware of maximum fields lengths specified in models/app_setting.rb when adding settings here!
CRM = {

	:check_in_period				=> 2,			# Integer. Hours before flight start_date time
	:default_margin					=> 23,		# Integer. Percentage to add to net costs.
	:pnr_folder_path				=> '\\\\selfs\PNR-grabs',                 # Formerly '\\\\selsvr01\central files\Flights\Flight System\Amadeus\PNR-grabs'
	:flight_reminder_period	=> 21,		# Days before flight

  :shell_commands_folder_path  => '/scripts/',
  :doc_builder_script_file     => '/documents/doc_builder/sdb.vbs', # Location of the doc generator script.
  :doc_builder_settings_file   => '/documents/doc_builder/sdb.ini', # Location of the doc generator script INI file.
  :pdf_builder_script_file     => '/documents/pdf_builder/',        # Location of the PDF generator script.

  :doc_folder_path        => '//selfs/documents/',                  # Root folder for documents.
  :legacy_doc_folder_path => '//selsvr01/documents/',               # Root folder for OLD database documents.
  :doc_templates_path     => 'C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/(Sample Templates)',           # Root folder for documents.
  :letter_templates_path  => 'C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/(Sample Templates)/Letters',           # Root folder for documents.
  :images_folder_path     => '//selsvr01/documents/',               # Root folder for supplier images etc.
  :signatures_folder_path => '//selsvr01/documents/',               # Root folder for signature images.
  :portraits_folder_path  => '//selsvr01/documents/',               # Root folder for users' photos.
  :maps_folder_path       => '//selfs/documents/Map-Images'         # Root folder for country map images.

}


# Helper to copy all customisable app-settings from the database into our hash of CRM settings:
def reload_app_settings

	puts " Loading custom app settings:" unless Merb.environment == 'test'

	AppSetting.all( :order => [:name] ).each do |opt|

		value = opt.value
		value = value.to_i  if opt.value_type =~ /Integer/i
		value = value.to_f  if opt.value_type =~ /Decimal/i

		CRM[ opt.name.to_sym ] = value

		puts             " #{ opt.name } = \"#{ CRM[ opt.name.to_sym ] }\" (#{ opt.value_type })" unless Merb.environment == 'test' || Merb.environment == 'development'
		Merb.logger.info " #{ opt.name } = \"#{ CRM[ opt.name.to_sym ] }\" (#{ opt.value_type })" unless Merb.environment == 'test'

	end

	print "\n" unless Merb.environment == 'test'
	
end



# Initialise the app_settings table with very default-defaults if it looks rather empty!
def seed_app_settings

	existing_settings = AppSetting.all( :name => CRM.keys )
	
	if existing_settings.length != CRM.length
	
		CRM.each do |name,value|

			if existing_settings.first( :name => name ).nil?

				if value.is_a?(String)
					value_type = 'String'
				elsif value.to_s =~ /\./
					value_type = 'Decimal'
				else
					value_type = 'Integer'
				end

				AppSetting.create( :name => name, :value => value, :value_type => value_type, :description => name )

			end

		end
		
	end
	
end



# The following run once as the app initialises:

	# Initialise the app_settings table with very default defaults if it looks rather empty!
	seed_app_settings()
	
	# Populate the cached CRM settings right now:
	reload_app_settings()

