class TripElementMiscType
  include DataMapper::Resource

  property :id,							Serial
  property :name,						String,	:required => true, :unique  => true, :default => 'New misc type'
  property :default_margin,	String, :required => true, :default => '0%', :format => /^\d{1,3}(\.\d{1,2})?\%?$/, :message => 'Default margin must be a value or a percentage, eg: 100 or 24%'
  property :updated_at,			DateTime
  property :updated_by,			String

  has n, :trip_elements, :child_key => [:misc_type_id]
	
	# Ideally margin would default to global app setting but this does not seem to work: (Moved to 'new' action in the controller instead)
	#	after :new do
	#		self.default_margin = CRM[:default_margin] || 24
	#	end

	def name_and_margin
		return "#{ self.name } [#{ self.default_margin }]"
	end
	#alias display_name name_and_margin			# DEPRICATED until default_margin feature is implemented

end
