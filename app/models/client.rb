class Client
  include DataMapper::Resource

  property :id,						Serial, :key => true

  property :title_id,			Integer,:default => lambda{ |client,prop| Title.first( :name => 'Mr' ).id },  :required => true
  property :forename,			String, :default => "", :required => true
  property :name,					String,	:default => "", :required => true, :index => true	# AKA surname
  property :fullname,			String, :default => ""									# Derived from other fields if blank.

  property :known_as,			String, :default => ""
  property :salutation,		String, :default => ""                                                                                                                                                        , :lazy => [:all]
  property :addressee,		String, :default => ""                                                                                                                                                        , :lazy => [:all]
  
  property :tel_work,			String, :default => ""                                                                                                                                                        , :lazy => [:all]
  property :fax_work,			String, :default => ""                                                                                                                                                        , :lazy => [:all]
  property :tel_mobile1,	String, :default => ""                                                                                                                                                        , :lazy => [:all]
  property :tel_mobile2,	String, :default => ""                                                                                                                                                        , :lazy => [:all]
  
  property :email1,				String, :length => 60, :default => "", :format => :email_address, :messages => { :format => "The client's primary email address does not appear to be a valid address" }
	property :email2,				String, :length => 60, :default => "", :format => :email_address, :messages => { :format => "The client's alternative email address does not appear to be a valid address" }
  
  #property :areasOfInterest, Integer
  #property :clientSourceOriginalId, Integer
  #property :recentSource, Integer
  #property :clientType, Integer
  
  property :birth_date,		Date,														:message => "Date of birth needs to be like 'dd/mm/yyyy' (or leave it blank)"                                                                 #, :lazy => [:all]
  property :birth_place,	String, :default => "" 				                                                                                                                                                #, :lazy => [:all]
  property :nationality,	String, :default => "" 				                                                                                                                                                #, :lazy => [:all]
  property :occupation,		String, :default => "" 					                                                                                                                                              #, :lazy => [:all]
  
  property :passport_name,				String, :default => ""                                                                                                                                               #, :lazy => [:all]
  property :passport_number,			String, :default => ""                                                                                                                                               #, :lazy => [:all]
  property :passport_issue_place,	String, :default => ""                                                                                                                                               #, :lazy => [:all]
  property :passport_issue_date,	Date,										:message => "Passport issue date needs to be like 'dd/mm/yyyy' (or leave it blank)"                                                           #, :lazy => [:all]
  property :passport_expiry_date, Date,										:message => "Passport expiry date needs to be like 'dd/mm/yyyy' (or leave it blank)"                                                          #, :lazy => [:all]
  
  property :notes_frequent_flyer, String, :default => "", :length => 255                                                                                                                                , :lazy => [:all]
  property :notes_airline,				String, :default => "", :length => 255                                                                                                                                , :lazy => [:all]
  property :notes_seating,				String, :default => "", :length => 255                                                                                                                                , :lazy => [:all]
  property :notes_food,						String, :default => "", :length => 255                                                                                                                                , :lazy => [:all]
  property :notes_general,				String, :default => "", :length => 255	                                                                                                                              , :lazy => [:all]
  # Depricated notes_general. Use notes collection instead.
  
  property :total_spend,					Integer, :default => 0                                                                                                                                                #, :lazy => [:all]
  
  # Defaults for the belongs_to fields below:                                                                                                                                                           
  property :marketing_id,					Integer, :default => 1, :required => true		# Marketing preferences (email, post etc)                                                                                 #, :lazy => [:all]
  property :type_id,							Integer, :default => 2, :required => true    #(Default to ClientType.first(:name=>"Client").id)                                                                       #, :lazy => [:all]
  property :original_source_id,		Integer, :default => 1, :required => true                                                                                                                             #, :lazy => [:all]
  property :source_id,						Integer                                                                                                                                                               #, :lazy => [:all]

  property :address_client_id,		Integer, :required => false
  property :legacy_contactid,			Integer,								      :lazy => [:all]

  property :original_company_id,  Integer   # The company who first added the client to the database.
  property :created_at,           DateTime
  property :created_by,           String
  property :updated_at,           DateTime
  property :updated_by,           String
  
  property :deleted_at,           DateTime, :required => false  # See custom "archive" method below.
  property :deleted_by,           String,   :required => false, :lazy => [:all]
  
  belongs_to :titlename,        :model => "Title",            :child_key => [:title_id]
  #belongs_to :type,            :model => "ClientType",       :child_key => [:type_id]
  belongs_to :client_type,      :model => "ClientType",       :child_key => [:type_id]
  belongs_to :source,           :model => "ClientSource",     :child_key => [:source_id]
  belongs_to :original_source,  :model => "ClientSource",     :child_key => [:original_source_id]
  belongs_to :marketing,        :model => "ClientMarketing",  :child_key => [:marketing_id]
  belongs_to :original_company, :model => "Company",          :child_key => [:original_company_id]

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

  # Associate clients with companies: (Only used on client page and for marketing/reports)
  has n, :client_companies
  has n, :companies, :through => :client_companies

  # Client Marketing options by Company Division:
  has n, :client_marketing_divisions
  has n, :divisions, :through => :client_marketing_divisions

  # Friendly readable summary of client's marketing preferences:
  # Note: The default delimiters provide the best default for reports, when no arguments are possible.
  # Eg: "Email: Steppes, Discovery. Postal: Discovery	"
  def marketing_summary( text_when_none = 'None', media_delimiter = '. ', divisions_delimiter = ', ' )

    summary = []

    unless self.client_marketing_divisions.empty?
      
      email_divisions  = marketing_divisions_email()
      postal_divisions = marketing_divisions_postal()

      summary.push "Email: #{  email_divisions.join(divisions_delimiter)  }" unless email_divisions.empty?
      summary.push "Postal: #{ postal_divisions.join(divisions_delimiter) }" unless postal_divisions.empty?

    end

    return summary.empty? ? text_when_none : summary.join(media_delimiter)

  end

  def marketing_summary_email( text_when_none = 'None', verbose = false )
    
    divisions = marketing_divisions_email()
    return divisions.empty? ? text_when_none : "#{ verbose ? 'Email: ' : '' }#{ divisions.join(', ') }"
    
  end
  
  def marketing_summary_postal( text_when_none = 'None', verbose = false )
    
    divisions = marketing_divisions_postal()
    return divisions.empty? ? text_when_none : "#{ verbose ? 'Postal: ' : '' }#{ divisions.join(', ') }"
    
  end

  # Set the default sort order and filter:
  #default_scope(:default).update( :deleted_by => nil, :order => [:name,:forename] )



	accepts_nested_attributes_for :notes
	accepts_nested_attributes_for :countries	#:interests
	accepts_nested_attributes_for :client_interests
	accepts_nested_attributes_for :addresses, :allow_destroy => true
	accepts_nested_attributes_for :client_addresses, :allow_destroy => true  # See http://github.com/snusnu/dm-accepts_nested_attributes
	accepts_nested_attributes_for :client_marketing_divisions, :allow_destroy => true

  # These are used for adding and removing existing objects to/from the collection:
	accepts_ids_for :trips
	accepts_ids_for :countries	# AKA :interests # IMPORTANT: See custom "def countries_ids=" below
	accepts_ids_for :addresses
	accepts_ids_for :companies
  
	#validates_format :birth_date, :with => /^[0-3]?[0-9][\-\/][0-1]?[0-9][\-\/][0-9][0-9][0-9][0-9]$/, :allow_nil => true, :message => "The client's date of birth needs to be valid, or leave it blank please"
	#validates_format :birth_date, :with => /^[1-2][0-9]{3}[-\/][0-1][0-9][-\/][0-3][0-9]$/, :message => "Date of birth: Needs to be of the form 'dd/mm/yyyy' (or leave it blank)"

  # For reports:
  alias client_source source
  #alias client_type   type
  alias type client_type
  def country_name;      self.country.name; end
  def mailing_zone_name; self.country && self.country.mailing_zone.name; end
  def areas_of_interest; self.countries_names.join(', '); end
  def total_spend;       self.attribute_get(:total_spend) || 0; end # Override to avoid nil

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
	def fullname;  return "#{ self.title } #{ self.forename            } #{ self.surname }"; end
	def shortname; return "#{ self.title } #{ self.forename.slice(0,1) } #{ self.surname }"; end
	alias :display_name :fullname

  def age
    return self.birth_date ? (Date.today - self.birth_date.to_date).to_i / 365 : nil
  end

  # Match name is used to show extra details when trying to compare client names: (Eg when processing WebRequests)
  def match_name
    return "#{ 'NEW: ' if self.new? }#{ self.fullname }#{ ' ['+self.postcode+']' unless self.postcode.blank? }"
  end

  # The search keywords table will be updated after very save unless this flag is set:
  # (May be set by the controller if it is calling refresh_search_keywords explicitly)
  attr_accessor :auto_refresh_search_keywords_after_save



  before :valid? do

    self.birth_date = nil           if self.birth_date == ''
    self.passport_issue_date = nil  if self.passport_issue_date == ''
    self.passport_expiry_date = nil if self.passport_expiry_date == ''

    #puts 'COUNTRIES', self.countries_ids.inspect, self.countries.inspect
    #self.client_interests.each do |client_interest|
    #  puts 'before', client_interest.inspect, client_interest.country.id
    #end
    #puts 'self.countries.dirty?', self.countries.dirty?
    
    # Deprecated: An attempt to fix the Client-save bug where Countries of Interest caused save to fail for no apparent reason :(
    # See custom def countries_ids= below
    #countries1 = self.countries.nil?        ? [] : self.countries.map{|c|c.id}
    #countries2 = self.client_interests.nil? ? [] : self.client_interests.map{|c|c.country_id}
    ##if self.countries.dirty? && self.client_interests.count{|ci| return !ci.client_id.nil? } > 0
    #if countries1.length != countries2.length ||
    #   countries1.sort.inspect != countries2.sort.inspect
    #  
    #  #self.client_interests.destroy!
    #  
    #  self.countries.each do |country|
    #    self.client_interests.new( :country_id => country.id )
    #  end
    #  
    #end

    #self.client_interests.each do |client_interest|
    #  puts 'after', client_interest.inspect, client_interest.country.id
    #end
    
    # Unfortunately the conversion of fields to uk-date format has to be done in the
    # controller action otherwise datamapper makes it's own assumptions about us-dates
    # See accept_valid_date_fields_for() in the create and update actions.

    # Ensure we reference a client for their address. (Defaults to assume client is using his own address)
    # (This should not be confused with client_addresses or address_clients!)
    self.address_client ||= self

  end

  before :create do

    # Ensure at least one company is selected for marketing to new client:
    self.companies << self.original_company if self.companies.empty? && self.original_company
    
    #@new_primary_address_id = id

    #puts self.client_addresses.inspect, self.addresses.inspect, @new_primary_address_id
    
    #unless id.blank? || self.new? || self.client_addresses.all( :address_id => id ).empty?

	    #self.client_addresses.each{ |a| puts a.inspect, a.is_active = (a.address_id == id.to_i) }.save!

      #active           = self.client_addresses.first( :is_active => true )
      #@primary_address = active.nil? ? nil : active.address

    #end
    
  end

  before :save do

    # Ensure we reference a client for their address. (Defaults to assume client is using his own address)
    # (This should not be confused with client_addresses or address_clients!)
    self.address_client ||= self

    # Re-concatenate fullname string:
    self.fullname = self.fullname
    
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
    self.source_id ||= self.original_source_id

    # Recalculate client total_spend:
    self.update_total_spend
    
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
  
  
  # Hack to apply countries of interest from Client form:
  # For some reason the standard "accepts_ids_for :countries" was failing and preventing client form saving
  def countries_ids=(ids)
    
    if ids
      self.client_interests.destroy! unless self.new? # TODO: Find a better way that only empties the collection instead of deleting records
      ids.each do |id|
        self.client_interests.new( :country_id => id )
      end
    end
    
  end


  # Safer alternative to the DESTROY method. (Updates the deleted_at field without actually destroying the row)
  # We could have used the ParanoidDateTime to do this automatically but that would prevent the normal queries from finding deleted rows without employing the extra "with_deleted" method.
  # More info at http://datamapper.org/docs/misc and http://blog.hez.ca/entries/photo/datamapper-paranoid-delete-quirks
  def archive( archived_by = nil )

    self.deleted_at = DateTime.now
    self.deleted_by = archived_by if archived_by
    
    return self.save

  end

  # Safer alternative to the DESTROY! method. (Updates the deleted_at field without actually destroying the row)
  def archive!( archived_by = nil )

    self.deleted_at = DateTime.now
    self.deleted_by = archived_by if archived_by
    
    return self.save!
    
  end

  # Helper for identifying "deleted" clients:
  def archived?
    return self.deleted_at != nil
  end


  # On ARCHIVE, remove this client from the keyword search table:
  after :archive,  :refresh_search_keywords
  after :archive!, :refresh_search_keywords


  attr_accessor :search_results_trips
	attr_accessor :search_results_address
    

	
  # Accessors for the client's current active ADDRESS:
  # Note how we cache @primary_address to prevent unecessary db trips as each address line is accessed:
  # Also, in the situation where a *new* client's attributes are being set, there will be no client_address mapping yet.
  def primary_address
    
    return @primary_address if @primary_address
    primary_mapping    = self.client_addresses.first( :is_active => true )
    @primary_address ||= primary_mapping && primary_mapping.address
    return @primary_address || ( self.new? && self.addresses.first ) || nil

		#return @primary_address ||= self.addresses.first( ClientAddress.is_active => true ) || ( self.new? && self.addresses.first ) || nil
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
		return self.primary_address && self.primary_address.id
	end

  # SETTER to make one of the client_addresses primary. (Used by the addresses form)
  # (The tests for blank & new just prevent accidentally submitted attribute from causing errors)
  # Important: Syntax could be simpler but this approach queries unsaved data instead of querying sql only.
	def primary_address_id=(id)

    @new_primary_address_id = id

    unless id.blank? || self.new? || self.client_addresses.all( :address_id => id ).empty?

	    self.client_addresses.each{ |a| puts a.inspect, a.is_active = (a.address_id == id.to_i) }.save!

      active           = self.client_addresses.first( :is_active => true )
      @primary_address = active.nil? ? nil : active.address

    end
    
  end

  alias address             primary_address
  alias address=            primary_address=
  alias active_address_id   primary_address_id    # TODO: Depricate this.
  #alias active_address_id=  primary_address_id=   # TODO: Depricate this.

  def initial
    return self.forename.blank? ? '' : self.forename.chars.first
  end
  
  def short_name()
    initial_prefix = self.forename.blank? ? '' : "#{ self.forename.chars.first } " # Initial followed by a space
    return "#{ initial_prefix }#{ self.name }"
  end
  
  
	# primary_address.country:
  def country
		return self.primary_address && self.primary_address.country
  end


  # Generate accessor methods for the attributes of the active address:
  %w[ address1 address2 address3 address4 address5 address6 postcode country_id tel_home fax_home ].each do |attr_name|
    define_method attr_name do
      return self.primary_address ? self.primary_address[attr_name.to_sym] : ''
    end
  end
	
  # All clients who are on trips with this client: (AKA Fellow travellers)
  def companions( trip_type_ids = [ TripType::TAILOR_MADE, TripType::PRIVATE_GROUP ] )
		return Client.all( Client.trips.id => self.trips_ids, Client.trips.type_id => trip_type_ids, :id.not => self.id )
  end


  # All clients who share an address with this client: (AKA Fellow dwellers)
  # IS THIS USED? Can we deprecate it?
  def cohabiters
    #return Client.all( :address_client_id => address_client.id, :address_client_id.not => nil, :id.not => id )
    return Client.all( :conditions => ["id != ? AND ( address_client_id = ? OR address_client_id = ? )", self.id, self.id, self.address_client.id.to_i ] )
  end

  
  # All other clients who share an address with this client: (AKA Fellow dwellers)
  def housemates( address_id = nil )
    address_id ||= self.addresses.map{|a|a.id}
    return Client.all( Client.client_addresses.address_id => address_id, :id.not => self.id )
  end

  
  # All clients (including self) who share addresses with this client: (AKA Fellow dwellers)
  def households( address_ids = nil )
    address_ids ||=  self.addresses.map{|a|a.id}
    return Client.all( Client.client_addresses.address_id => address_ids )
  end

  
  # Combined total_spend of everyone who shares same addresses:
  # Should be same as self.households.sum(:total_spend) but that seems to add up duplicates :(
  def households_total_spend( address_ids = nil )
    return self.households(address_ids).map{|c|c.total_spend}.inject(:+) || 0
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
    return @active_trips ||= self.trips.all( :is_active_version => true, :type_id.not => TripType::TOUR_TEMPLATE )
  end

  def fixed_deps( tour_id = nil )
    deps = self.active_trips.all( :type_id => TripType::FIXED_DEP )
    return tour_id ? deps.all( :tour_id => tour_id ) : deps
  end

  def booked_trips
    return self.active_trips.all( :status_id => [ TripStatus::CONFIRMED, TripStatus::COMPLETED ] )
  end

  # Helper for listing group templates that the client has joined:
  def tour_templates
    return self.trips.all( :is_active_version => true, :type_id => TripType::TOUR_TEMPLATE )
  end

  # Used in reports:
  def booked_trips_count
    return self.booked_trips.count
  end

  def trip_versions_count
    return self.trips.count
  end

  def active_trips_count
    return self.active_trips.count
  end

  alias trips_count active_trips_count

  # Used in reports:
  def companies_names
    return self.companies.map{|c|c.name}.join(', ')
  end

  # Used in reports:
  def companies_initials
    return self.companies.map{|c|c.initials}.join(', ')
  end
    
  # Used in reports:
  def invoice_total
    return self.money_ins.sum(:amount)
  end
  	
  # Used in reports:
  def invoice_first_date
    return self.money_ins.min(:created_at)
  end
    
  # Used in reports: DEPRECATED. Use brochure_last_generated_date instead
  def brochure_last_date
    return self.brochure_requests.max(:generated_date)
  end

  # Used in reports:
  def brochure_last_generated_date
    return self.brochure_requests.max(:generated_date)
  end

  # Used in reports:
  def brochure_last_requested_date
    return self.brochure_requests.max(:requested_date)
  end
  
  


  # Helper to identify clients that have only just been added to the database:
  def created_today?
    self.new? || ( self.created_at && self.created_at.jd == Date.today.jd ) || false
  end


  # Recalculate total_spend by adding up all invoice totals:
  def update_total_spend
    self.total_spend = self.money_ins.sum(:amount) || 0   # Allow for sum returns nil when there are no items.
  end

  # Recalculate and SAVE total_spend by adding up all invoice totals:
  def update_total_spend!
    self.update_total_spend()
    self.save!
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
    do_delete = ( self.deleted_at != nil )
		Client.refresh_search_keywords( self.id, do_delete )
  end

  
  # Helper to copy name and address from another client: (Useful when initialising companion client)
  def copy_companion_details_from( client_id )

    #attributes_to_copy = [:name, :salutation, :addressee, :known_as, :tel_work, :fax_work, :tel_mobile, :tel_mobile2, :email1, :email2]
    attributes_to_copy  = [:name]
    master              = Client.get(client_id)

    unless master.nil?

      attributes        = master.attributes.reject{ |attr,val| !attributes_to_copy.include? attr }
      self.attributes   = attributes

      # Copy each of the master client's addresses to the new client: (So they share same address id reference)
      master.client_addresses.each do |addr|
        self.client_addresses << ClientAddress.new(
          #:address		=> Address.new( addr.address.attributes.reject{ |attr,val| attr == :id } )
          :address    => addr.address,
          :is_active	=> addr.is_active
        )
      end

      # Default copied client to NO MARKETING and original_source to COMPANION:
      self.marketing_id      = 0
      self.original_source ||= ClientSource.first( :name => 'Companion' ) || master.original_source
      self.source          ||= self.original_source

    end

  end

  
  def initialize(*)
    super
    @auto_refresh_search_keywords_after_save ||= true
  end






