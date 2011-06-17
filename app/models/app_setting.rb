class AppSetting
  include DataMapper::Resource

  property :id,		Serial

  property :name,				String, :required => true,	:length => 50, :unique => true,	:default => 'new_setting'
  property :value,			String, :required => true,	:length => 200, 								:default => '0'
	property :value_type,	String, :required => true,	:length => 20, 									:default => :Integer
  property :description,String, :required => true,	:length => 100, :unique => true,:default => 'What is this setting for?'

	# In theory value_type could use this instead of String: Enum[ :String, :Integer, :Decimal ]
	
	validates_is_number :value, :unless => Proc.new {|setting| setting.value_type.to_sym == :String }

	after :save do
		# Repopulate our custom CRM cached hash of settings: (See lib/app_settings.rb)
		reload_app_settings()
	end

	def name_and_value
		return "#{ self.name } \"#{ self.value }\""
	end
	alias display_name name_and_value

end

# This is a hack because for some reason the AppSetting table is not being created when running tests:
AppSetting.auto_migrate! if Merb.environment == 'test'		# Warning: Running this will clear the table!

