class Client
  include DataMapper::Resource

  property :id,						Serial, :key => true

  property :title_id,			Integer,:default => lambda{ |client,prop| Title.first( :name => 'Mr' ).id },  :required => true
  property :forename,			String, :default => "", :required => true
  property :name,					String,	:default => "", :required => true, :index => true	# AKA surname
  property :fullname,			String, :default => ""									# Derived from other fields if blank.

  property :known_as,			String, :default => ""
  property :salutation,		String, :default => "", 				:lazy => [:all]
  property :addressee,		String, :default => "", 				:lazy => [:all]

  property :tel_work,			String, :default => "", 				:lazy => [:all]
  property :fax_work,			String, :default => "", 				:lazy => [:all]
  property :tel_mobile1,	String, :default => "", 				:lazy => [:all]
  property :tel_mobile2,	String, :default => "", 				:lazy => [:all]
  
  property :email1,				String, :length => 60, :default => "", :format => :email_address, :messages => { :format => "The client's primary email address does not appear to be a valid address" }
	property :email2,				String, :length => 60, :default => "", :format => :email_address, :messages => { :format => "The client's alternative email address does not appear to be a valid address" }
  
  #property :areasOfInterest, Integer
  #property :clientSourceOriginalId, Integer
  #property :recentSource, Integer
  #property :clientType, Integer
  
  property :birth_date,		Date,														:lazy => [:all], :message => "Date of birth needs to be like 'dd/mm/yyyy' (or leave it blank)"
  property :birth_place,	String, :default => "", 				:lazy => [:all]
  property :nationality,	String, :default => "", 				:lazy => [:all]
  property :occupation,		String, :default => "",					:lazy => [:all]
  
  property :passport_name,				String, :default => "", :lazy => [:all]
  property :passport_number,			String, :default => "", :lazy => [:all]
  property :passport_issue_place,	String, :default => "", :lazy => [:all]
  property :passport_issue_date,	Date,										:lazy => [:all], :message => "Passport issue date needs to be like 'dd/mm/yyyy' (or leave it blank)"
  property :passport_expiry_date, Date,										:lazy => [:all], :message => "Passport expiry date needs to be like 'dd/mm/yyyy' (or leave it blank)"
  
  property :notes_frequent_flyer, String, :default => "", :lazy => [:all], :length => 255
  property :notes_airline,				String, :default => "", :lazy => [:all], :length => 255
  property :notes_seating,				String, :default => "", :lazy => [:all], :length => 255
  property :notes_food,						String, :default => "", :lazy => [:all], :length => 255
  property :notes_general,				String, :default => "", :lazy => [:all], :length => 255	# Depricated. Use notes collection instead.
  
  property :total_spend,					Integer, :default => 0, :lazy => [:all]

  # Defaults for the belongs_to fields below:
  property :marketing_id,					Integer, :default => 1, :lazy => [:all], :required => true			# Marketing preferences (email, post etc)
  property :type_id,							Integer, :default => 2, :lazy => [:all], :required => true     #(Default to ClientType.first(:name=>"Client").id)
  property :original_source_id,		Integer, :default => 1, :lazy => [:all], :required => true
  property :source_id,						Integer, :default => 1, :lazy => [:all]

  property :legacy_contactid,			Integer,								:lazy => [:all]

  property :address_client_id,		Integer, :required => false
  
  belongs_to :titlename,        :model => "Title",            :child_key => [:title_id]
  belongs_to :type,             :model => "ClientType",       :child_key => [:type_id]
  belongs_to :source,           :model => "ClientSource",     :child_key => [:source_id]
  belongs_to :original_source,  :model => "ClientSource",     :child_key => [:original_source_id]
  belongs_to :marketing,        :model => "ClientMarketing",  :child_key => [:marketing_id]

  # For reports:
  alias client_source source

  # Foreign-key back to clients table when referring to address of another client:
  belongs_to :address_client,  :model => "Client", :child_key => [:address_client_id]
  has 1,     :address_clients, :model => "Client", :child_key => [:address_client_id]

  has n, :tasks       # AKA Followups
  has n, :notes
  has n, :documents
  has n, :money_ins   # AKA Invoices
  has n, :web_requests
  has n, :brochure_requests
  
  has n, :client_addresses
  has n, :addresses, :through => :client_addresses

  has n, :trip_clients
  has n, :trips, :through => :trip_clients  #, :mutable => true

  # This is just a record of each User's clients recently worked on:
  has n, :user_clients
  has n, :users, :through => :user_clients  #, :mutable => true

  # Associate clients with the invoices that paid for them:
  has n, :money_in_clients
  has n, :on_invoices, :through => :money_in_clients, :model => "MoneyIn", :child_key => [:money_in_id]
  #has n, :money_ins, :through => :money_in_clients

	
  has n, :client_interests
  #has n, :interests, :through => :client_interests, :model => "Country"	#, :child_key => [:country_id]
	has n, :countries, :through => :client_interests
	alias :interests  :countries
	alias :interests= :countries=

	accepts_nested_attributes_for :notes
	accepts_nested_attributes_for :countries	#:interests
	accepts_nested_attributes_for :client_interests
	accepts_nested_attributes_for :addresses, :allow_destroy => true
	accepts_nested_attributes_for :client_addresses, :allow_destroy => true  # See http://github.com/snusnu/dm-accepts_nested_attributes

  # These are used for adding and removing existing objects to/from the collection:
	accepts_ids_for :trips
	accepts_ids_for :countries	# AKA :interests
	accepts_ids_for :addresses
  
	#validates_format :birth_date, :with => /^[0-3]?[0-9][\-\/][0-1]?[0-9][\-\/][0-9][0-9][0-9][0-9]$/, :allow_nil => true, :message => "The client's date of birth needs to be valid, or leave it blank please"
	#validates_format :birth_date, :with => /^[1-2][0-9]{3}[-\/][0-1][0-9][-\/][0-3][0-9]$/, :message => "Date of birth: Needs to be of the form 'dd/mm/yyyy' (or leave it blank)"
		

	alias :interests_ids  :countries_ids
	alias :interests_ids= :countries_ids=

  def title; return self.titlename.name; end

  # Helper for setting title_id when a title string is provided:
  def title=(new_title)
    #t = Title.first(:name => new_title) || self.titlename
    #self.title_id = t && t.id || nil
    self.titlename = Title.first(:name => new_title) || self.titlename
  end
    
	alias :surname  :name
	alias :surname= :name=
	alias :fullname_in_database :fullname
	def fullname;  return self.fullname_in_database.blank? ? "#{ self.title } #{ self.forename } #{ self.surname }" : self.fullname_in_database; end
	def shortname; return "#{ self.title } #{ self.forename.slice(0,1) } #{ self.surname }"; end
	alias :display_name :fullname

  # Match name is used to show extra details when trying to compare client names: (Eg when processing WebRequests)
  def match_name
    return "#{ 'NEW: ' if self.new? }#{ self.fullname }#{ ' ['+self.postcode+']' unless self.postcode.blank? }"
  end

  # The search keywords table will be updated after very save unless this flag is set:
  # (May be set by the controller if it is calling refresh_search_keywords explicitly)
  attr_accessor :auto_refresh_search_keywords_after_save



  before :valid? do

    # Unfortunately the conversion of fields to uk-date format has to be done in the
    # controller action otherwise datamapper makes it's own assumptions about us-dates
    # See accept_valid_date_fields_for() in the create and update actions.

    # Ensure we reference a client for their address. (Defaults to assume client is using his own address)
    # (This should not be confused with client_addresses or address_clients!)
    self.address_client ||= self

  end

  before :save do

    # Ensure we reference a client for their address. (Defaults to assume client is using his own address)
    # (This should not be confused with client_addresses or address_clients!)
    self.address_client ||= self

    # This functionality has been moved to the ClientAddress model.
    # Make sure exactly one address is tagged as active: (aka primary)
    # Sort them by is_active first then ensure only the first one is indeed active:
    #self.client_addresses.all( :order => [ :id.desc, :is_active ] ).reverse!.each_with_index{ |a,i| a.is_active = (i==0) }
    #addr = self.client_addresses.all( :order => [ :id.desc, :is_active.asc ] )
    #last = addr.length - 1
    #addr.each_with_index{ |a,i| a.is_active = (i==last) }
    # This original simpler solution failed. Does not like boolean as first item in order clause: self.client_addresses.all( :order => [ :is_active.desc, :id ] ).each_with_index{ |a,i| a.is_active = (i==0) }
    #self.client_addresses.each_with_index{ |a,i| a.is_active = (i==0) }
    #self.client_addresses.first.is_active = true if self.client_addresses.first

    # Might as well assume marketing source is same as original source if necessary: (Helpful when someone uses this field for reposrting)
    self.source ||= self.original_source

  end

  before :update do
    #datePattern = /^[0-3][0-9][-\/][0-1][0-9][-\/][1-2][0-9]{3}$/
    #self.birth_date = nil #unless self.birth_date.to_s =~ datePattern
    #self.passport_issue_date = nil #unless self.passport_issue_date.to_s =~ datePattern
    #self.passport_expiry_date = nil #unless self.passport_expiry_date.to_s =~ datePattern
  end 

  after :create do

    # Ensure new clients have a reference for their address if none was specified:
    unless self.address_client
      address_client = self
      self.save!
    end

  end
  
  after :save do

		# Clear cached lists after saving any changes:
		@primary_address  = nil
		@active_trips     = nil

    # The primary address flag should be managed by hooks in the ClientAddress model but
    # some situations do not trigger them (eg address.destroy) so this is a belt-and-braces precaution:
    #ClientAddress.ensure_client_has_one_primary_address( self )
    
    # Repopulate the keyword search table entries for this client:
    self.refresh_search_keywords() if self.auto_refresh_search_keywords_after_save

  end

  attr_accessor :search_results_trips
	attr_accessor :search_results_address
    

	
  # Accessors for the client's current active ADDRESS:
  # Note how we cache @primary_address to prevent unecessary db trips as each address line is accessed:
  def primary_address
		return @primary_address ||= self.addresses.first( ClientAddress.is_active => true )
  end

  # Depricated:
  	def primary_address=(address)
  
      if address && address.id.to_i > 0
  
  		  self.client_addresses.each do |a|
          a.is_active = ( a.address_id == address.id )
          @primary_address = address if a.is_active
        end
  
      end
  
    end 

	def primary_address_id
		return self.primary_address.id
	end

  # Helper for setting one of the client_addresses as primary. (Used by the addresses form)
  # (The test for blank/new just prevents accidentally submitted attribute from causing errors)
	def primary_address_id=(id)

    unless id.blank? || self.new? || self.client_addresses.all( :address_id => id ).empty?
	    self.client_addresses.each{ |a| a.is_active = (a.address_id == id) }.save!
      @primary_address = nil
    end

  end

  alias address             primary_address
  alias address=            primary_address=
  alias active_address_id   primary_address_id    # TODO: Depricate this.
  #alias active_address_id=  primary_address_id=   # TODO: Depricate this.

	# primary_address.country:
  def country
		return self.primary_address && self.primary_address.country
  end

  # Generate accessor methods for the attributes of the active address:
  %w[ address1 address2 address3 address4 address5 address6 postcode country_id tel_home fax_home ].each do |attr_name|
    define_method attr_name do
      return self.address ? self.address[attr_name.to_sym] : ''
    end
  end
	
  # All clients who are on trips with this client:
  def fellow_travellers
		return Client.all( Client.trips.id => self.trips_ids, :id.not => self.id )
  end


  # All clients who share an address with this client:
  def fellow_dwellers
    #return Client.all( :address_client_id => address_client.id, :address_client_id.not => nil, :id.not => id )
    return Client.all( :conditions => ["id != ? AND ( address_client_id = ? OR address_client_id = ? )", self.id, self.id, self.address_client.id.to_i ] )
  end


  # Simple string summarising the trips: (Eg: "1 unconfirmed, 1 confirmed, 2 completed, 1 canceled, 5 abandoned")
  # For speed, we loop through the trips counting the statuses, not the other way around.
  def trips_statement( trips_list = nil )

		counts              = {}
		statement           = []
		trip_states_lookup  = cached(:trip_states_hash)
		
		trips_list ||= self.active_trips
    
		# Loop through the trips, counting how many of each status we find:
		trips_list.each{ |trip| counts[trip.status_id] = counts[trip.status_id].to_i + 1 }
		
		# Convert the hash of counts to an array of strings each displaying status names alongside their counts:
		counts.each{ |id,count| statement << "#{ count } #{ trip_states_lookup[id] }" }

		return statement.empty? ? 'None' : statement.join(', ')

  end


  # All the client's trips that are the current active version of each of the client's trips: (ie ignore "other" versions)
  # Note how we cache @active_trips to prevent unecessary db trips as each trip is accessed:
  # Added :type_id filter 01-Sep-2010 GA.
  def active_trips
    return @active_trips ||= trips.all( :is_active_version => true, :type_id.not => TripType::TOUR_TEMPLATE )
  end

  def fixed_deps( tour_id = nil )
    deps = self.active_trips.all( :type_id => TripType::FIXED_DEP )
    return tour_id ? deps.all( :tour_id => tour_id ) : deps
  end


  # Depricated?
  # Returns a very compact alternative to the trips collection (Eg: for use with client.TO_JSON in "views/clients/search.json.erb")
  # Note the use of "each" to encourage DataMapper to use Strategic Eager Loading. (Otherwise we would have just used "map")
  # TODO: Adapt the trips method to decide when to return a compact list?
  def trips_lite
    result = []
    self.trips.each{ |trip| result << trip.lite }
    return result
  end

  # contextId is a helper to ensure consistency throughout the UI:
  def contextId
    return "tabClient" + (id || 0).to_s
  end
  
  # Helper to ensure consistent HTML Element IDs throughout the UI:
  # I know this should not be on the model but it's most convenient here!
  # TODO: Refactor to use Trips Controller Actions instead.
  def contextId (subPanel = nil)
    nameOf = { :summary=>"Summary", :documents=>"Documents", :payments=>"Payments", :newTrip=>"NewTrip", :trip=>"Trip" }
    return "client" + (id || 0).to_s + ( nameOf[subPanel] || "" )
  end


  # Helper to instruct database to rebuild search data for current client:
  def refresh_search_keywords
		Client.refresh_search_keywords(self.id)
  end


  
  def initialize(*)
    super
    @auto_refresh_search_keywords_after_save ||= true
  end






# Class methods:


  # Helper to instruct database to rebuild search data for one or all clients:
  # Warning: Takes longer when client_id not specified! (Though usually less than 10 seconds)
  def self.refresh_search_keywords(client_id = nil)

    Merb.logger.info "Refreshing client_keywords table for client_id #{ client_id || 'all'  }"

		sql_statement = "EXEC usp_client_keywords_refresh ?"
		repository(:default).adapter.execute( sql_statement, client_id )
    
  end
  

  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Client'
  end
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    #return [ :name, :title, :trip_clients, :trips ]
    return [ :name, :title, :forename, :addressee, :salutation, :tel_work, :fax_work, :tel_mobile1, :tel_mobile2, :email1, :email2, :original_source, :source, :client_type, :money_ins, :trips ]
  end

end


			