# Class methods:


  # Helper to instruct database to rebuild search data for one or all clients:
  # Warning: Takes longer when client_id not specified! (Though usually less than 10 seconds)
  def self.refresh_search_keywords( client_id = nil, do_delete = nil )

    do_delete = nil if client_id == nil

    if do_delete
      Merb.logger.info "Deleting client_keywords for client_id #{ client_id }"
    else
      Merb.logger.info "Refreshing client_keywords table for client_id #{ client_id || 'all'  }"
    end

		sql_statement = "EXEC usp_client_keywords_refresh ?, ?"
		repository(:default).adapter.execute( sql_statement, client_id, do_delete )
    
  end
  

  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Client'
  end
  
  # Define which properties are available in reports  
  def self.potential_report_fields

    # WARNING: We don't include :trips here because TripsCount would conflict with our custom :trips_count!

    return [ :id, :name, :title, :forename, :addressee, :salutation, :birth_date, :age, :tel_work, :fax_work, :tel_mobile1, :tel_mobile2, :email1, :email2, :original_source, :source, :companies_names, :companies_initials, :client_type, :areas_of_interest, :original_company, :money_ins, :address1, :address2, :address3, :address4, :address5, :postcode, :country_name, :mailing_zone_name, :created_at, 

      # ...and the following are special custom methods especially for reports:
      :booked_trips_count, :trips_count, :trip_versions_count, :invoice_total, :invoice_first_date, :marketing_summary, :marketing_summary_email, :marketing_summary_postal,
      :brochure_last_generated_date, :brochure_last_requested_date,

      :brochure_last_date # is deprecated. Use :brochure_last_generated_date instead.
      # :marketing        # is deprecated. Use :marketing_summary (marketing divisions) instead.

    ]

  end



  # Helper to trigger creation of a VirtualCabinet Command File for this user: (For CLIENT only, not a GROUP TOUR)
  # def open_virtual_cabinet( user, trip_id = nil )
  #   return VirtualCabinet.create user, self, trip_id
  # end




# Private methods:

private

  # Helper to list all DIVISIONS for which the client allows EMAIL marketing:
  def marketing_divisions_email( text_when_none = 'None' )
    
    return self.client_marketing_divisions.select{|m| m.allow_email }.map{|m| m.division.name }
    
  end

  # Helper to list all DIVISIONS for which the client allows POSTAL marketing:
  def marketing_divisions_postal( text_when_none = 'None' )
    
    return self.client_marketing_divisions.select{|m| m.allow_postal }.map{|m| m.division.name }
    
  end



end


			
