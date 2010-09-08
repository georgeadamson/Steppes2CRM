require 'dm-timestamps'

class TripElement
  include DataMapper::Resource
  
  # Old fields: DetailID,ElementTypeID,ItineraryHeaderID,SupplierID,DateFrom,DateTo,NumAdults,NumChildren,NumSingles,NoMargin,total_cost,total_price,exchange_rate,cost_per_adult,cost_per_child,single_suppl,LeaderCost,meal_plan,room_type,twin_rooms,single_rooms,triple_rooms,cost_per_triple,DetailNotes,cost_by_room,FlightHandlerID,Description,flight_code,FlightDate,DepartAirport,ArriveAirport,DepartureTime,ArrivalTime,arrive_next_day,booking_code,OptionExpires,OptionNotes,ReturnOptionCode,ReturnOptionExpires,ReturnOptionNotes,flight_leg,Taxes,BSPerAdult,BSPerChild,DFcost_per_adult,DFcost_per_child,DFNotes,Returnflight_code,ReturnFlightDate,ReturnDepartAirport,ReturnArriveAirport,ReturnDepartureTime,ReturnArrivalTime,ReturnArriveNextDay,LinkedHandlerID,SubGroupID,row_updated_date
  # Ground Agent domestic Flight now entered as Flight. Formerly: DFcost_per_adult,DFcost_per_child,DFNotes
  # Return flights now entered as separate Flight. Formerly: Returnflight_code,ReturnFlightDate,ReturnDepartAirport,ReturnArriveAirport,ReturnDepartureTime,ReturnArrivalTime,ReturnArriveNextDay
  
  # Note: Flights without a handler can only be added by a PNR.
  
  FLIGHT  = TripElementType::FLIGHT  unless defined?(FLIGHT)
  HANDLER = TripElementType::HANDLER unless defined?(HANDLER)
  ACCOMM  = TripElementType::ACCOMM  unless defined?(ACCOMM)
  GROUND  = TripElementType::GROUND  unless defined?(GROUND)
  MISC    = TripElementType::MISC    unless defined?(MISC)
  
  
  property :id,                   Serial
  property :type_id,							Integer,		:required	=> true,	:default	=> FLIGHT  					# tripElementType ID	(1=Flight, 4=Accomm, 5=Ground, 8=Misc)
  property :misc_type_id,					Integer,		:default	=> 1																		# tripElementMiscType ID
  property :trip_id,							Integer,		:required	=> true,	:index		=> true							# trip ID
  property :supplier_id,					Integer,		:required	=> true																	# supplier ID for Suppliers
  property :handler_id,						Integer																												# supplier ID for FlightHandlers (Supplier trip_element_type_id=2)
  property :name,									String,			:default	=> 'Trip element'
  property :description,					String,			:length		=> 600,		:default	=> ''
  property :notes,								String,			:length		=> 600,		:lazy			=> true,  :default => ''	# Formerly "DetailNotes" and "OptionNotes" (now merged)
  
  property :start_date,						DateTime,		:required	=> true,	:default	=> lambda{ |elem,prop| Date.today }				# Formerly departTime & flightDate
  property :end_date,							DateTime,		:required	=> true,	:default	=> lambda{ |elem,prop| Date.today + 1 }		# Formerly arriveTime
  
  property :adults,								Integer,		:default	=> 1
  property :children,							Integer,		:default	=> 0
  property :infants,							Integer,		:default	=> 0
  property :singles,							Integer,		:default	=> 0
  
  property :margin_type,					String,			:length		=> 1,			:default	=> '%'							# Apply margin as percent? (Or fixed amount)
  property :margin,								BigDecimal, :required	=> true,  :precision=> 6, :scale	=> 2,	:default	=> lambda{ |elem,prop| CRM[:default_margin] || 24 }	# Number representing a fixed amount or percent.
  property :exchange_rate,				BigDecimal, :required	=> true,  :precision=> 6, :scale	=> 2,	:default	=> 1
  property :cost_per_adult,				BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2  # LOCAL cost per adult per day
  property :cost_per_child,				BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2  # LOCAL cost per child per day
  property :cost_per_infant,			BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2  # LOCAL cost per infant per day
  property :cost_per_triple,			BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2
  property :cost_by_room,					BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2
  property :single_supp,					BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2
  
  # Calculated totals: (Updated whenever the element is saved)
  property :total_cost,						BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2	# AKA Total Net 
  property :total_price,					BigDecimal, :default	=> 0,			:precision=> 9, :scale	=> 2	# AKA Total Gross
  alias total_net   total_cost
  alias total_gross total_price
  
  property :meal_plan,						String,			:length		=> 2,			:default	=> ''
  property :room_type,						String,			:length		=> 50,		:default	=> ''
  property :single_rooms,					Integer,		:default	=> 0
  property :twin_rooms,						Integer,		:default	=> 0
  property :triple_rooms,					Integer,		:default	=> 0
  
  property :flight_code,					String,			:length		=> 10,		:default	=>	''  # Flight number
  property :flight_leg,						Boolean,		:default	=> false
  property :arrive_next_day,			Boolean,		:default	=> false
  property :touchdownDescription, String,			:default	=> ''									      # Text equivalent of touchdowns table association.
  property :taxes,								BigDecimal, :precision=> 6,	:scale		=> 2, :default => 0
  
  property :biz_supp_per_adult,		BigDecimal, :precision=> 6,	:scale		=> 2, :default => 0
  property :biz_supp_per_child,		BigDecimal, :precision=> 6,	:scale		=> 2, :default => 0
  property :biz_supp_per_infant,	BigDecimal, :precision=> 6,	:scale		=> 2, :default => 0
  property :biz_supp_margin,			BigDecimal, :precision=> 6, :scale	  => 2,	:default => '10', :required	=> true
  property :biz_supp_margin_type, String,     :length		=> 1,			            :default => '%'
  
  property :is_subgroup,					Boolean,		:default	=> false							# Only set when number of adults/children/infants must differ from main trip.
  property :is_active,						Boolean,		:default	=> true								# (Reserved for future use)
  
  property :booking_code,					String,			:length		=> 50,		:default	=> ''	# Alias: pnr_number. Formerly: option_code,OptionExpires,OptionNotes,ReturnOptionCode,ReturnOptionExpires,ReturnOptionNotes
  property :booking_reminder,			DateTime																		# 
  property :booking_expiry,				DateTime																		# UNUSED?
  property :booking_line_number,	Integer
  property :booking_line_revision,Integer
	property :depart_airport_id,		Integer
	property :arrive_airport_id,		Integer
	property :depart_terminal,			String,			:length		=> 10
	property :arrive_terminal,			String,			:length		=> 10
  
  property :created_at,						DateTime
  property :updated_at,						DateTime
  property :created_by,						String
	property :updated_by,						String
  
  #property :flightDate, String            # Date          #Depricate? Use start_date instead?
  #property :departTime, String            # DateTime      #Depricate? Use start_date instead?
  #property :arriveTime, String            # DateTime      #Depricate? Use end_date instead?
  
  alias pnr_number  booking_code
  alias pnr_number= booking_code=
  
  # Aliases and dummy methods necessary for generic method calls in the calc() method:
  def   biz_supp_per_single; return 0; end
  alias cost_per_single      single_supp 
  alias cost_per_single=     single_supp=
  alias cost_margin          margin      
  alias cost_margin=         margin=     
  alias cost_margin_type     margin_type 
  alias cost_margin_type=    margin_type=
  alias taxes_margin_type    margin_type
  alias taxes_margin_type=   margin_type=
  alias taxes_margin=        taxes_margin=     
  def   taxes_margin;        return self.taxes_margin_type == '%' ? 0 : self.margin; end # Fixed margin must not be addes to taxes.
  def   taxes_per_single;    return 0; end
  def   taxes_per_single=;             end
  alias taxes_per_adult      taxes
  alias taxes_per_child      taxes
  alias taxes_per_infant     taxes
  
  # Ensure flight number is always returned in upper case:
  def flight_code
    return self.attribute_get(:flight_code).upcase if self.attribute_get(:flight_code)
  end
  
  
  #  ??? LinkedHandlerID,SubGroupID
  
  
  #validates_format :start_date, :format => /^[0-2]?[0-9]:[0-6][0-9]$/, :message => "oops"
  #validates_format :start_time, :with => /^[0-2]?[0-9]:[0-6][0-9]$/, :message => "oops "
  
  belongs_to :trip
  belongs_to :supplier
  belongs_to :handler,				:model => 'Supplier',							:child_key => [:handler_id]  # AKA Flight Agent, Flight Handler
  belongs_to :element_type,		:model => 'TripElementType',			:child_key => [:type_id]
  belongs_to :misc_type,			:model => 'TripElementMiscType',	:child_key => [:misc_type_id]
  belongs_to :depart_airport,	:model => 'Airport',							:child_key => [:depart_airport_id]
  belongs_to :arrive_airport,	:model => 'Airport',							:child_key => [:arrive_airport_id]
  
  has n, :touchdowns    # List of 0-n touchdown airports.
  
	# Instance storage of airport codes. Intended for customising validation messages when creating or updating flights from PNR data:
	attr_accessor :depart_airport_code, :arrive_airport_code
  
  
  # Require departure/arrival AIRPORTS on flight NOT created automatically by a PNR:
  validates_present :depart_airport_id, :if => Proc.new {|elem| elem.flight? && elem.pnr_number.blank? }
	validates_present :arrive_airport_id, :if => Proc.new {|elem| elem.flight? && elem.pnr_number.blank? }
  
  # Require departure/arrival AIRPORTS on flight created automatically by a PNR:
  validates_present :depart_airport_id, :if => Proc.new {|elem| elem.bound_to_pnr? },
  :message => "The Departure Airport code was not recognised. (Try examining the PNR and ensure the airport has an Airport Code defined in the System Admin pages)"
  validates_present :arrive_airport_id, :if => Proc.new {|elem| elem.bound_to_pnr? },
  :message =>   "The Arrival Airport code was not recognised. (Try examining the PNR and ensure the airport has an Airport Code defined in the System Admin pages)"
	
  
  # Require SUPPLIER on element NOT created automatically by a PNR:
  validates_present :supplier_id, :unless => Proc.new {|elem| elem.bound_to_pnr? }
  
  # Require SUPPLIER (airline) on flight created automatically by a PNR:
  validates_present :supplier_id, :if => Proc.new {|elem| elem.bound_to_pnr? },
  :message => "The Airline code was not recognised. (Try examining the PNR and ensure the airline has an Airline Code defined in the System Admin pages)"
  
  # Require HANDLER on flight NOT created automatically by a PNR:
  validates_present :handler_id, :if => Proc.new {|elem| elem.flight? && elem.pnr_number.blank? },
  :message => "The Flight agent cannot be left blank"
  
  
  # Ugly workaround for the way datamapper returns datetime properties!
  # Necessary because DM adds unwanted +01 timezone offset when reading datetime fields from database during BST.
  # TODO: Look out for a better solution: http://groups.google.com/group/datamapper/browse_thread/thread/f01d9dba2cc29412
  alias raw_start_date start_date
  alias raw_end_date   end_date
  def start_date; d = self.raw_start_date; DateTime.civil( d.year, d.month, d.day, d.hour, d.min, 0, 0 ); end
  def end_date;   d = self.raw_end_date;   DateTime.civil( d.year, d.month, d.day, d.hour, d.min, 0, 0 ); end
  
  
	#  validates_with_block :arrive_airport_id do
	#  
	#		if self.type_id == 1 && !self.pnr_number.blank?
	#			return [ false, "The Arrival Airport code was not recognised. (Try examining PNR #{ self.pnr_number } and add the airport code #{ @arrive_airport_code } to the appropriate airport in the System Admin page)" ]
	#		else
	#			return true
	#		end
	#  
	#  end
  
  
  # Silently tidy up invalid attributes before saving:
  before :save do
    
    self.handler_id = nil unless handler_id.to_i > 0
    
    if ( trip = self.trip )
      
      # Always save flight number in upper case:
      self.flight_code.upcase! if self.flight?
      
      # Ensure start/end_date are not blank: (Unless it's a flight element created by a PNR)
      self.start_date	||= DateTime.parse( trip.start_date ) unless self.bound_to_pnr?
      self.end_date		||= self.start_date + 1               unless self.bound_to_pnr?
      
      self.adults				= trip.adults   if self.adults.nil?   || self.adults   != trip.adults   # TODO: Handle subgroups
      self.children			= trip.children if self.children.nil? || self.children != trip.children #
      self.infants			= trip.infants  if self.infants.nil?  || self.infants  != trip.infants  #
      self.adults				= 0 if self.adults   < 0
      self.children			= 0 if self.children < 0
      self.infants			= 0 if self.infants  < 0
      self.adults				= trip.adults    if self.adults   > trip.adults
      self.children			= trip.children  if self.children > trip.children
      self.infants			= trip.infants   if self.infants  > trip.infants
      self.is_subgroup	= ( self.adults < trip.adults || children < trip.children || infants < trip.infants )
      
    end
    
    # Recalculate this element's total cost and price:
    self.update_prices()
    
  end
  
  
  after :save do
    
    # Clear cached calculations because the data has changed:
    @cache_of_calc_results = {}
    
    @prevElem = nil
    @nextElem = nil
    
    # Recalculate and save price_per_xxx and total_price OF THE TRIP:
    if ( trip = self.trip )
      trip.reload
      trip.update_prices
      trip.save!
    end       
    
  end
  
  
  after :destroy do
    
    self.total_cost  = 0
    self.total_price = 0
    
    @prevElem = nil
    @nextElem = nil
    
    # Recalculate and save price_per_xxx and total_price OF THE TRIP:
    if ( trip = self.trip )
      trip.reload
      trip.update_prices
      trip.save!
    end       
    
  end
  
  
  # Helper to derive the margin multipler if applicable, otherwise just return 1:
  def margin_multiplier
    return ( self.margin_type == '%' ) ? (100 - self.margin) / 100 : 1
  end
  alias cost_margin_multiplier margin_multiplier
  alias taxes_margin_multiplier margin_multiplier
  
  # Helper to derive the biz_supp margin multipler if applicable, otherwise just return 1:
  def biz_supp_margin_multiplier
    return ( self.biz_supp_margin_type == '%' ) ? (100 - self.biz_supp_margin) / 100 : 1
  end
  
  # Generic helper for returning element.adults etc:
  def count_of(people)
    
    return case people.to_s.singularize.to_sym
    when :adult  then self.adults
    when :child  then self.children
    when :infant then self.infants
    when :single then self.singles
    else 0
    end
    
  end
  
  
  
	# Helpers for handling DATES and TIMES...
  
  # Provide friendly way to get/set flight times (start/end_time are stored with date in the start/end_date fields)
  #alias start_time start_date
  #alias end_time end_date
  
	# Check-in time is n hours before start_date time: (Requires app setting CRM[:check_in_period] )
	# (Typically applies to Flight elements only)
	def check_in_time
		( self.start_date.to_time - ( CRM[:check_in_period] || 2 ).hours ).formatted(:uitime) if self.start_date
	end
  
	# Return the time portion of start_date: (Typically applies to Flight elements only)
	def start_time
		self.start_date.formatted(:uitime) if self.start_date
	end
  
	# Return the time portion of end_date: (Typically applies to Flight elements only)
	def end_time
		self.end_date.formatted(:uitime) if self.end_date
	end
  
  
  # Merge start_time with the start_date field: (Typically applies to Flight elements only)
  def start_time=(hh_mm);
    unless hh_mm.blank?
			d = self.start_date
			t = DateTime.strptime(hh_mm, '%H:%M')
			self.start_date = DateTime.civil(d.year, d.month, d.day, t.hour, t.min)
		end
  end
  
  # Merge end_time with the end_date field: (Typically applies to Flight elements only)
  def end_time=(hh_mm);
    unless hh_mm.blank?
			d = self.end_date
			t = DateTime.strptime(hh_mm, '%H:%M')
			self.end_date = DateTime.civil(d.year, d.month, d.day, t.hour, t.min)
		end
  end
  
	def dateSummary
		# Eg: "Sun 4th May to Thu 5th Jun 2008"
		sameYear  = (self.start_date.year  == self.end_date.year ? '' : ' %Y')    # Only show start year when different.
		sameMonth = (self.start_date.month == self.end_date.month ? '' : ' %b') # Only show start month when different.
		return self.start_date.strftime_ordinalized('%a %d' + sameMonth + sameYear) + " to " + self.end_date.strftime_ordinalized('%a %d %b %Y')
	end
  
	#validates_format :start_time, :format => /[0-2][0-9]:[0-9][0-9]/
  
  
  
  
  
	# Helpers for handling DAYS...
  
  # Element's number of days as percent of total trip length:
  def percentOfTrip; return 100 * self.days.to_f / self.trip.days; end    
  
  # Element's start day as percent of total trip length:
  def percentThroughTrip; return 100 * self.day.to_f / self.trip.days; end 
  
  # Number of days since start of trip:
  def day; return ( ( Date.parse(self.start_date.to_s) - Date.parse(self.trip.start_date.to_s) ) + 1).to_i; end  
  
  # Duration of trip element in days:
  def days                                                                  
    result = ( Date.parse(self.end_date.to_s) - Date.parse(self.start_date.to_s) ).to_i
    result += 1 unless self.element_type && self.element_type.code == "accomm"			# Don't count the check-out day of accommodation elements. Eg: Two nights span 3 days so just count 2.
    return result
  end
  
  
	# Returns an array of trip elements that this one overlaps: (collection will include this one)
	# Defaults to only consider overlaps with elements that are the same type, eg Flights.
  # TODO: Find a less resource-intentive way to do this! Can it be handled by the trip object?
	def overlaps( type_id = true )
    
		if @overlaps.nil?
      
			@overlaps = []
			type_id		= self.type_id if type_id      === true	# Fiter by same type if type_id is true
			type_id		= false        if type_id.to_i ==  0			# Do not filter at all if type_id is false or non numeric.
      
			# This technique matches fields returned from a single query, preventing multiple queries for each day:
			self.trip.trip_elements.all( :order => [ :start_date, :id ] ).each do |elem|
        
				@overlaps << elem if (  type_id == false || elem.type_id == type_id ) \
        &&
        (
          # if dates overlap or match exactly:
          #( elem.start_date.jd <  self.end_date.jd && elem.end_date.jd >  self.start_date.jd ) ||	
          #( elem.start_date.jd == self.end_date.jd && elem.end_date.jd == self.start_date.jd )
          #( elem.start_date.jd <= self.end_date.jd && elem.end_date.jd >= self.start_date.jd )
          ( self.start_date.jd == elem.start_date.jd ) ||
          ( self.start_date.jd >= elem.start_date.jd && self.start_date.jd <  elem.end_date.jd   ) ||
          ( self.end_date.jd   >  elem.start_date.jd && self.end_date.jd   <= elem.end_date.jd   )
        )
        
			end
      
			# Alternative technique using DM collection. Could not get this to work:
			#	@overlaps = self.trip.trip_elements.all( :order => [ :start_date, :id ] )
			#
			#	@overlaps.each do |elem|
			#
			#		@overlaps.delete(elem) if ( type_id == false || elem.type_id == type_id ) &&
			#				( elem.start_date.jd <  self.end_date.jd && elem.end_date.jd >  self.start_date.jd ) ||
			#				( elem.start_date.jd == self.end_date.jd && elem.end_date.jd == self.start_date.jd )
			#
			#	end
      
		end
		
		# Alternative technique using custom sql filters. Resulted in multiple queries on database:
		#	@overlaps ||= self.trip.trip_elements.all( :order => [ :start_date, :id ], :conditions => [
		#
		#		# Either filter by overlapping dates:
		#		'( CAST(FLOOR(CAST( trip_elements.start_date AS float)) AS datetime) < CAST(FLOOR(CAST( ? AS float)) AS datetime)   AND' +
		#		'  CAST(FLOOR(CAST( trip_elements.end_date   AS float)) AS datetime) > CAST(FLOOR(CAST( ? AS float)) AS datetime) ) OR ' +
		#
		#		# Or by exactly the same dates:
		#		'( CAST(FLOOR(CAST( trip_elements.start_date AS float)) AS datetime) = CAST(FLOOR(CAST( ? AS float)) AS datetime)   AND' +
		#		'  CAST(FLOOR(CAST( trip_elements.end_date   AS float)) AS datetime) = CAST(FLOOR(CAST( ? AS float)) AS datetime) )',
		#
		#		self.end_date,
		#		self.start_date,
		#		self.start_date,
		#		self.end_date
		#
		#	] )
		#
		#	# Filter by element type if necessary:
		#	if type_id
		#		type_id = self.type_id if type_id == true
		#		return @overlaps.all( :type_id => type_id )
		#	else
		#		return @overlaps
		#	end
    
		return @overlaps
    
	end
  
	# Return the zero-based index of this element's position among overlapping elements:
	# Default to only consider overlaps with elements of the same type.
	def overlap_index( type_id = true )
		
		return self.overlaps(type_id).index(self) || 0
    
	end
  
  
  # Helper for returning the previous and next elements in the trip, by start_date:
  def prev
    return @prevElem ||= derivePrevAndNextElements() || @prevElem
  end
  
  def next
    return @nextElem ||= derivePrevAndNextElements() || @nextElem
  end
  
  
  
  
  
  
	# Helpers for handling COSTS...
  
  # Daily LOCAL COST of trip_element: (DEPRICATED aliases)
  alias local_cost_per_adult  cost_per_adult;
  alias cost_per_child_local  cost_per_child;
  alias cost_per_infant_local cost_per_infant;
  
  
  # Special DSL method for calculating specific costs and prices. Used on the Costings Sheet a lot.
  # Eg: elem.calc :daily, :local, :cost, :per, :adult
  # Params:
  #   days              = :daily or :total  (specifying :total will multiply by number of days)
  #   currency          = :local or :actual (specifying :actual will apply the exchange_rate)
  #   measure           = :net or :gross or :margin
  #   per_or_all        = :per or :all      (specifying :all will multiply by number of adults or whoever)
  #   person            = :adult or :child or :infant or :single
  # options:
  #   :biz_supp         = true or false(default) - Specify true to calculate business class supplement on flight elements.
  #   :with_biz_supp    = true or false(default) - Specify true to include business class supplement in the result.
  #   :with_taxes       = true or false(default) - Specify true to include element taxes in the result.
  #   :zero_when_no_one = false or true(default) - Specify true to simply return zero when there are no persons.
  #   :string_format    = false or a format-string(default) - Specify false to return result as a decimal.
  #   :with_all_extras  is equivalent to :with_taxes and :with_biz_supp and :with_booking_fee
  
  def calc( days, currency, measure, per_or_all, person, options = {} )
    
    
    # Tidy up the options and assume defaults where necessary:
    args                    = { :days => days, :measure => measure, :per_or_all => per_or_all, :person => person }
    options                 = Trip.clean_calc_options options.merge(args), self
    days                    = options[:days]
    measure                 = options[:measure]
    per_or_all              = options[:per_or_all]
    person                  = options[:person]
    persons                 = options[:persons]
    options_and_as_decimal  = options[:options_and_as_decimal]
    @cache_of_calc_results||= {}
    
    
    # Calculate sum of results for all types of travellers: (adults+children+infants+singles)
    if persons == :travellers
      
      result = self.calc( days, currency, measure, per_or_all, :adult,  options_and_as_decimal ) +
      self.calc( days, currency, measure, per_or_all, :child,  options_and_as_decimal ) +
      self.calc( days, currency, measure, per_or_all, :infant, options_and_as_decimal ) +
      self.calc( days, currency, measure, per_or_all, :single, options_and_as_decimal )
      
      
      
      # Otherwise calculate results for a specific type of traveller: (adults/children/infants/singles)
    else
      
      # Fetch the number of elem.adults or elem.children or elem.infants:
      person_count = self.count_of persons
      
      
      # Simply return zero when there are no travellers of the specified type:
      if person_count == 0 && options[:zero_when_no_one]
        
        result = 0.0
        
        # Bail out if we're trying to read biz_supp for a non-flight or a single: (Because biz_supp only applies to adult/child/infant)
      elsif options[:biz_supp] && ( !self.is_flight? || person == :single )
        
        result = 0.0
        
        # Otherwise do the calculations for this type of traveller:
      else
        
        # Derive method names:
        # (When options[:biz_supp] flag is specified then read properties beginning with 'biz_supp_' otherwise 'cost_')
        method_prefix             = options[:taxes] ? 'taxes' : options[:biz_supp] ? 'biz_supp' : 'cost'
        cost_method               = "#{ method_prefix }_per_#{ person }"    # Eg: cost_per_adult or biz_supp_per_adult
        margin_method             = "#{ method_prefix }_margin"             # Eg: cost_margin or biz_supp_margin
        margin_type_method        = "#{ method_prefix }_margin_type"        # Eg: cost_margin_type or biz_supp_margin_type
        margin_multiplier_method  = "#{ method_prefix }_margin_multiplier"  # Eg: cost_margin_multiplier or biz_supp_margin_multiplier
        
        margin_multipler          = self.method(margin_multiplier_method).call    # Eg: When margin is 23% consultants divide cost by 0.77 to get gross
        margin                    = self.method(margin_method).call               # Eg: 23 (percent) or 250 (fixed)
        margin_type               = self.method(margin_type_method).call          # '%' or blank.
        
        # TODO: Cache results in instance variable hash to speed up costings sheet and reports etc.
        # May not be as helpful as hoped because the cache_key needs to be even more unique. Note sure what's needed.
        # It almost works but cache needs to get cleared when margin or exchange_rate properties change during calcs.
        # The caching mechanism is effectively disabled because it requires options[:use_cache] to make use of it.
        
        if options.delete(:use_cache) && 
          ( cache_key = "#{ options.inspect }_#{ margin }_#{ margin_type }".to_sym ) && 
          ( result = @cache_of_calc_results[cache_key] )
          
          puts " Using cached copy of #{ cache_key }"
          puts "  = #{ result } \n"
          
        else
          
          #  if options[:taxes]
          #    cost_in_local     = ( person != :single ? self.taxes : 0 ) || 0
          #  end
          #    cost_in_local     = self.method(cost_method).call
          #  end
          
          # Calculate costs per person:
          cost_in_local         = self.method(cost_method).call
          exchange_rate         = ( currency == :actual && self.exchange_rate != 0 ) ? self.exchange_rate.abs : 1.0
          cost_in_currency      = cost_in_local  / exchange_rate
          
          if margin_type == '%'
            # Calculate percent margin per person:
            margin_in_currency  = ( cost_in_currency  / margin_multipler ) - cost_in_currency
          elsif options[:taxes] || person == :single
            # Skip fixed margin on single calculations and taxes:
            margin_in_currency  = 0.0
          else
            # Otherwise used fixed margin:
            margin_in_currency  = margin
          end
          
          # Calculate net or gross or margin amount:
          per_person_amount   = case measure
          when :net    then cost_in_currency
          when :gross  then cost_in_currency + margin_in_currency
          when :margin then margin_in_currency
          else              cost_in_currency
          end
          
          # When returning biz_supp or taxes we must not multiply by the number of days:
          days = 1 if !days || days.zero? || options[:biz_supp] || options[:taxes]
          
          result  = per_person_amount
          result *= person_count.abs if per_or_all == :all
          result *= days  # :daily => 1, :total => self.days, otherwise specify number of days.
          
          # Add extras to the result if required:
          if options[:with_taxes] || options[:with_biz_supp]
            
            no_extras = options.merge( options_and_as_decimal ).merge( :taxes => false, :with_taxes => false, :biz_supp => false, :with_biz_supp => false )
            
            # ADD TAXES to result if required:
            if options[:with_taxes] && !options[:taxes]
              result += self.calc( 1, currency, measure, per_or_all, person, no_extras.merge( :taxes => true ) )
            end
            
            # ADD BIZ_SUPP to result if required:
            if options[:with_biz_supp] && !options[:biz_supp]
              result += self.calc( 1, currency, measure, per_or_all, person, no_extras.merge( :biz_supp => true ) )
            end
            
          end
          
          @cache_of_calc_results[cache_key] = result
          
        end
        
      end
      
      
    end
    
    
    if options[:to_currency]
      currency_format = options[:to_currency] == true ? :generic : options[:to_currency]
      return result.to_currency( currency_format )
    else
      return options[:string_format] ? format( options[:string_format], result ) : result
    end
    
    
  end
  
  
  
  
	# General helpers...
  
	# Helpers for testing what type of element this is: 
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
  
  # Just to make the dsl consistent with the Supplier model:
  alias airline? is_flight
  alias is_airline? is_flight # TODO: Depricate this
  
  
  # Helper flag to tell us whether a flight was created by a PNR:
  def bound_to_pnr?
    return self.flight? && !self.pnr_number.blank?
  end
  
  
	# Consistent string for use in displays and reports etc:
  def display_name
    return self.supplier.name.blank? ? self.name : self.supplier.name
  end
  
  # Legacy attribute to be depricated:
	alias displayName display_name
  
  
	# Prepare a little summary of the number of days or nights:
  def name_and_duration( name_when_blank = '(supplier not set)' )
    
    duration = self.is_flight? ? '' : " (#{ self.days } #{ self.is_accomm? ? 'nights' : 'days' })"
    
    name = self.display_name.blank? ? name_when_blank : self.display_name
    
    return "#{ name }#{ duration }"
    
  end
  
  
  
  # Helper for re-calculating the trip.total_cost property: (Formerly known as total_spend)
  # Includes WITH_ALL_EXTRAS
  def calc_total_cost( options = { :as_decimal => true } )
    
    options = options.merge( :with_all_extras => true )
    options.merge!( :to_currency => false, :string_format => false ) if options[:as_decimal]
    
    return self.calc( :total, :actual, :net, :for_all, :travellers, options )
    
  end
  
  # Helper for re-calculating the trip.total_price property: (Formerly known as total_spend)
  # Includes WITH_ALL_EXTRAS
  def calc_total_price( options = { :as_decimal => true } )
    
    options = options.merge( :with_all_extras => true )
    options.merge!( :to_currency => false, :string_format => false ) if options[:as_decimal]
    
    return self.calc( :total, :actual, :gross, :for_all, :travellers, options )
    
  end
  
  
  # Helper for recalculating and setting total_cost and total_price of this element:
  # (Should be called automatically when element is saved)
  def update_prices
    
    if self.destroyed?
      self.total_cost  = 0
      self.total_price = 0
    else
      self.total_cost  = self.calc_total_cost
      self.total_price = self.calc_total_price
    end
    
  end
  
  
  
  
  #	# Daily STERLING COST of trip element:
  #	def cost_per_adult_actual;  return self.calc( :daily, :actual, :cost, :per, :adult ); end
  #	def cost_per_child_actual;  return self.calc( :daily, :actual, :cost, :per, :child ); end
  #	def cost_per_infant_actual; return self.calc( :daily, :actual, :cost, :per, :infant); end
  #  
  #	# Daily STERLING PRICE of trip element:
  #	def gross_per_adult_actual;  return self.calc( :daily, :actual, :gross, :per, :adult ); end
  #	def gross_per_child_actual;  return self.calc( :daily, :actual, :gross, :per, :child ); end
  #	def gross_per_infant_actual; return self.calc( :daily, :actual, :gross, :per, :infant); end
  #
  #	# Daily LOCAL MARGIN of trip element:
  #	def margin_per_adult_local;   return self.calc( :daily, :local,  :margin, :per, :adult ); end
  #	def margin_per_child_local;   return self.calc( :daily, :local,  :margin, :per, :child ); end
  #	def margin_per_infant_local;  return self.calc( :daily, :local,  :margin, :per, :infant); end
  #  
  #	# Daily STERLING MARGIN of trip element:
  #	def margin_per_adult_actual;  return self.calc( :daily, :actual, :margin, :per, :adult ); end
  #	def margin_per_child_actual;  return self.calc( :daily, :actual, :margin, :per, :child ); end
  #	def margin_per_infant_actual; return self.calc( :daily, :actual, :margin, :per, :infant); end
  #
  #	# Total LOCAL COST of trip element: (Foreign currency unit cost x Number of days)
  #	def total_cost_per_adult_local;  return self.calc( :total, :local, :cost, :per, :adult ); end
  #	def total_cost_per_child_local;  return self.calc( :total, :local, :cost, :per, :child ); end
  #	def total_cost_per_infant_local; return self.calc( :total, :local, :cost, :per, :infant); end
  #  
  #	# Total STERLING COST of trip element: (Total local cost / Exchange rate)
  #	def total_cost_per_adult_actual;  return self.calc( :total, :actual, :cost, :per, :adult ); end
  #	def total_cost_per_child_actual;  return self.calc( :total, :actual, :cost, :per, :child ); end
  #	def total_cost_per_infant_actual; return self.calc( :total, :actual, :cost, :per, :infant); end
  #  
  #	# Total STERLING MARGIN of trip element:
  #	def total_margin_per_adult_actual;  return self.calc( :total, :actual, :margin, :per, :adult ); end
  #	def total_margin_per_child_actual;  return self.calc( :total, :actual, :margin, :per, :child ); end
  #	def total_margin_per_infant_actual; return self.calc( :total, :actual, :margin, :per, :infant); end
  #  
  #	# Total STERLING GROSS gross of trip element:
  #	def total_gross_per_adult_actual;  return self.calc( :total, :actual, :gross, :per, :adult ); end
  #	def total_gross_per_child_actual;  return self.calc( :total, :actual, :gross, :per, :child ); end
  #	def total_gross_per_infant_actual; return self.calc( :total, :actual, :gross, :per, :infant); end
  
  
  
  #  def initialize(*)
  #    
  #    super
  #
  #    if self.trip
  #      self.adults   = self.trip.adults  
  #      self.children = self.trip.children
  #      self.infants  = self.trip.infants 
  #      self.singles  = self.trip.singles 
  #    end
  #    
  #  end
  
  
  
  
  private
  
  
  # Helper for working out the element.prev and element.next elements in the trip by start_date:
  # TODO: Find a better way!
  def derivePrevAndNextElements
    
    foundSelf   = nil
    @prevElem ||= nil
    @nextElem ||= nil
    
    self.trip && self.trip.trip_elements.all( :order => [ :type_id, :start_date, :id ] ).each do |elem|
      
      # The order of these commands is significant:
      @nextElem = elem if foundSelf && !@nextElem
      foundSelf = elem if elem == self
      @prevElem = elem if !foundSelf
      
    end
    
    return nil
    
  end
  
  
end
