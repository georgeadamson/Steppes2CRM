class Airport
  include DataMapper::Resource
  
  property :id, Serial
	
  property :name,       String,			:required => true,	:unique => true, :default => 'New airport'
  property :code,       String,			:required => true,	:unique => true
  property :city,       String,			:required => true
  property :country_id, Integer,		:required => true
  property :tax,	      BigDecimal,	:required => false, :precision=>6, :scale=>2, :default => 0					# Unused. For future enhancement.
	
  belongs_to :country
  #belongs_to :company	# Depricated because country is already associated with company.
	
  has n, :trip_elements, :child_key => [:depart_airport_id]		# tripElement.departAirport
  has n, :trip_elements, :child_key => [:arrive_airport_id]		# tripElement.arriveAirport
  has n, :touchdowns																					# tripElement.touchdowns	???
	
  # Set the default sort order:
  default_scope(:default).update( :order => [:name,:code] )
  
	before :save do
		self.code.upcase!
	end
	
	# Helper to return the airport id and name in a little diddy array:
	def id_and_name
		return [ self.id, self.display_name ]
	end
	
	# Helper to return the airport code if defined, otherwise the name:
	def code_or_name
		self.code.blank? ? self.name : self.code
	end
	
	# Airport NAME and code string used for consistent display: (Eg: "Heathrow [LHR]")
  # BEWARE of using different brackets. Some ui script may expect '[...]' for deriving airport code.
  # NOTE the use of double-space ("  ") to safely tell the UI where additional formatting may be added.
	def name_and_code
		name = self.name.blank? ? '(blank airport name)' : self.name
		code = self.code.blank? ? 'no code'              : self.code
		return "#{ name }  [#{ code }]"
	end
	alias display_name name_and_code
	
	# Airport CODE and name string used for consistent display: (Eg: "LHR [Heathrow]")
  # BEWARE of using different brackets. Some ui script may expect '[...]' for deriving airport name.
  # NOTE the use of double-space ("  ") to safely tell the UI where additional formatting may be added.
	def code_and_name
		name = self.name.blank? ? '(blank airport name)' : self.name
		code = self.code.blank? ? 'no code'              : self.code
		return "#{ code }  [#{ name }]"
	end
	alias display_code code_and_name
	
end
