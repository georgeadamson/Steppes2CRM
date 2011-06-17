class Supplier
  include DataMapper::Resource

  # IMPORTANT: Flight Handlers (AKA Flight Agents) from the old Database are now Supplier Type 2.
  
  FLIGHT  = 1 unless defined?(FLIGHT)
  AIRLINE = 1 unless defined?(AIRLINE)
  HANDLER = 2 unless defined?(HANDLER)
  ACCOMM  = 4 unless defined?(ACCOMM)
  GROUND  = 5 unless defined?(GROUND)
  MISC    = 8 unless defined?(MISC)
  
  property :id,						      Serial
  property :name,					      String,	 :required => true,	:default => 'New supplier'
  property :code,					      String,	 :length	 => 3,		:default => ''	# Typically only used for Airline codes
  property :type_id,			      Integer, :required => true,	:default => 1   # 1=Airline, 2=FlightAgent, 4=Accomm, 5=Ground, 8=Misc
  property :currency_id,	      Integer, :required => true
  property :linked_supplier_id,	Integer, :lazy => true                                       # Applies to Accommodation only. Maps to a Ground Agent. TODO: Use for Airlines too?
  property :country_id,		      Integer, :lazy => true,	  :required => true,	:message => 'A country has not been chosen for this supplier'
  property :address_id,        	Integer, :lazy => true
  property :tel_emergency,			String,  :lazy => true,   :length => 30
  property :email,	            String,  :lazy => true,   :length => 255
  property :location,           String,  :lazy => true    # To be depricated?
  property :description,	      String,  :lazy => true,   :length => 2500, :lazy => true
  property :contact_name,	      String,  :lazy => true
  property :contact_name2,      String,  :lazy => true
  property :notes,              String,  :lazy => true,   :length => 255
  property :default_room_type,	String,  :lazy => true
  property :default_meal_plan,	String,  :lazy => true
  property :image_file,         String,  :lazy => true,   :length => 100    # Migrate to images table
  property :bankline_template,  String,  :lazy => true,   :length => 20     # Alphanumeric code used by Steppes accounts system. Added May 2011 by GA

  property :bank_name,        	                  String, :lazy => :bank
  property :bank_account_holder_name,             String, :lazy => :bank
  property :bank_account_number,        	        String, :lazy => :bank,   :length => 20
  property :bank_sort_code,        	              String, :lazy => :bank,   :length => 10
  property :bank_swift_code,        	            String, :lazy => :bank,   :length => 20
  property :bank_charges_code,        	          String, :lazy => :bank
  property :bank_intermediary_name,               String, :lazy => :bank
  property :bank_intermediary_swift_code,         String, :lazy => :bank,   :length => 20
  property :bank_currency_id,        	            Integer,:lazy => :bank
  property :bank_address_id,        	            Integer,:lazy => :bank

  property :facilities_number_of_rooms,        	  String, :lazy => :facilities
  property :facilities_mobile_reception,        	String, :lazy => :facilities
  property :facilities_electricity,        	      String, :lazy => :facilities
  property :facilities_internet,        	        String, :lazy => :facilities
  property :facilities_activities,        	      String, :lazy => :facilities,   :length => 250
  property :facilities_health_and_safety,        	String, :lazy => :facilities,   :length => 250
  property :facilities_money_exchange,        	  String, :lazy => :facilities
  property :facilities_credit_card,        	      String, :lazy => :facilities
  property :facilities_room_description,        	String, :lazy => :facilities,   :length => 250
  property :facilities_region_description,        String, :lazy => :facilities,   :length => 250
  property :facilities_air_transfer_description,  String, :lazy => :facilities,   :length => 250
  property :facilities_road_transfer_description, String, :lazy => :facilities,   :length => 250
  property :facilities_misc,        	            String, :lazy => :facilities,   :length => 250
  property :facilities_inspected_by,        	    String, :lazy => :facilities,   :length => 100
  property :facilities_inspected_date,        	  Date,   :lazy => :facilities
  
  property :created_at,                           Date
  property :updated_at,                           Date
  
 
  belongs_to :address
  belongs_to :country
  belongs_to :type,		          :model => "TripElementType",	:child_key => [:type_id]
  belongs_to :currency,         :model => "ExchangeRate",			:child_key => [:currency_id]
  belongs_to :linked_supplier,  :model => "Supplier",         :child_key => [:linked_supplier_id] # AKA Default handler for Accommodation. TODO: Use for Airlines too?
  belongs_to :bank_currency,    :model => "ExchangeRate",     :child_key => [:bank_currency_id]
  belongs_to :bank_address,     :model => "Address",          :child_key => [:bank_address_id]

	
  has n, :trip_elements,  :child_key => [:supplier_id]		# Trip Element Supplier
  has n, :trip_elements,  :child_key => [:handler_id]		# Trip Element Handler AKA Flight Agent, Flight Handler
  has n, :excursions

  has n, :company_suppliers
  has n, :companies, :through => :company_suppliers
  
  has n, :money_outs
  
	accepts_ids_for :companies
	accepts_nested_attributes_for :address
	#accepts_nested_attributes_for :companies


  # Set the default sort order:
  default_scope(:default).update( :order => [:name,:code] )


	validates_is_unique :name, :scope => [ :type_id, :currency_id ],
		:message => 'A supplier of this type already exists with the same name and currency'

	# Enforce uniqueness of Airline codes:
	validates_is_unique :name, :scope => [ :type_id, :code ],
		:if => Proc.new {|supplier| supplier.type_id == 1 },
		:message => 'An airline already exists with the same airline code'

	validates_with_method :require_one_or_more_companies

	def require_one_or_more_companies
	
		if self.companies.empty?
			return [ false, 'You must choose at least one company who uses this supplier' ]
		else
			return true
		end
	
	end



  before :save do
    # Prevent blank field "" from causing silent failure!
    self.linked_supplier_id = nil if self.linked_supplier_id.to_s.empty?
  end



  # Convenience method to return id and name:
	def id_and_name
		return [ self.id, self.display_name ]
	end


	# Supplier name and currency string: (Eg: "British Airways [GBP]")
	def name_and_currency

		# Populate currencies lookup if not already loaded:
		#$cached[:exchange_rates_hash] ||= {}
		#$cached[:exchange_rates].each{ |currency| $cached[:exchange_rates_hash][currency.id] = currency.name } if $cached[:exchange_rates_hash].empty?

		supplier_name = self.name.blank? ? '(blank supplier name)' : self.name
		currency_name	= cached(:exchange_rates_hash)[self.currency_id] || ''

		return "#{ supplier_name } #{ '[' + currency_name + ']' unless currency_name.blank? }"

	end

	alias display_name name_and_currency


	# Supplier name and code and currency string: (Eg: "British Airways (BA) [GBP]")
	def name_code_and_currency

		supplier_name = self.name.blank? ? '(blank supplier name)' : self.name
		supplier_code = self.code.blank? ? 'no code'               : self.code
		currency_name	= cached(:exchange_rates_hash)[self.currency_id] || ''

		return "#{ supplier_name }#{ ' - ' + supplier_code unless supplier_code.blank? }#{ ' [' + currency_name + ']' unless currency_name.blank? }"

	end

	
	# Supplier NAME and CODE string used for consistent display: (Eg: "British Airways [BA]")
  # Typically only used for airlines.
  # BEWARE of using different brackets. Some ui script may expect '[...]' for deriving supplier code.
  # NOTE the use of double-space ("  ") to safely tell the UI where additional formatting may be added.
	def name_and_code
		name = self.name.blank? ? '(blank supplier name)' : self.name
		code = self.code.blank? ? 'no code'               : self.code
		return "#{ name }  [#{ code }]"
	end

	# Supplier CODE and name string used for consistent display: (Eg: "BA [British Airways]")
  # Typically only used for airlines.
  # BEWARE of using different brackets. Some ui script may expect '[...]' for deriving supplier name.
  # NOTE the use of double-space ("  ") to safely tell the UI where additional formatting may be added.
	def code_and_name
		name = self.name.blank? ? '(blank supplier name)' : self.name
		code = self.code.blank? ? 'no code'               : self.code
		return "#{ code }  [#{ name }]"
	end
	alias display_code code_and_name

	

	# Helpers for testing what type of supplier this is: 
	def is_flight;  return self.type_id == FLIGHT;  end
	def is_handler; return self.type_id == HANDLER; end
	def is_accomm;  return self.type_id == ACCOMM;  end
	def is_ground;  return self.type_id == GROUND;  end
	def is_misc;    return self.type_id == MISC;    end
  alias flight?   is_flight
  alias handler?  is_handler
  alias agent?    is_handler  # TODO: Depricate this? (Because it can be confused with ground agent)
  alias accomm?   is_accomm
  alias ground?   is_ground
  alias misc?     is_misc
  
  # TODO: Depricate these after ensuring they are not referenced anywhere in the project:
  alias is_agent    is_handler
  alias is_agent?   is_handler
  alias is_handler? is_handler
  alias is_flight?  is_flight
  alias is_accomm?  is_accomm
  alias is_ground?  is_ground
  alias is_misc?    is_misc
  
  # Whilst the is_flight? method is consistent with TripElement model let's make it more relevant to Supplier:
  alias is_airline? is_flight?
  
end

# Suppliers.auto_migrate!