require "dm-accepts_nested_attributes"
require "ostruct"	#OpenStruct

class Trip
  include DataMapper::Resource 
    
    # TripState constants duplicated here for readability: (Eg @trip.status_id = Trip::UNCONFIRMED or TripState::UNCONFIRMED)  
    UNCONFIRMED = TripState::UNCONFIRMED    unless defined? UNCONFIRMED
    CONFIRMED   = TripState::CONFIRMED      unless defined? CONFIRMED
    COMPLETED   = TripState::COMPLETED      unless defined? COMPLETED
    ABANDONNED  = TripState::ABANDONED      unless defined? ABANDONED
    CANCELLED   = TripState::CANCELLED      unless defined? CANCELLED
    
    # TripType constants duplicated here for readability:
    TAILOR_MADE   = TripType::TAILOR_MADE   unless defined? TAILOR_MADE     # Most common trip type.
    PRIVATE_GROUP = TripType::PRIVATE_GROUP unless defined? PRIVATE_GROUP   # TODO: Depricate this because TAILOR_MADE trip can do the job.
    TOUR_TEMPLATE = TripType::TOUR_TEMPLATE unless defined? TOUR_TEMPLATE   # Trip must have a tour id.
    FIXED_DEP     = TripType::FIXED_DEP     unless defined? FIXED_DEP       # Trip must have a tour id.
    
    
    property :id,                         Serial    # Important: trip.id was migrated from ItineraryHeaderID in old database.
    property :name,                       String,   :length => 100, :required => true, :default => lambda{ |trip,prop| trip.tour ? "New dates for #{ trip.tour.name }" : 'A lovely new trip' }
    property :version,                    Integer,  :default => 1
    #property :version_name,              String,   :default => "New version"
    #property :activeTripId,              Integer,  :required => true   # FK to trip.id. Only one version can be active per trip.
    
    # Self-referencing FK for activeTrip:
    # So trip.version_of_trip.name returns the original title of any trip (the first version).
    property    :version_of_trip_id,      Integer,  :default => 0 # Warning: This is also updated by an sql trigger! (trg_trips_version_of_trip_id)
    
    property :is_active_version,	        Boolean,	:default => true      # Only one version can be active per trip.
    property :is_version_snapshot,        Boolean,	:default => false     # When true this version becomes read only.
    property :start_date,					        Date,			:default => lambda{ |trip,prop| Date.today },       :required => true
    property :end_date,						        Date,			:default => lambda{ |trip,prop| Date.today + 10 },  :required => true
    
    property :adults,							        Integer,	:default => 1
    property :children,						        Integer,	:default => 0
    property :infants,						        Integer,	:default => 0
    property :singles,						        Integer,	:default => 0
    alias single_supps singles
    
    # Price per person: (entered on the trip_element form)
    property :price_per_adult,		        Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    property :price_per_child,		        Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    property :price_per_infant,		        Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    property :price_per_adult_biz_supp,		Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    property :price_per_child_biz_supp,		Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    property :price_per_infant_biz_supp,	Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    property :price_per_single_supp,		  Decimal, :default	=> 0,		:precision=> 9, :scale	=> 2
    
    property :type_id,						        Integer,	  :default  => TripType::TAILOR_MADE, :required => true
    property :status_id,					        Integer,	  :default  => TripState::UNCONFIRMED	  # 1=Unconfirmed, 2=Confirmed, 3=Completed, 4=Abandonned, 5=Canceled
    property :deleted,						        Boolean,	  :default  => false
    property :tour_id,						        Integer,	  :required => false        # Only required when type_id = TOUR_TEMPLATE
    
    property :total_price,				        Integer,	:default => 0               # Rather important!
    
    # Helper for calculating total net including everything: (in sterling)
    def total_cost
      return self.calc( :total, :actual, :net, :for_all, :travellers, :with_all_extras => true, :string_format => false )
    end
    alias total_net   total_cost
    
    alias total_gross total_price
    alias total_spend total_price         # <-- Support for depricated property
    
    # Dummy property aliases to ensure generic method calls in trip.calc() have something to call:
    def return_zero(*); return 0.0; end
    alias price_per_single            price_per_single_supp
    alias price_per_single=           price_per_single_supp=
    alias price_per_single_biz_supp   return_zero
    alias price_per_single_biz_supp=  return_zero
    #def price_per_single_biz_supp;    return 0.0; end
    #def price_per_single_biz_supp=(); return 0.0; end
    
    has n, :documents
    has n, :trip_elements #, :constraint => :destroy  # See: http://github.com/datamapper/dm-constraints
    alias elements trip_elements
    
    has n, :trip_clients
    has n, :clients,    :through => :trip_clients
    
    has n, :trip_countries
    has n, :countries,  :through => :trip_countries
    
    has n, :trip_pnrs
    has n, :pnrs,       :through => :trip_pnrs
    
    has n, :money_ins         # AKA Invoices
    has n, :money_outs        # AKA SupplierPaymentRequests

    belongs_to  :version_of_trip,  :model => "Trip",:child_key => [:version_of_trip_id]
    has n,      :version_of_trips, :model => "Trip",:child_key => [:version_of_trip_id] #, :via => :version_of_trip
    alias orig_version_of_trip version_of_trip
    def version_of_trip; return self.orig_version_of_trip || self; end  # Allow for trips with missing version_of_trip
    
    belongs_to :tour 		      # Only applies when this trip.type is TOUR_TEMPLATE or FIXED_DEP.
    belongs_to :user 		      # Handled by / Prepared by.
    belongs_to :company		    # Handled by / Cost centre / Invoice to.
    belongs_to :type,   :model => "TripType",  :child_key => [:type_id]			# 1=Tailor made
    belongs_to :status, :model => "TripState", :child_key => [:status_id]   # 1=Unconfirmed, 2=Confirmed, 3=complete, 4=Canceled, 5=Abandonned.
    #belongs_to :tripPackage	  # Formerly known as Group Title etc .
    
    property :created_at, Date
    property :created_by, String, :default => ''
    property :updated_at, Date
    property :updated_by, String, :default => ''

    # See http://github.com/snusnu/dm-accepts_nested_attributes
    accepts_nested_attributes_for :clients        # Only used for confirming client source on new trips.
    accepts_nested_attributes_for :countries      # trip destinations
    accepts_nested_attributes_for :trip_countries # trip destinations
    accepts_nested_attributes_for :trip_clients,  :allow_destroy => true
    accepts_nested_attributes_for :trip_elements, :allow_destroy => true
    
    # Handlers for has n through associations: 
    accepts_ids_for :clients		        # ONLY used for providing a clients_names attribute, not for receiving clients_ids!
    accepts_ids_for :countries			    # Country IDs are accessed via trip.countries_ids
    accepts_ids_for :pnrs						    # Pnr numbers are accessed via trip.pnrs_names (or pnr_numbers alias)
    
    # This flag can be used to derive new dates for every element when trip start_date is changed:
    # (So an element that was on day5 will be adjusted accordingly to remain on day5 after the new start_date)
    attr_accessor :auto_update_elements_dates
    
    attr_accessor :do_copy_trip_id         # Specify a trip to copy details from.
    attr_accessor :do_copy_trip_clients    # Allows clients to be copied from another trip.      Use with do_copy_trip_id.
    attr_accessor :do_copy_trip_elements   # Allows elements to be cloned from another trip.     Use with do_copy_trip_id.
    attr_accessor :do_copy_trip_itinerary  # Allows elements etc to be cloned from another trip. Use with do_copy_trip_id.
    attr_accessor :do_copy_trip_countries  # Allows countries to be copied from another trip.    Use with do_copy_trip_id.
    attr_accessor :do_link_to_master       # When set, elements in the copied trip will be bound to the original. Use with do_copy_trip_id when creating a Fixed Dep from a Group Template.
    
    attr_accessor :debug


    # This fix is redundant because trip.start/end_date are Date properties not DateTime
    #  # Ugly workaround for the way datamapper returns datetime properties!
    #  # See _shared.rb: Helper for ensuring datamapper does not mess up datetime fields by returning them with +1 hour offset!
    #  # TODO: Look out for a better solution.
    #  alias raw_start_date start_date
    #  alias raw_end_date   end_date
    #  def start_date; get_datetime_property_of( self, :start_date ); end
    #  def end_date;   get_datetime_property_of( self, :end_date   ); end
    
    # Alas validations on date fields never seem to work!
    #	validates_with_block :end_date do
    #		return [ false, 'pants' ] if self.end_date < self.start_date
    #		true
    #	end
    
    # TODO!
    #validates_absence_of  :tour_id, :if => Proc.new{ |trip| trip.type_id != TOUR_TEMPLATE }
    #validates_presence_of :tour_id, :if => Proc.new{ |trip| trip.type_id == TOUR_TEMPLATE }


    # Require user to confirm client source when creating a new private trip:
    validates_with_method :check_client_source_on_new_trip, :if => lambda{|t| t.new? && ( t.tailor_made? || t.private_group? ) }


    
    # OVERRIDE standard save method to workaround a bug where save! has no effect inside the "after :save" hook
    # Call super to run save as normal then ensure the version_of_trip_ is set to to self:
    def save
      
      saved_as_normal = super
      
      if saved_as_normal && self.version_of_trip_id.to_i == 0 && self.id.to_i > 0
        self.version_of_trip_id = self.id
        saved_special = self.save!
        #self.dirty? = false if saved_special
        return saved_special
      end
      
      return saved_as_normal
      
    end
    

    before :valid? do

      # Convert blank string to nil on fields that expect IDs:
      self.user_id    = nil if self.user_id.blank?
      self.type_id    = nil if self.type_id.blank?
      self.company_id = nil if self.company_id.blank?
      
      self.name								||= "Untitled trip"
      self.status_id					||= Trip::UNCONFIRMED
      self.tour_id              = nil if self.tour_id.to_i == 0
      self.type_id              = TripType::TOUR_TEMPLATE if self.tour && !self.fixed_dep? && !self.tour_template?
      self.version_of_trip_id ||= 0	# Cannot be nil. If zero, this will be set to the trip's own new id after save.

      # Swap start and end dates if start date is later than end date:
      # Beware! Setting start/end_date here is a workaround for when they've not been submitted as part of the form
      # and the update methods decides to overwrite them with their defaulv values!
      #self.start_date = self.start_date || Date.today
      #self.end_date   = self.end_date   || Date.today + 10
      if self.start_date > self.end_date
        self.start_date, self.end_date = self.end_date, self.start_date
      end

    end

    
    before :create do
      
      # Ensure both created_by and updated_by are set if only one was specified:
      self.created_by = self.updated_by if self.created_by.blank?
      self.updated_by = self.created_by if self.updated_by.blank?
      
    end
    
    
    before :save do
      
      # Ensure existing trip refers to itself if missing version_of_trip:
      self.version_of_trip_id = self.id if self.version_of_trip_id.to_i == 0 && self.id.to_i > 0
      
      # 
      self.is_active_version = true if @new_active_version_id && @new_active_version_id == self.id
      
      # Copy details from another trip if required:
      # Warning: Relying on this hook can cause save to fail if copied elements are invalid.
      # Note: This clears the do_copy_trip_xxxx flags to prevent copies from being created again accidentally.
      self.do_copy_trip if self.do_copy_trip_id
      
      # Adjust every element's start_date to allow for a new trip.start_date
      self.update_elements_dates if self.auto_update_elements_dates === true || self.auto_update_elements_dates.to_s.to_i > 0


      # Ensure all trip elements still have valid numbers of adults/children/infants
      # (Also see TripElement before :save)
      # TODO: Handle subgroups?
      self.trip_elements.each do |elem|
        
        elem.adults   = self.adults   if elem.adults   != self.adults  
        elem.children = self.children if elem.children != self.children
        elem.infants  = self.infants  if elem.infants  != self.infants 
        elem.singles  = self.singles  # <-- TODO: Get unit tests to work with this.
        #elem.save!      if elem.dirty? #&& !elem.new? && !elem.destroyed? && elem.valid? && elem.supplier_id
          
      end
    
      # Recalculate and set price_per_xxx and total_price attributes:
      # This also calls calc_total_price() for us.
      # Only where price pp is currently zero because we must not override prices set manually in costing sheet!
      # Also see notes in trip_elements#update controller action regarding before/after:save hooks.
      self.update_prices
      
      # TODO: Make this work: (Intended to detect when pnr numbers have been changed so we can speed up trip save)
      @pnr_numbers_have_changed     ||= self.pnrs.dirty? || self.trip_pnrs.dirty?
      @orig_pnr_numbers_before_save   = self.pnr_numbers
      
    end
      
    
    after :save do
      
      #unless ( @avoid_triggering_after_save_hook_recursively ||= false )
      @avoid_triggering_after_save_hook_recursively = true
      

      # Workaround: See overidden save method above. We should be able to call save! here but it has does nothing. :(
      # Set version_of_trip_id to self if not already set: (Note we tried "self.activeTrip ||= self" but it caused recursive "stack level too deep" error)
      # Aug 2010 GA: Retired the sqltrigger and rely on this instead: (See comments near end of this class)
      #  if self.version_of_trip_id.to_i == 0 && self.id.to_i > 0
      #    self.version_of_trip_id = self.id
      #    self.save!
      #  end
      
      # If necessary, update the "is_active_version" flag on all other versions of same trip:
      if self.is_active_version || ( (@new_active_version_id ||= nil) && @new_active_version_id == self.id )
      
        self.make_other_versions_inactive!
        
      elsif @new_active_version_id && ( active_version = self.versions.get(@new_active_version_id) )
        
        # Ensure the chosen active_version is updated:
        active_version.update!( :is_active_version => true )
        active_version.make_other_versions_inactive!
        
      end
      @new_active_version_id = nil
      
      # Moved to before:save
      # Ensure all trip elements still have valid numbers of adults/children/infants
      # (Also see TripElement before :save)
      # TODO: Handle subgroups?
      #  self.trip_elements.each do |elem|
      #    
      #    elem.adults   = self.adults
      #    elem.children = self.children
      #    elem.infants  = self.infants
      #    elem.save!      if elem.dirty? && !elem.new? && !elem.destroyed? && elem.valid?
      #    
      #  end
      
      # Override flag because it is not reliable:
      # TODO: Find a way to detect when pnr numbers have been changed
      @pnr_numbers_have_changed ||= ( self.pnr_numbers.sort != @orig_pnr_numbers_before_save.sort )
      
      # Ensure the trip_elements include all the flights identified by this trip's PNRs:
      # Create and/or delete flight elements if necessary!
      if @pnr_numbers_have_changed
        
        self.pnrs.each do |pnr|
          
          report = pnr.refresh_flight_elements_for(self)
          
          report[:errors].each_pair do |line_nos,err|
            self.errors.add :pnr_numbers, "#{ pnr.number } line #{ line_nos }: #{ err }"
          end
          
        end
        
        
        # As a catch all, DELETE any orphaned PNR flights that seem to be left behind by old PNRs!
        # This should not be necessary but situation did occur occasionally in test system.
        pnr_numbers = self.pnr_numbers
        self.flights.each do |f|
          
          unless f.pnr_number.blank? || pnr_numbers.include?(f.pnr_number) || f.new? || f.destroyed?
            
            Pnr.logger.info "Also deleting flight element #{ f.id } that seems to reference PNR #{ f.pnr_number } that is is longer assiged to the trip!" 
            f.destroy!
            
          end
          
        end
        
        
        # Refresh our change-tracking flags:
        @pnr_numbers_have_changed     = false
        @orig_pnr_numbers_before_save = self.pnr_numbers
        
      end
      
      
      # Create flight followups if the trip is now confirmed:
      # Note: Followups will not be created again if they already exist.
      if self.confirmed?
        self.flights.each{ |flight| flight.create_task() }
      end
      
      
      @avoid_triggering_after_save_hook_recursively = false
      
      #end
      
    end
    
    
    after :destroy do
      
      if self == self.version_of_trip
        
        # TODO: Also delete all versions of this trip!
        
      elsif self.is_active_version
        
        # Make the original version the active version:
        self.version_of_trip.update!( :is_active_version => true )
        self.version_of_trip.make_other_versions_inactive!
        
      end
      
      # Delete associated trip_elements too:
      TripElement.all( :trip_id => self.id ).destroy
      
    end
    
    
    
    # Derived properties and helpers...
    
    def leaders;			return self.clients.all( Client.trip_clients.trip_id	=> self.id, Client.trip_clients.is_leader			=> true ); end
    def invoicables;	return self.clients.all( Client.trip_clients.trip_id	=> self.id, Client.trip_clients.is_invoicable	=> true ); end

    def primaries

      primaries = self.clients.all( Client.trip_clients.is_primary => true )

      # Attempt to correct trip with no primary client!
      if primaries.empty? && ( first_trip_client = self.trip_clients.first( :order => [:id] ) )
        first_trip_client.is_primary = true
        first_trip_client.save! unless self.new?
        primaries.reload        unless self.new?
      end

      return primaries

    end
    
    #def secondaries
    #  return self.clients.all( TripClient.is_primary => false )
    #end

    def flights;	return self.trip_elements.all( :type_id => TripElement::FLIGHT,  :order => [:start_date, :id] ); end
    def handlers; return self.trip_elements.all( :type_id => TripElement::HANDLER, :order => [:start_date, :id] ); end	# AKA Flight agents
    def accomms;	return self.trip_elements.all( :type_id => TripElement::ACCOMM,  :order => [:start_date, :id] ); end
    def grounds;	return self.trip_elements.all( :type_id => TripElement::GROUND,  :order => [:start_date, :id] ); end
    def miscs;		return self.trip_elements.all( :type_id => TripElement::MISC,    :order => [:start_date, :id] ); end
    
    # TODO!
    def booking_ref
      return self.version_of_trip_id || self.id
    end
    
    # DEPRICATED:
    # Calculate duration of trip in days: (When overrun is true, we include any trip elements that are not within trip dates!)
    def duration(overrun = false)
      if overrun || overrun == :with_overrun
        return ( self.last_element.end_date.jd - self.first_element.start_date.jd ) + 1
      else
        return ( self.end_date.jd - self.start_date.jd ) + 1
      end
    end
    
    
    # Return array of simple "day" hashes each containing useful info about elements etc on that day:
    def days(overrun = false)
      
      overrun		||= (overrun == :with_overrun)  # True to include elements that lie outside trip dates.
      result			= []
      first_date	= overrun ? self.first_element.start_date.to_date : self.start_date
      last_date		= overrun ? self.last_element.start_date.to_date  : self.end_date
      total_days	= last_date.jd - first_date.jd + 1		# jd returns julian date number
      
      # Dummy loop to encourage datamapper to load all the trip_elements: (Thereby preventing multiple queries later)
      # TODO: Try another technique. This is not preventing dm from querying for each day!
      trip_elements = self.trip_elements.all.each{ |elem| x = elem.description }
      
      # Build a hash to represent each day and add them to the result array:
      total_days.times do |i|
        
        date = first_date + i
        
        elements = trip_elements.all(
          
          :start_date.lt	=> date + 1,	# Elements beginning on or before date.
          :end_date.gte		=> date,	# Elements ending on or after date.
          :order					=> [:type_id, :start_date, :id]
          
          # Special clause to exclude the checkout day of accommodation elements otherwise we see an extra day for each:
          # Except where check out day is same as check-in day because it's probably a day-room.
          # (Note: We use SQL FLOOR to compare on dates only, excluding the time just in case it varies)
          #:conditions			=> [ "NOT ( trip_elements.type_id = #{ TripElement::ACCOMM } AND CAST(FLOOR(CAST( trip_elements.end_date AS float)) AS datetime) = ? AND FLOOR(CAST( trip_elements.start_date AS float)) < FLOOR(CAST( trip_elements.end_date AS float)) )", date ]
          
        )
        
        elements.each do |elem|
          elements.delete(elem) if elem.accomm? && elem.end_date.jd == date.jd && elem.start_date.jd < elem.end_date.jd
        end
        # For some reason this equivalent delete_if syntax did not work:
        #	elements.delete_if{ |elem|
        #		return elem.type_id == TripElement::ACCOMM && elem.end_date.jd == date.jd && elem.start_date.jd < elem.end_date.jd
        #	}
        
        
        # Create a hash-like object to represent a day: (An OpenStruct is like a hash but can be accessed using day.date instead of day[:date] )
        day = OpenStruct.new(
          :number		=> i + 1,
          :date			=> date,
          :percent	=> 100 * i / total_days,		# Percentage through entire trip.
          :elements	=> elements.all,
          :flights	=> elements.all( :type_id => TripElement::FLIGHT ),
          :agents		=> elements.all( :type_id => TripElement::HANDLER ),
          :accomms	=> elements.all( :type_id => TripElement::ACCOMM ),
          :grounds	=> elements.all( :type_id => TripElement::GROUND ),
          :miscs		=> elements.all( :type_id => TripElement::MISC )
        )
        
        result << day 
        
      end
      
      return result
      
    end
    
    
    # Alias for trip.days(true) (Number of days including trip_elements falling outside trip dates)
    def days_overrun;		return self.days(true); end
    
    # Handy shortcuts for common attributes:
    def tailor_made?;   return self.type_id   == TripType::TAILOR_MADE;   end
    def private_group?; return self.type_id   == TripType::PRIVATE_GROUP; end
    def tour_template?; return self.type_id   == TripType::TOUR_TEMPLATE; end
    def fixed_dep?;     return self.type_id   == TripType::FIXED_DEP;     end
    def unconfirmed?;   return self.status_id == TripState::UNCONFIRMED;  end
    def confirmed?;     return self.status_id == TripState::CONFIRMED;    end
    def completed?;     return self.status_id == TripState::COMPLETED;    end
    def abandonned?;    return self.status_id == TripState::ABANDONED;    end
    def cancelled?;     return self.status_id == TripState::CANCELLED;    end
    def year;						return self.start_date.strftime("%Y"); end
    def month;					return self.start_date.strftime("%b %Y"); end
    def travellers;			return self.adults.to_i + self.children.to_i + self.infants.to_i; end
    def travellers?;		return self.travellers    > 0; end
    def adults?;				return self.adults.to_i   > 0; end
    def children?;			return self.children.to_i > 0; end
    def infants?;				return self.infants.to_i  > 0; end
    def singles?;				return self.singles.to_i  > 0; end
    
    def is_first_version; return self.version_of_trip_id == self.id || self.id.nil?; end  # AKA The ORIGINAL trip version.
    def version_name;		  return self.is_first_version ? "Original version: #{ self.name }" : self.name; end
    
    # Shortcut for get/setting name of the ORIGINAL trip version:
    def title;            ( self.version_of_trip ||= self ).name; end
    def title=(new_name); ( self.version_of_trip ||= self ).name = new_name; end
    
    alias pax                   travellers
    alias version_of_trip_name	title
    alias first_version_name		title
    alias first_version					version_of_trip
    
    # Helper to return a string of client names: (Used in reports)
    def primary_clients_names

      return self.primaries.map{|c| "#{ c.fullname } #{ c.postcode }" }.join(', ')

    end


    def total_margin_percent
      return self.calc( :total, :actual, :percent_margin, :for_all, :travellers, :with_all_extras => true, :final_prices => true, :decimal_places => 1 ) + '%'
    end

	
	  # Helper to return total of all invoices and credits etc: (Used in reports. Name is consistent with TotalPrice etc)
	  def total_invoiced
		  return self.money_ins.sum(:amount) || 0
	  end
  	
	  # Helper to return the earliest trip invoice date: (Used in reports)
	  def invoice_first_date
		  return self.money_ins.min(:created_at)
	  end
	

	  # Helper to return the trip type because reports don't seem to handle trip.type.name automatically: (Used in reports)
    def type_name
      return self.type.name
    end

	
    # Helper to fetch trips that are linked to this trip.
    # By default this only returns the active_version of each trip.
    def slave_trips( include_inactive_versions = false )

      master_elem_ids = self.trip_elements.map{|elem| elem.id }
      slaves          = Trip.all( Trip.trip_elements.master_trip_element_id => master_elem_ids )
      slaves          = slaves.all( :is_active_version => true ) unless include_inactive_versions
      
      return slaves
      
    end
    
    # Helper to return the Group Trip that this trip's elements are linked to:
    # TODO: Store master_trip_id in the database because this will be useless if master trip has no elements!
    def master_trip
      
      slave_element = self.trip_elements.first( :master_trip_element_id.gt => 0 )
      
      return slave_element && slave_element.master_element && slave_element.master_element.trip

    end


    # Helper to return a list of all versions of this trip:
    def versions
      return Trip.all( :version_of_trip_id => self.version_of_trip_id )
    end
    
    
    # Helper to return the active version from all trips that have the same version_of_trip_id:
    def active_version
      return self.versions.first( :is_active_version => true )
    end
    
    # Helper to set the active version amongst all trips that have the same version_of_trip_id:
    # Warning: This may run update! on self and all other versions:
    def active_version_id=(trip_id)
      if( @new_active_version_id = trip_id )
        self.is_active_version = ( @new_active_version_id == self.id ) 
      end
      #return ( version = self.versions.get(trip_id) ) && !version.is_active_version && version.become_active_version!
    end
    
    
    # Helper to set is_active_version on this trip, and unset is_active_version on the other versions:
    # Warning: This may call save! on self and all versions:
    def become_active_version!( save_self = false, save_others = true )
      
      self.is_active_version = true
      self.save! if save_self && self.dirty? && !self.new?
      self.make_other_versions_inactive! save_others

    end
    
    # Helper to unset the "is_active_version" flag on all other trips sharing the same version_of_trip_id:
    # Warning: This has does nothing if self has not been saved yet.
    def make_other_versions_inactive!( save_others = true )

      if self.is_active_version && self.version_of_trip_id && self.id
        other_versions = self.versions.all( :id.not => self.id ).each{ |v| v.is_active_version = false }
        other_versions.save! if save_others && !self.new?
        return other_versions
      end

    end
    
    # Friendly DSL method to fetch collection of specific types of money_in records:
    def invoices( invoice_type = :all )
      
      money_ins = self.money_ins( :order => [:id] )
      
      return case invoice_type
        
      when :all                     then money_ins
      when :main                    then money_ins( :is_deposit => false ).delete_if{ |inv| !inv.main_invoice? }
      when :supps,   :supplements   then money_ins( :is_deposit => false ).delete_if{ |inv| !inv.supplement? }
      when :credits, :credit_notes  then money_ins( :is_deposit => false ).delete_if{ |inv| !inv.credit_note? }
      when :deposits                then money_ins( :is_deposit => true  )
      else                               money_ins
      end
      
    end
    
    
    # Calculate the default date when invoice payment is due for this trip:
    def payment_due_date
      return self.company.due_days.days.until( self.start_date.to_time )
    end
    
    # Calculate standard deposit based on company.default_deposit and trip.total_price
    def default_deposit
      if self.company.default_deposit =~ /%$/
        self.total_price * ( self.company.default_deposit.to_i / 100 )
      else
        self.company.default_deposit.to_i * self.travellers
      end
    end
    
    
    
    # Calculate which trip_element starts first: (Arbitrarily choose one if several start on same date)
    def first_element
      return self.trip_elements.first( :order => [:start_date, :id] )
    end
    # Calculate which trip_element finishes last: (Arbitrarily choose one if several finish on same date)
    def last_element
      return self.trip_elements.first( :order => [:end_date.desc, :id.desc] )
    end
    alias earliest_element first_element  # Depricated.
    alias latest_element   last_element   # Depricated.
    
    
    # When the earliest element starts before the trip's start_date, calculate how many days out it is:
    def days_overrun_before
      result = self.start_date.jd - self.first_element.start_date.jd
      return result >= 0 ? result : 0
    end
    
    
    # When the latest element ends after the trip's end_date, calculate how many days out it is:
    def days_overrun_after
      result = self.last_element.end_date.jd - self.end_date.jd
      return result >= 0 ? result : 0
    end
    
    
    def date_summary
      # Eg: "Sun 4th May to Thu 5th Jun 2008"
      sameYear = (self.start_date.year == self.end_date.year ? '' : ' %Y')  # Only show start year when different.
      return self.start_date.strftime_ordinalized('%a %d %b' + sameYear) + " to " + self.end_date.strftime_ordinalized('%a %d %b %Y')
    end
    alias dateSummary date_summary	# Depricated
    
    
    def traveller_summary
      # Eg: "4 adults, 2 children, 1 infant"
      if self.travellers?
        return	(self.adults?   ?        "#{ self.adults   } adults"   : 'No adults!') +
                (self.children? ? ", " + "#{ self.children } children" : '') +
                (self.infants?  ? ", " + "#{ self.infants  } infants"  : '') +
                (self.singles?  ? ", " + "#{ self.singles  } singles"  : '')
      else
        return "No travellers!"
      end
    end
    alias client_summary traveller_summary
    alias travellerSummary traveller_summary	# Depricated
    

    # Return a readable summary of the trip_clients' statuses: (Eg: 1 Unconfirmed, 2 Waitlisted, 3 Confirmed)
    def client_status_summary

      return @client_status_summary ||= lambda{

        totals = {}
        lookup = cached(:trip_client_statuses_hash)

        # Count how many clients there are with each client_status:
        self.trip_clients.each do |trip_client|
          totals[trip_client.status_id] ||= 0
          totals[trip_client.status_id] +=  1
        end

        return totals.map{ |id,count| "#{ count } #{ lookup[id] }" }.join(', ')

      }.call

    end


    # Return a summary of the trip's dates, status and clients:
    def summary( include_client_statuses = false )
      client_statuses = ( include_client_statuses && !self.client_status_summary.blank? ) ? " (#{ self.client_status_summary })" : ''
      return "#{ self.date_summary } - #{ self.status_name } - #{ self.traveller_summary }#{ client_statuses }"
    end

    
    def country_names
      self.countries_names.join(', ')
    end
    
    
    # Helper to receive a list of PNR numbers and apply them as a list of PNR IDs instead:
    # Note: New/updated PNR data will be applied by the 'after :save' hook.
    def pnrs_names=( new_pnrs_names )
      
      # Convert argument to array if a csv string was provided:
      new_pnrs_names = new_pnrs_names.split(/[,\s]+/).compact() if new_pnrs_names.is_a?(String)
      
      @pnr_numbers_have_changed = ( new_pnrs_names.sort != self.pnrs_names.sort )
      
      # If new_pnrs_names list is different then use them to lookup a new list of pnrs_ids :
      if @pnr_numbers_have_changed
        
        new_pnrs_ids  = []
        Pnr.all( :name => new_pnrs_names ).each{ |pnr| new_pnrs_ids << pnr.id }
        self.pnrs_ids = new_pnrs_ids
        
      end
      
    end
    
    # Alias for the setter above and the getter generated dynamically by accepts_ids_for(:pnrs)
    alias pnr_numbers= pnrs_names=
    alias pnr_numbers  pnrs_names

    
    # Helper for returning the number of somethings...
    def count_of(something)
      
      return case something.to_sym
        when :travellers,   :traveller, :all, :person,  :persons, :people then self.travellers
        when :elements,     :element,   :trip_elements, :trip_element     then self.trip_elements.length
        when :adults,       :adult        then self.adults
        when :children,     :child        then self.children
        when :infants,      :infant       then self.infants
        when :singles,      :single       then self.singles
        when :primaries,    :primary      then self.primaries.length
        when :invoicables,  :invoicable   then self.invoicables.length
        when :flights,      :flight       then self.flights.length
        when :accomms,      :accomm       then self.accomms.length
        when :grounds,      :ground       then self.grounds.length
        when :miscs,        :misc         then self.miscs.length
        when :handlers,     :handler      then self.handlers.length
        else 0
      end
      
    end
    
    
    #  # DEPRICATED! Use trip.calc(...) instead.
    #  # Helper to calculate trip final prices, based on the price_per_xxx & price_per_xxx_biz_supp properties:
    #  def final_price( measure, per_or_all, person, options = {} )
    #    
    #    options       = Trip.clean_calc_options options.merge( :measure => measure, :per_or_all => per_or_all, :person => person ), self
    #    measure       = options[:measure]
    #    per_or_all    = options[:per_or_all]
    #    person        = options[:person]
    #    as_decimal    = options[:as_decimal].merge( :final_prices => false )
    #    result        = 0
    #    
    #    
    #    # Special calculation for percent_margin for all travellers:
    #    if person == :traveller && measure == :percent_margin
    #      
    #      net    = self.final_price( :net  , per_or_all, :travellers, as_decimal )
    #      gross  = self.final_price( :gross, per_or_all, :travellers, as_decimal )
    #      
    #      result = ( gross - net ) / gross * 100 unless gross.zero?
    #      
    #      
    #    # Special summing for all travellers:
    #    elsif person == :traveller
    #      
    #      # Sum for all persons: Eg: (:gross, :for_all, :adults) + (:gross, :for_all, :children) etc
    #      result = self.final_price( measure, per_or_all, :adults,   as_decimal ) + 
    #               self.final_price( measure, per_or_all, :children, as_decimal ) + 
    #               self.final_price( measure, per_or_all, :infants,  as_decimal ) + 
    #               self.final_price( measure, per_or_all, :singles,  as_decimal )
    #      
    #      
    #    # Otherwise do the standard calculations:
    #    else
    #      
    #      method_suffix = options[:biz_supp] ? '_biz_supp' : ''
    #      price_method  = "price_per_#{ person }#{ method_suffix }"
    #      
    #      net           = self.calc( 1, :actual, :net, :per, person, as_decimal ) unless measure == :gross
    #      
    #      # Fetch trip.price_per_xxx and add trip.price_per_xxx_biz_supp if required:
    #      gross         = self.method( price_method ).call || 0
    #      gross        += self.method( "price_per_#{ person }_biz_supp" ).call || 0 if options[:with_biz_supp]
    #      
    #      # Avoid attempts to calculate percent_margin when gross is zero!
    #      unless measure == :percent_margin && gross == 0
    #        
    #        # Fetch or calculate the net/gross/margin value:
    #        result = case measure
    #          when :net            then net
    #          when :gross          then gross
    #          when :margin         then gross - net
    #          when :percent_margin then ( gross - net ) / gross * 100 #100 - ( net / gross * 100 )
    #        end
    #        
    #        # Multiply by the number of adults or children or infants or singles:
    #        result *= self.count_of(person) if per_or_all == :all && measure != :percent_margin
    #        
    #      end
    #      
    #    end
    #    
    #    if options[:to_currency]
    #      currency_format = options[:to_currency] == true ? :generic : options[:to_currency]
    #      result.to_currency( currency_format )
    #    elsif options[:string_format]
    #      format( options[:string_format], result )
    #    else
    #      result
    #    end
    #    
    #  end
    
    
    
    
    # Special DSL method for calculating specific costs and prices. Used on the Costings Sheet a lot.
    # Note: Summing local currencies is a pointless effort unless all elements are in same currency.
    # Eg: trip.calc :daily, :local, :cost, :per, :adult
    # Arguments:
    # days        = :daily / :total (Depricated! Has no effect on results of trip.calc!)
    # currency    = :local / :actual (In practice :actual just means sterling)
    # measure     = :net / :gross / :margin / :percent_margin
    # per_or_all  = :per / :all / :for_all (:for_all is just an alias of :all to be more readable)
    # person      = :adult / :child / :infant / :single
    # options     = :biz_zupp / :with_biz_supp / :taxes / :with_taxes / :booking_fee / :with_booking_fee / :with_all_extras / (See clean_calc_options() for more!)
    # Note that :final_prices => true only applies to trip.calc(), it has no effect on trip_element.calc()
    # For debugging use :debug => true in the options to have them output to the console.
    def calc( days, currency, measure, per_or_all, person, options = { :for => :all_elements } )
      
      # Tidy up the options and assume defaults where necessary:
      result                  = nil
      #days                    = :daily  # Depricated. Override days argument because it has no effect on trip.calc.
      args                    = { :measure => measure, :per_or_all => per_or_all, :person => person }
      options                 = Trip.clean_calc_options options.merge(args), self
      options[:debug]         = true if self.debug
      
      measure                 = options[:measure]
      per_or_all              = options[:per_or_all]
      person                  = options[:person]
      persons                 = options[:persons]
      trip_elements           = options[:for]                     # :flights / :accomms / :grounds / :miscs / :trip_elements (This is used for a method call on the trip object)
      as_decimal              = options[:as_decimal]  
      options_and_as_decimal  = options[:options_and_as_decimal]  # Same as options, plus those required to return a decimal result instead of formatted string.
      
      # TODO: Find a better way to indent the debug messages:
      @@indent ||= ''
      #puts "#{@@indent} options for trip.calc() #{ options.inspect }" if ( options[:debug] )
      puts "#{@@indent} trip.calc( :#{days} :#{currency} :#{measure} :#{per_or_all} :#{person}) options:  #{ options.inspect }" if ( options[:debug] )
      @@indent << ' '
      
      
      # Notes: 
      # - When returning net we always return calculated net regardless of final_prices option.
      # - The with_taxes option is irrelevant when returning gross final_prices.
      # - days and currency are not relevant when calculations involve final_prices.
      
      # Delegate the task to a more specialised method if calculations must involve final prices:
      #   if options[:final_prices] && measure != :net
      #     result = self.final_price( measure,	per_or_all, person, as_decimal.merge( :final_prices => nil ) )
      #   end
      
      
      # Set result from the arguments if specified:
      # This allows result to be specified explicitly instead of calculating it. Not used much.
      result = options[:net]    if options[:net]    && measure == :net
      result = options[:gross]  if options[:gross]  && measure == :gross
      result = options[:margin] if options[:margin] && measure == :margin
      
      
      # Otherwise we must calculate result:
      unless result
        
        result = 0.0
        
        # Experimental. This condition is now at the end of the if-statement:
        #  # Return stored price_per_adult/child/infant/single:
        #  if measure == :gross && options[:final_prices] && person != :traveller
        #    
        #    if ( count_of_persons ||= self.count_of(persons) ) > 0
        #      
        #      # Derive method name for 'trip.price_per_xxx' or 'trip.price_per_xxx_biz_supp':
        #      price_method  = "price_per_#{ person }#{ options[:biz_supp] ? '_biz_supp' : '' }"
        #      
        #      # Ta-daa! The final price per person: (Either biz_supp or price pp excluding biz_supp)
        #      result = self.method( price_method ).call || 0
        #      
        #      # Add gross final BIZ_SUPP price to result if required:
        #      if options[:with_biz_supp] && !options[:biz_supp] && person != :single
        #        
        #        biz_supp_options = options_and_as_decimal.merge( :biz_supp => true, :with_biz_supp => false )
        #        result += self.calc( days, currency, :gross, per_or_all, person, biz_supp_options )
        #        
        #      end
        #      
        #      result *= count_of_persons if per_or_all == :all
        #      
        #    end
        
        
        # Calculate booking_fee only:
        if options[:booking_fee]
          
          # Booking fee is the same in both net and gross in this system, because we don't charge margin on it:
          if ( measure == :gross || measure == :net ) && person != :single
            
            result = ( per_or_all == :per ) ? self.booking_fee : self.booking_fees(persons)
            puts "#{@@indent} Booking fee: #{result} options: #{ options_and_as_decimal.inspect }" if ( options[:debug] )
            
          end
          
          
        # Calculate MARGIN amount or PERCENT_MARGIN:
        elsif measure == :margin || measure == :percent_margin
          
          exclude_non_marginables = { :with_taxes => false, :with_booking_fee => false }

          net    = self.calc( days, currency, :net,   per_or_all, person, options_and_as_decimal )
          gross  = self.calc( days, currency, :gross, per_or_all, person, options_and_as_decimal )
          margin = gross - net

          # BEWARE! Margin is the difference (profit) between net and gross but
          #         PERCENT-MARGIN is calculated using values that exclude taxes and booking-fee.
          if measure == :percent_margin

            #net    = self.calc( days, currency, :net,   per_or_all, person, options_and_as_decimal.merge(exclude_non_marginables) )
            #gross  = self.calc( days, currency, :gross, per_or_all, person, options_and_as_decimal.merge(exclude_non_marginables) )

            taxes       = self.calc( days, currency, :net,   per_or_all, person, :taxes       => true, :string_format => false )
            booking_fee = self.calc( days, currency, :net,   per_or_all, person, :booking_fee => true, :string_format => false )
 
            unless options[:biz_supp] || options[:single_supp]
              gross -= taxes
              gross -= booking_fee
            end

            result = margin / gross * 100 unless gross.zero?
            puts "#{@@indent} Percent_margin: #{result} (#{margin} / #{gross} * 100) options: #{ options.inspect }" if ( options[:debug] )

          else

            result = margin
            puts "#{@@indent} Margin: #{result} options: #{ options.inspect }" if ( options[:debug] )

          end
          
          
        # Derive total calculated NET / GROSS / MARGIN by summing the trip_elements:
        # Note that :net is always calculated, regardless of :final_prices.
        # Eg: trip.calc( :daily, :actual, :net, :for_all, :travellers, :with_all_extras => true )
        elsif measure == :net || !options[:final_prices]
          
          elems = self.method(trip_elements).call
          puts "#{@@indent} Sum #{ elems.length } trip elements:" if ( options[:debug] )
          puts "#{@@indent}  (No elements to sum)"                if ( options[:debug] ) && elems.empty?
          @@indent << ' '
          booking_fee_not_already_included = true
          
          elems.each do |elem|
            
            unless elem.destroyed?
              
              # Might as well save some effort by summing the pre-calculated fields whenever possible:
              if options[:with_all_extras] && measure == :net
                
                elem_calc = elem.total_net
                puts "#{@@indent} #{result} + #{elem_calc} = #{result+elem_calc} (Adding: elem.total_net)" if ( options[:debug] )
                
              elsif options[:with_all_extras] && measure == :gross
                
                elem_calc = elem.total_gross
                puts "#{@@indent} #{result} + #{elem_calc} = #{result+elem_calc} (Adding: elem.total_gross)" if ( options[:debug] )
                
              else
                
                elem_calc = elem.calc( :day, currency, measure, per_or_all, person, options_and_as_decimal )
                puts "#{@@indent} #{result} + #{elem_calc} = #{result+elem_calc} (Adding: elem.calc :day :#{currency} :#{measure} :#{per_or_all} :#{person}) options: #{ options_and_as_decimal.inspect }" if ( options[:debug] )
                booking_fee_not_already_included = true
                
              end
              
              result += elem_calc
              
            else
              puts "#{@@indent} (Ignoring deleted element)" if ( options[:debug] )
            end
            
          end
          
          puts "#{@@indent} Total of sum = #{ result }" if ( options[:debug] )
          @@indent.chop!
          
          # Removed this 23 Jun 2010 because it's already included in summed result:
          # Eg: Included when trip.calc( :daily, :actual, :cost,  :per, :adult, :with_all_extras => true )
          # Add file booking fee if required:
          if booking_fee_not_already_included && options[:with_booking_fee] && person != :single #&& per_or_all == :per
            
            booking_fee       = self.calc( days, currency, measure, :per, person, :booking_fee => true, :string_format => false )
            persons_multipler = per_or_all == :per ? 1 : self.count_of(persons)
            booking_fees      = booking_fee * persons_multipler
            result           += booking_fees
            
            puts "#{@@indent} #{ result - booking_fees } + #{ booking_fee }x#{ persons_multipler }#{persons} = #{ result } (Adding: elem.calc :#{days} :#{currency} :gross :per :#{person}) options: :booking_fee => true" if ( options[:debug] )
            
          end
          
          
        # Fetch GROSS FINAL PRICE for ALL PERSONS:
        # Note: This condition can only happen when options[:final_prices] is true.
        elsif measure == :gross && person == :traveller
          
          result_before = result
          
        result = \
          ( adult_gross  = self.calc( days, currency, :gross, per_or_all, :adult,  options_and_as_decimal ) ) +
          ( child_gross  = self.calc( days, currency, :gross, per_or_all, :child,  options_and_as_decimal ) ) +
          ( infant_gross = self.calc( days, currency, :gross, per_or_all, :infant, options_and_as_decimal ) ) +
          ( single_gross = self.calc( days, currency, :gross, per_or_all, :single, options_and_as_decimal ) )
          
          puts "#{@@indent} #{result_before} + #{adult_gross} + #{child_gross} + #{infant_gross} + #{single_gross} = #{result}" if ( options[:debug] )
          
          
        # Fetch GROSS FINAL PRICE for adult/child/infant/single:
        # Warning: This returns final price per child (for example) even when there are not children on the trip!
        # Note: This condition can only happen when options[:final_prices] is true and measure is not :gross.
        else
          
          if ( count_of_persons ||= self.count_of(persons) ) > 0
            
            # Derive method name for trip.price_per_xxx or trip.price_per_xxx_biz_supp:
            price_method  = "price_per_#{ person }#{ options[:biz_supp] ? '_biz_supp' : '' }"
            
            # Ta-daa! The final price per person: (Either price_per_person or price_per_person_biz_supp)
            result        = self.method( price_method ).call || 0
            
            puts "#{@@indent} #{price_method} = #{result}" if ( options[:debug] )
            
            # Add gross final BIZ_SUPP price to result if required:
            if options[:with_biz_supp] && !options[:biz_supp] && person != :single
              
              # Important: (Fixed 28 Jun 2010) Ignore per_or_all and get biz_supp PER person otherwise we risk multiplying twice!
              biz_supp_options = options_and_as_decimal.merge( :biz_supp => true, :with_biz_supp => false )
              biz_supp         = self.calc( days, currency, :gross, :per, person, biz_supp_options )
              result += biz_supp
              puts "#{@@indent} with_biz_supp: #{ result-biz_supp } + #{ biz_supp } = #{ result }" if ( options[:debug] )
              
            end
            
            result *= count_of_persons    if per_or_all == :all
            puts "#{@@indent} for_all: #{ result / count_of_persons } x #{ count_of_persons } = #{ result }" if ( options[:debug] ) && per_or_all == :all
            
          end
          
        end
        
      end
      
      #puts "#{@@indent} Result: #{ result }"
      @@indent.chop!
      
      # Format the result:
      return Trip.format_calc_result( result, options )
      
    end
    
    
    
    
    # Helper for tidying the options passed to the trip.calc() method:
    def self.clean_calc_options( options, obj )
      
      # Throw in ALL THE EXTRAS if required:
      # (And remove the with_all_extras option so it can't affect options on nested calls to calc)
      if options.delete(:with_all_extras)
        
        options.merge!(
          :with_taxes       => true,
          :with_biz_supp    => true,
          :with_booking_fee => true,
          :taxes            => false,
          :biz_supp         => false,
          :booking_fee      => false
        )
        
      end
      
      # Tidy up the options and assume defaults where necessary:
      options[:with_taxes]        = options.delete(:incl_taxes)    if options.has_key?(:incl_taxes)
      options[:with_biz_supp]     = options.delete(:incl_biz_supp) if options.has_key?(:incl_biz_supp)
      options[:for]               = :all_elements if !options[:for] || options[:for] == true  
      options[:zero_when_no_one]  = true  if options[:zero_when_no_one].nil?                # Return zero when none of the specified person is travelling (Eg when elem.adults == 0)
      options[:decimal_places]    = 0     if options[:decimal_places].nil?                  # Number of dp to include.
      options[:currency_prefix]   = ''    if options[:currency_prefix].nil?                 # Currency symbol to prepend to result.
      options[:string_format]   ||= "#{ options[:currency_prefix] }%.#{ options[:decimal_places] || 0 }f" unless options[:string_format] == false  # Eg: "£%.2f" => format( "£%.2f", 100 ) => '£100.00'
      options[:per_or_all]        = :all  unless options[:per_or_all] == :per               # Allow :for_all and :all to mean the same thing.
      options[:taxes]             = false if options[:with_taxes]    && options[:taxes]     # Prevent conflict between the :taxes    and :with_taxes    options.
      options[:biz_supp]          = false if options[:with_biz_supp] && options[:biz_supp]  # Prevent conflict between the :biz_supp and :with_biz_supp options.
      
      # :daily => 1, :total => self.days, otherwise specify number of days:
      options[:days] = case options[:days]
      when :daily, :day, 0, nil     then 1
      when :total, :all             then obj.days.abs
      when options[:days].to_i.abs  then options[:days].to_i.abs
      else                          1
      end
      
      # Tidy up the measure argument:
      options[:measure] = case options[:measure].to_sym
      when :net,    :cost,  :net_cost       then :net
      when :gross,  :price, :gross_price    then :gross
      when :margin, :profit                 then :margin
      when :percent_margin, :margin_percent then :percent_margin
      else                                       :net
      end
      
      # Tidy up the person argument: Eg: cost_per_child => :child, single_supp => :single, cost_per_single => :single
      options[:person]  = :traveller if options[:person] == :travellers or options[:person] == :person or options[:person] == :people
      options[:person]  = ( options[:person] || :adult ).to_s.gsub(/cost_per_|_supp/,'').singularize.to_sym
      options[:persons] = options[:person].to_s.pluralize.to_sym
      
      # Tidy up the trip_elements option:
      options[:for]     = ( options[:for] || :all ).to_s.gsub(/all_elements|all|total/,'trip_elements').singularize.pluralize.to_sym
      
      # Bonus attribute to keep the calling methods tidy:
      options[:as_decimal] ||= options[:to_decimal]   # Alias for misspelled option.
      options[:as_decimal]   = { :string_format => false, :to_currency => false } if options[:as_decimal] === true
      #options[:as_decimal]   = options.merge( options[:as_decimal] || {} )
      
      options[:options_and_as_decimal] ||= options.merge( :string_format => false, :to_currency => false )
      
      return options
      
    end
    
    
    
    # Helper for formatting the return value from the trip.calc() method:
    def self.format_calc_result( result, options )
      
      if options[:to_currency]
        currency_format = options[:to_currency] === true ? :generic : options[:to_currency]
        return result.to_currency( currency_format )
      else
        return options[:string_format] ? format( options[:string_format], result ) : result
      end
      
    end
    
    
    # Helper to calculate the total_cost for a supplier used on this trip:
    # TODO: Allow for subgroups in trip_elements.
    def total_cost_of_supplier( supplier )
      
      return 0 if supplier.nil?
      supplier = Supplier.get(supplier) if supplier.is_a? Integer
      
      elems = self.trip_elements.all( :supplier => supplier ) | self.flights.all( :handler => supplier )
      
      return  self.adults     * ( elems.sum( :cost_per_adult  )     || 0 ) +
              self.children   * ( elems.sum( :cost_per_child  )     || 0 ) +
              self.infants    * ( elems.sum( :cost_per_infant )     || 0 ) +
              self.singles    * ( elems.sum( :single_supp )         || 0 ) +
              self.adults     * ( elems.sum( :biz_supp_per_adult  ) || 0 ) +
              self.children   * ( elems.sum( :biz_supp_per_child  ) || 0 ) +
              self.infants    * ( elems.sum( :biz_supp_per_infant ) || 0 ) +
              self.travellers * ( elems.sum( :taxes ) || 0 )
      
    end
    
    
    # Helper to return an array of all suppliers (and flight handlers) involved in this trip's elements:
    def suppliers
      
      suppliers = []
      
      self.trip_elements.each do |elem|
        suppliers << elem.supplier if elem.supplier && !suppliers.include?(elem.supplier)
        suppliers << elem.handler  if elem.handler  && !suppliers.include?(elem.handler)  # Applies to flights only.
      end
      
      return suppliers
      
    end



    # Helper to reposition all the elements when the trip date changes. (Except bound elements)
    # Eg: When trip.start_date is moved by +10 days, all elements move by +10 days.
    # The number of days is derived automatically from the current and dirty (unsaved) start_date.
    def update_elements_dates( days = nil )

      if ( self.attribute_dirty?(:start_date) || days ) && !self.new?
        
        date   = Trip.properties[:start_date]
        days ||= self.dirty_attributes[date] - self.original_attributes[date]
      
        Merb.logger.debug "Adjusting dates of #{ self.trip_elements.length } elements by #{ days } days for trip #{ self.id }:"

        unless days.to_i.zero?
          
          self.trip_elements.each do |elem|
            
            if elem.bound_to_pnr?
              Merb.logger.debug " Not adjusting element #{ elem.id } dates because it is bound to a PNR."
            elsif elem.is_slave?
              Merb.logger.debug " Not adjusting element #{ elem.id } dates because it is bound to a Group Template."
            else
              elem.day += days.to_i
              Merb.logger.debug " Adjusting dates of element #{ elem.id } by #{ days } days."
            end
            
          end
          
        end
        
      end
      
    end

    
    # Helper for deriving company booking_fee:
    # (We cache the result temporarily to help speed up calculations that call this repeatedly)
    def booking_fee
      return @booking_fee ||= self.company && self.company.booking_fee || 0
    end
    
    # Helper for deriving total booking_fees: (For :all / :adults / :children / :infants)
    # (We cache the result temporarily to help speed up calculations that call this repeatedly)
    def booking_fees( travellers = :all )
      
      @booking_fees ||= {}
      travellers      = travellers.to_s.singularize.to_sym
      
      return @booking_fees[travellers] ||= case travellers
        
      when :adult, :child, :infant, :all, :person, :traveller then
        
        self.booking_fee * self.count_of(travellers)
        
      else 0
        
      end
      
    end
    
    
    
    # Helper for re-calculating the trip.total_price property: (Formerly known as total_spend)
    # Warning: Don't forget this includes both price_per_x and price_per_x_biz_supp
    def calc_total_price( options = { :as_decimal => true } )
      
      @@indent ||= ''
      @@indent << ' '
      
      final_price_options =     { :to_currency => true,  :final_prices  => true, :with_all_extras => true }
      final_price_options.merge!( :to_currency => false, :string_format => false ) if options[:as_decimal]
      final_price_options.merge!( options )
      
      result = self.calc( :daily, :actual, :gross, :for_all, :travellers, final_price_options )
      puts "#{@@indent} calc_total_price = #{result} (elem.calc :day :actual :gross :all :travellers) options: #{ final_price_options.inspect }" if options[:debug]
      
      @@indent.chop!
      return result
      
    end
    
    
    
    
    # Helper for recalculating and setting price_per_xxx and total_price of trip:
    # Only applied where price pp is currently zero because we must not override prices set manually in costing sheet!
    def update_prices( override = false )
      
      # Ensure submitted currency strings such as "123.00" are converted to decimals:
      # (These values are submitted by the Costings page)
      self.price_per_adult            = self.price_per_adult.to_f
      self.price_per_child            = self.price_per_child.to_f
      self.price_per_infant           = self.price_per_infant.to_f
      self.price_per_single           = self.price_per_single.to_f
      self.price_per_adult_biz_supp   = self.price_per_adult_biz_supp.to_f
      self.price_per_child_biz_supp   = self.price_per_child_biz_supp.to_f
      self.price_per_infant_biz_supp  = self.price_per_infant_biz_supp.to_f

      # Specify options: (Note we don't use :with_all_extras because it would include :with_biz_supp)
      std_options = { :with_biz_supp  => false, :with_booking_fee => true, :with_taxes => true, :string_format => false, :to_currency => false }
      biz_options = { :biz_supp       => true,                                                  :string_format => false, :to_currency => false }
      
      # Recalculate prices-per-person where they seem to be ZERO or just the booking fee:
      # (This typically occurs when no-one has entered prices in the Costing Sheet yet)
      self.price_per_adult            = self.calc( :total, :actual, :gross, :per, :adult,  std_options ) if override || self.price_per_adult.zero?  || self.price_per_adult  == self.booking_fee || self.price_per_adult  == self.booking_fees(:adults)
      self.price_per_child            = self.calc( :total, :actual, :gross, :per, :child,  std_options ) if override || self.price_per_child.zero?  || self.price_per_child  == self.booking_fee || self.price_per_child  == self.booking_fees(:children)
      self.price_per_infant           = self.calc( :total, :actual, :gross, :per, :infant, std_options ) if override || self.price_per_infant.zero? || self.price_per_infant == self.booking_fee || self.price_per_infant == self.booking_fees(:infants)
      self.price_per_adult_biz_supp   = self.calc( :total, :actual, :gross, :per, :adult,  biz_options ) if override || self.price_per_adult_biz_supp.zero?
      self.price_per_child_biz_supp   = self.calc( :total, :actual, :gross, :per, :child,  biz_options ) if override || self.price_per_child_biz_supp.zero?
      self.price_per_infant_biz_supp  = self.calc( :total, :actual, :gross, :per, :infant, biz_options ) if override || self.price_per_infant_biz_supp.zero?
      
      # Recalculate the total price of the trip too:
      self.total_price = self.calc_total_price()
      
    end
    

    # Helper to set all elements' exchange rates to the current rate:
    # Note: Expected behaviour is to recalculate prices even if rates have not changed.
    def update_exchange_rates( save = false )

      self.elements.each do |elem|

        elem.exchange_rate = elem.supplier.currency.rate if elem.supplier && elem.supplier.currency
        elem.update_prices
        elem.save! if save && !self.new?

      end

      result = self.update_prices
      self.save! if save && !self.new?
      return result

    end

    
    # Helper to set all elements' margins to the specified percentage:
    def update_margins_to( new_margin, save = false )

      self.elements.each do |elem|

        elem.margin_type          = '%'
        elem.biz_supp_margin_type = '%'
        elem.margin               = new_margin.to_i
        elem.biz_supp_margin      = new_margin.to_i
        elem.update_prices
        elem.save! if save && !self.new?

      end

      self.update_prices(:override_price_per_person)
      self.save! if save && !self.new?

      return self.total_price

    end
    
    
    
    # DEPRICATED
    # Helper to return a very compact version of the trip object with minimal attributes: (Useful when using to_json)
    def lite
      
      # Note the use of "each" to encourage DataMapper to use Strategic Eager Loading. (We could have just used "map")
      clients = []
      self.clients.each do |client|
        clients << {
          :id       => client.id,
          :name     => client.name,
          :forename => client.forename,
          :fullname => client.fullname,
          :shortname=> client.shortname
        }
      end
      
      return {
        :id           => self.id,
        :name         => self.name,
        :status       => self.status,
        :type         => self.type,
        :travellers   => self.travellers,
        :clients      => clients
      }
      
    end
    
    
    # @context: The id of this Client object is used for making Trip.contextId more unique:
    attr_accessor :context 
    
    # Helper to ensure consistent HTML Element IDs throughout the UI:
    # I know this should not be on the model but it's most convenient here!
    # TODO: Refactor to use Trips Controller Actions instead.
    # DEPRICATED
    def contextId (childContext = nil, context = nil)
      
      lookupNameOf = {
        :summary=>"Summary",
        :builder=>"Builder",
        :itinerary=>"Itinerary",
        :documents=>"Documents",
        :accounting=>"Financials",
        :countries=>"Countries"
      }
      
      # Allow for missing childContext argument (string) by testing for presence of 2nd argument:
      if childContext.is_a? Client
        context ||= childContext  # Swap arguments
        childContext = nil
      end
      
      @context = context unless context.nil?
      newContextId = @context.contextId unless @context.nil?
      return ( newContextId || "" ) + "trip" + (id || 0).to_s + ( lookupNameOf[childContext] || "" )
      
    end
    
    
    # Helper to generate a new version of this trip: (Note we explicitly prevent copied elements from being bound to their originals)
    def new_version( custom_attributes = {} )

      version = Trip.new
      version.do_link_to_master = false
      cloned  = version.copy_attributes_from self, custom_attributes

      return version if cloned

    end



    # Helper to copy details from another trip if required:
    # Warning: Relying on this hook can cause save to fail if copied elements are invalid.
    # Note: This also clears the do_copy_trip_xxx flags to prevent copies from being created again accidentally.
    def do_copy_trip( master_trip_id = nil, unbind_from_pnrs = true )

      master_trip_id ||= self.do_copy_trip_id

      # Copy details from another trip if required:
      if master_trip_id && ( master_trip = Trip.get(master_trip_id) )

        # Copy Clients from master_trip:
        if self.do_copy_trip_clients
          self.copy_clients_from master_trip
          self.do_copy_trip_clients = nil     # Clear flag to prevent duplication if saved again.
        end

        # Copy Countries from master_trip:
        if self.do_copy_trip_countries
          self.copy_countries_from master_trip
          self.do_copy_trip_countries = nil   # Clear flag to prevent duplication if saved again.
        end

        # Copy Trip Elements from master_trip:
        # Important: PNR Flight elements are cloned as standard flights (without booking_code) if unbind_from_pnrs.
        if self.do_copy_trip_elements

          options = {
            :adjust_dates     => true,
            :unbind_from_pnrs => unbind_from_pnrs,
            :link_to_master   => self.do_link_to_master # Should only be used to link a FIXED_DEP's elements to it's TOUR_TEMPLATE
          }
          self.copy_elements_from master_trip, options
          self.do_copy_trip_elements = nil    # Clear flag to prevent duplication if saved again.

        end

        # Only copy the pnrs if specified:
        unless unbind_from_pnrs
          self.copy_pnr_numbers_from master_trip
        end
        
      end

    end


    
    # Helper for CLONING a trip along with it's assigned clients, countries and new clones of the trip_elements:
    def copy_attributes_from( master, custom_attributes = nil )
      
      if master
        
        clone          = self
        link_to_master = ( clone.do_link_to_master.nil? ? true : !!clone.do_link_to_master )

        attributes = master.attributes.except(:id).merge( :name => "Copy of #{ master.name }" )

        # Important: A copy of a TOUR_TEMPLATE must be a FIXED_DEP:
        if master.tour_template?
          attributes.merge! :type_id => TripType::FIXED_DEP, :name => "Group: #{ master.name }"
        end

        clone.attributes = attributes
        
        # Copy clients, countries, elements and pnr-numbers:
        clone.copy_clients_from master
        clone.copy_elements_from master, :link_to_master => link_to_master
        clone.copy_countries_from master
        clone.copy_pnr_numbers_from master
        
        # Override defaults with any attributes explicitly specified in this method's arguments:
        clone.attributes = custom_attributes if custom_attributes
        
        return clone.attributes
        
      end
      
    end
    
    
    def copy_clients_from( master, clone = nil )
      
      clone ||= self
      
      master.trip_clients.each do |c|
        
        attributes = c.attributes.merge( :id => nil, :status_id => TripClientStatus::UNCONFIRMED )
        conditions = { :client_id => c.client_id }
        clone.trip_clients.first_or_new( conditions, attributes )
        
      end
      
    end
    

    def copy_countries_from( master, clone = nil )

      clone ||= self

      master.trip_countries.each do |c|

        attributes = c.attributes.merge( :id => nil  )
        conditions = { :country_id => c.country_id }
        clone.trip_countries.first_or_new( conditions, attributes )

      end

    end


    def copy_pnr_numbers_from( master, clone = nil )
      
      clone ||= self
      
      master.trip_pnrs.each do |p|
        
        attributes = { :pnr_id => p.pnr_id, :pnr_number => p.pnr_number }
        conditions = { :pnr_id => p.pnr_id }
        clone.trip_pnrs.first_or_new( conditions, attributes )
        
      end
      
    end


    # Helper for cloning elements from another trip:
    # Options:
    #    :adjust_dates true to ensure first element date is adjusted to start of trip.
    #    :unbind_from_pnrs true to skip any PNR Number (AKA booking_code) associated with flights.
    def copy_elements_from( master, options = nil )

      # Apply defaults for omitted options:
      defaults  = {
        :clone            => self,
        :type_id          => nil,   # When set, only elements matching this type will be copied.
        :adjust_dates     => false, # When true, element dates will be changed to fit the new trip.
        :unbind_from_pnrs => false, # When true, skip the :booking_code field.
        :link_to_master   => false  # When true, set  the :master_trip_element_id field. For Fixed Dep only!
      }
      options   = defaults.merge( options || {} )
      clone     = options.delete :clone
      type_id   = options[:type_id].to_i > 0 ? options[:type_id].to_i : nil

      master.trip_elements.all( :order => [:id] ).each do |master_elem|

        # Add cloned element to the trip (unless type_id was specified and matches element type)
        if !type_id || master_elem.type_id == type_id

          clone_elem = clone.trip_elements.new.copy_attributes_from( master_elem, options )

        end

      end

    end


    # Helper to make current client the only primary on this trip:
    def set_primary_client!( client_id, allow_fellow_primaries = false )

      if ( trip_client = self.trip_clients.first( :client_id => client_id ) )

        # Make client primary if not already:
        if !trip_client.is_primary
          trip_client.is_primary = true
          trip_client.save!
        end

        # Only make other clients non-primary if current client is now primary:
        if trip_client.is_primary && !allow_fellow_primaries

          self.trip_clients.all( :client_id.not => client_id, :is_primary => true ).each do |other|
            other.is_primary = false
            other.save!
          end
        end

      end

    end

    
    def initialize(*)
      super
      self.type_id    ||= TripType::TAILOR_MADE
      self.status_id  ||= TripState::UNCONFIRMED
      self.debug      ||= false
      @orig_pnr_numbers_before_save = self.pnr_numbers
    end
    
    
    
    # DEPRICATED in favour of "after :save" hook
    # Definition of sql trigger that ensures version_of_trip_id is set on first version of each trip:
    
    #	-- =============================================
    #	-- Author:		George Adamson
    #	-- Create date: 09 Feb 2010
    #	-- Description:	Ensure the first version of a new trip has a self reference to it's own id.
    #	-- =============================================
    #	CREATE TRIGGER [dbo].[trg_trips_version_of_trip_id]
    #		 ON  [dbo].[trips]
    #		 AFTER INSERT
    #	AS 
    #	BEGIN
    #
    #		SET NOCOUNT ON;
    #
    #	-- Set version_of_trip_id to self reference it's id if it not already set:
    #			-- (This only applies to first version of each trip. Subsequent versions refer to first version's id)
    #			UPDATE		trips SET trips.version_of_trip_id = trips.id
    #			FROM		trips
    #			INNER JOIN	inserted ON inserted.id = trips.id
    #			WHERE		inserted.version_of_trip_id = 0
    #			OR			inserted.version_of_trip_id IS NULL
    #
    #	END
    
    
    alias trip_state status

    # An accessor for trip.status.name that returns a cached value to reduce sql queries:
    def status_name
      @@cached_status_name ||= {}
      @@cached_status_name[self.status_id] ||= self.status.name
    end

    # An accessor for trip.status.code that returns a cached value to reduce sql queries:
    def status_code
      @@cached_status_code ||= {}
      @@cached_status_code[self.status_id] ||= self.status.code
    end


# Class methods:

    # Find all the confirmed trips that ended yesterday: (Used by automated status change in app/controllers/application.rb)
    def self.all_ready_to_complete( today = nil )

      today ||= Date.today
      active_versions = Trip.all( :is_active_version => true,  :status_id => TripState::CONFIRMED, :end_date.lt => today )
      other_versions  = Trip.all( :is_active_version => false, :version_of_trip_id => active_versions.map{|t|t.id} )

      return active_versions + other_versions

    end

    # Find all the unconfirmed trips that [would have] started yesterday: (Used by automated status change in app/controllers/application.rb)
    def self.all_ready_to_abandon( today = nil )

      today ||= Date.today
      active_versions = Trip.all( :is_active_version => true,  :status_id => TripState::UNCONFIRMED, :start_date.lt => today )
      other_versions  = Trip.all( :is_active_version => false, :version_of_trip_id => active_versions.map{|t|t.id} )

      return active_versions + other_versions

    end


    # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
    def self.class_display_name
      return 'Trip'
    end
    
    
    # Define which properties are available in reports  
    def self.potential_report_fields

      return [ :name, :title, :booking_ref, :status, :company, :user, :is_active_version, :pax, :clients, :money_ins, :start_date, :end_date, :total_cost, :total_price, :countries, :country_names, 

      # ...and the following are special custom methods especially for reports:
      :primary_clients_names, :type_name, :total_invoiced, :invoice_first_date, :total_margin_percent ]

    end



private

    # Validator to confirm client source when creating a new private trip:
    def check_client_source_on_new_trip

      # Fail validation if client nested attributes contain blank source:
      if self.new? \
      && ( self.tailor_made? || self.private_group? ) \
      && self.respond_to?(:clients_attributes) \
      && self.clients_attributes \
      && ( blank_sources = self.clients_attributes.select{|k,v| v[:source_id].to_i.zero?} ) \
      &&  !blank_sources.empty?

          # Derive name of affected client, just to be helpful:
          affected_client_ids   = blank_sources.map{|k,v| v[:id]}
          affected_clients      = Client.all( :id => affected_client_ids )
          affected_client_names = affected_clients.map{|c| c.fullname}.join(', ')
          affected_client_names = "for #{ affected_client_names }" unless affected_clients.empty?

          return [ false, "First you'll need to confirm the client source #{ affected_client_names }" ]

      else
        return true
      end

    end

end


