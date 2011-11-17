class Pnr
  require 'ostruct'
  include DataMapper::Resource
  
  property :id,								Serial
	
	property :name,							String,		:required => true, :unique => true, :length => 6		# AKA PNR Number or Booking Code
	property :data,							Text,			:required => true,                  :lazy	  => true	# Raw Amadeus flight data etc.
	property :booking_date,			DateTime,	:required => true																		# Date when PNR was generated.
	property :first_flight_date,DateTime
	property :reminder_date,		DateTime																											# Used as a sort of booking expiry.
	
	property :file_name,				String,		:required => true, :length => 200	# AIR file downloaded by the Amadeus ProPrinter app.
	property :file_date,				DateTime,	:required => true																		# Filesystem updated-date of AIR file. (AIR = Amadeus Interface Record)
	
	property :flight_count,			Integer,	:required => true, :default => 0										# Number of flight rows found in AIR file.
	property :client_count,			Integer,	:required => true, :default => 0										# Number of client names found in AIR file.
	
  property :error_log,        Text

	property :created_at,				DateTime
	property :updated_at,				DateTime																											# AKA imported_date
	
	has n, :trip_pnrs,	:child_key => [:pnr_id]
	has n, :trips,			:through   => :trip_pnrs
	
	# Aliases to improved readability: (because 'pnr.number' is more like the terminology used by consultants)
	alias number name
	alias imported_date updated_at
	
  
  # Shared timestamp of the last time Pnr.import_latest_amadeus_records() was run:
  @@import_is_running = false
  @@last_import_date  = DateTime.now
  def self.last_import_date;  return @@last_import_date;  end
  def self.import_is_running; return @@import_is_running; end
  

  # Helper to SET THE PNR ATTRIBUTES by parsing their values from the raw pnr data:
  def data!( new_data = nil )

    self.data = new_data.to_s if new_data
  
    if self.data && self.data =~ /^\w*AIR-BLK/
      
      # Parse details from the raw pnr data and derive attributes expected by the pnr object:
      parsed_data     = Pnr.parse_amadeus_record(self.data)
      pnr_attributes  = Pnr.get_pnr_attrs_from(parsed_data)

      Pnr.logger.info "Updated PNR #{ self.number } from it's raw data"
      
      return self.attributes = pnr_attributes
      
    end
    
    return false
  
  end
  
  

	# Update associated trip elements whenever PNR is updated:
	after :save do

    Pnr.logger.info "Saved PNR #{ self.number }"
	
		# Depricated because for some reason this can cause SQL to hang:
    # Instead you must call pnr.refresh_trip_flights explicitly after saving the pnr.
    # refresh_trip_flights()

	end
	
	
	def refresh_trip_flights
		
		self.trips.each do |trip|
      
      #print "\n refresh_flight_elements_for(trip id #{ trip.id })" if Merb.environment == 'test'
      
			how_many = refresh_flight_elements_for(trip)
      
			#trip.save unless how_many[:succeeded].zero?
      
		end
    
    if self.trips.empty?
      message = "No trips were updated because none reference PNR #{ self.number }"
      Pnr.logger.info message
      #print message if Merb.environment == 'test'
	  end
	   
	end
	
	
	# Extract flights data from PNR as an array of attributes-hashes:
	# Important: These are NOT instances of real flight trip_element objects, but the attributes match.
	def flights
		
    # Parse each flight out of the pnr data then format each as trip_element attributes:
    parsed_pnr_flights = Pnr.parse_amadeus_record( self.data )[:flights]
    flights_attributes = parsed_pnr_flights.map{ |f| Pnr.get_flight_element_attrs_from(f) }
		
    return flights_attributes # Array of flight element attributes
		
	end
	
	
	
	
	
	# Ensure a trip's elements include all the flights identified by this PNR:
	# Create trip_elements for flights not already on the trip with the same booking_line_number.
	# Update trip_elements for flights already on the trip with the same booking_line_number.
  # Delete trip_elements for flights with booking_line_number that is no longer in the pnr.
	# Called by trips controller (for each assigned pnr) when trip is updated.
	# Warning! Only call this method if the PNR is relevant to the trip!
	def refresh_flight_elements_for(trip)

		Pnr.logger.info! "#{ Time.now.to_s } refresh_flight_elements_for trip id #{trip.id} (Already has #{ trip.flights.length } flights) Applying PNR #{ self.number } to #{ trip.inspect }"
			
		succeeded   = 0
		failed      = 0
		errors			= {}
    pnr         = self

    # DELETE the trip's flights where booking_line_numbers no longer in pnr:
    pnr_line_numbers = []
    pnr.flights.each{ |f| pnr_line_numbers << f[:booking_line_number] if f[:booking_line_number].to_i > 0 }

    trip.flights.all(
      :booking_code             => pnr.number,
      :booking_line_number.not  => pnr_line_numbers
    ).delete_if{ |flight| !flight.booking_line_number.blank? }.destroy!


		# CREATE or UPDATE the trip's flights for each pnr-flight:
		pnr.flights.each do |attributes|
      
			conditions = {
        :booking_code         => pnr.number,
        :booking_line_number  => attributes[:booking_line_number]
      }
			
			flight = trip.flights.first_or_new( conditions, attributes )
      is_new = flight.new?

			flight.attributes = attributes unless flight.new?
		
			if !flight.dirty?

				Pnr.logger.info! " Skipped flight line #{ flight.booking_line_number } because it is already up to date"

			elsif flight.save!  # <-- Update without triggering hooks otherwise we cause recursion.

				Pnr.logger.info! " #{ is_new ? 'Added' : 'Updated' } flight line #{ flight.booking_line_number } successfully. #{ flight.inspect }"
				succeeded += 1

			else
				
				Pnr.logger.info! " Failed while updating flight line #{ flight.booking_line_number }: #{ flight.errors.inspect }"
				failed += 1		
						
				error_message = flight.errors.values.join(', ')
				
				# Add pnr_line_number to array of errors: (it can be manipulated later to report line numbers for each error)
				( errors[error_message] ||= [] ) << attributes[:booking_line_number]
				
			end
			
		end


		# Convert arrays of pnr-line-numbers into csv strings, then invert the hash so the line numbers become the hash keys:
		# Eg: BEFORE: errors = { "The Airline code was not recognised." => [3,4] }
		# Eg: AFTER : errors = { "3,4" => "The Airline code was not recognised." }
		errors = errors.each_pair{ |err,line_nos| errors[err] = line_nos.join(',') }.invert

    # The trip_elements collection does not yet include the flights we just added so we have to refresh it.
    # Warning: This has the effect of resetting unsaved trip_elements because this code keeps reloading all elements before their attributes get saved!)
    # Consequently I had to add a workaround in the trip_elements#update controller action! :(
    # TODO: Find a better solution!
    # Added 05 Jul 2010 to prevent bug where flights may get added several times by before/after:save hooks because trip_elements collection does not include the flights we just added!
    trip.trip_elements.reload 

		Pnr.logger.info! "Finished refresh_flight_elements_for trip id #{trip.id} (#{ trip.flights.length } flights)"
		Pnr.logger.info! errors.inspect unless errors.empty?
		
		return {
			:succeeded	=> succeeded,		# Count of successfully imported flight lines.
			:failed			=> failed,			# Count of failed flight line imports.
			:errors			=> errors				# Hash of PNR line numbers and their errors.
		}
		
	end
	
	
	
	
	
	
	
	
	#
	# Class method helpers for handling Amadeus Interface Record (AIR) files and parsing PNR data out of them.
	#
	
	
	# Return an array of NEW AIR FILES sorted by ascending order of file-updated-date:
  # Called by Pnr.prepare_latest_amadeus_records()
	def self.latest_amadeus_records( since_date = nil, pnr_folder_path = nil )
		
		# Default to import files modified since the LAST PNR was imported:
		recent_pnr				= Pnr.first( :order => [:updated_at.desc] )
		since_date			||= ( recent_pnr && recent_pnr.updated_at ) ? recent_pnr.updated_at : ( Date.today - 10 )
		
		# Default to the standard PNR AIR folder:
		pnr_folder_path	||= CRM[:pnr_folder_path] || ''
		pnr_search_path		= pnr_folder_path.gsub('\\','/') / '*.txt'	
	
		# Get array of paths of every file in pnr folder, then
		pnr_files = Dir.glob( pnr_search_path ).
		
			# Populate an array of hashes representing each file:
			map{ |path|																						

				# Return a hash of the file's properties and contents:
				File.open( path, 'r' ){ |file|							
					{
						:file_name		=> File.basename( file.path ),
						:file_date		=> file.mtime.to_datetime,
						:data					=> file.read
					}
				}

			}.
			
			# Filter by files updated after since_date and
			# Sort selected files by last-updated-date:
			select{ |file| file[:file_date] > since_date }.
			sort{   |a, b| a[:file_date]  <=> b[:file_date] }

		Pnr.logger.info "Found #{ pnr_files.length } new PNR Files modified after #{ since_date.to_s } in #{ pnr_search_path }"
		
		# Return array of new AIR files:
		return pnr_files

	end
	
	
	
	
	# Helper for parsing the raw text of an Amadeus Interface Record (AIR) file containing PNR details.
	# Returns a hash of attributes and info.
	# Expects to receive the contents of an AIR file.
	# At time of writing, the AIR files were stored in \\selsvr01\central files\Flights\Flight System\Amadeus\PNR-grabs
	def self.parse_amadeus_record(air)
		
		flights = []
		clients = []
    errors  = [] # Will be used to log parsing errors as we go.
		
		# Parse out the important lines from the AIR text:
		data_rows			= air.split(/\n/)
		codes_data		= data_rows.select{ |row| row =~ /^MUC/ }		# Eg: "MUC1A 3OQC6X002;0101;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;;;;;;;;;;;;;;;;;;;;;;BA NOSYNC"
		reminder_data	= data_rows.select{ |row| row =~ /^TKTL/ }	# Eg: "TKTL20MAR/LONU12102"
		dates_data		= data_rows.select{ |row| row =~ /^D-/ }		# Eg: "D-100315;100315;100315"
		clients_data	= data_rows.select{ |row| row =~ /^I-/ }		# Eg: "I-001;01ARMITAGE/JAMESMR;;APSTEPPES TRAVEL 01285 885333 JAMES;;"
		flights_data	= data_rows.select{ |row| row =~ /^U-/ }		# Eg: "U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 01MAY1315 2055 01MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1"
		
		# Discard 'ARNK' rows that are not flights: (Eg: "U-000X;000OGRU;GUARULHOS INTL   ;GIG;RIO DE JANEIRO IN;VOID;BR;BR")
		flights_data.delete_if{ |data| data =~ /^U-000/ }
		
		# Assemble PNR Booking expiry date:
		pnr_number				= codes_data.first.slice(6,6).upcase
    errors << "Unable to parse pnr_number from codes_data #{ codes_data.first.inspect }" if pnr_number.nil?
		
		# Extract the booking date:
		# Important: The year of the booking is required to derive the year of the flight departure and arrival dates.
    begin
  		pnr_booking_date	= Date.strptime( dates_data.first.slice(2,6), '%y%m%d')	# Eg: 'D-100315;100315;100315' => '2010-03-15'
		rescue
      errors << 'Unable to parse pnr_booking_date from #{dates_data.first}'
    end
    errors << "Unable to parse booking_date from dates_data #{ dates_data.first.inspect }" if pnr_booking_date.nil?

	  pnr_reminder_day		= nil
	  pnr_reminder_month	= nil
	  pnr_reminder_date		= nil

    airline_code        = nil
    airline             = nil
    depart_airport_code	= ''
    arrive_airport_code = ''
    depart_airport      = nil
    arrive_airport      = nil

    flight              = {}
		
		# Reminder date will be derived later from first flight date unless it was specified in the PNR:
		# (Note: We cannot derive it from flights until we have parsed all the flight data)
    begin
		  unless reminder_data.empty?
  			
			  pnr_reminder_day		= reminder_data.first.slice(4,2).to_i
			  pnr_reminder_month	= Date::Format::ABBR_MONTHS[ reminder_data.first.slice(6,3).downcase ]
			  pnr_reminder_date		= Date::civil( pnr_booking_date.year, pnr_reminder_month, pnr_reminder_day )
  			
		  end
		rescue
      errors << 'Unable to parse reminder date'
    end
		
		
		# Parse flight details from each flight row:
		flights_data.each do |data|
			
			# Examples of raw flight data: 
			#		U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 01MAY1315 2055 01MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1
			#		U-002X;003OGIG;RIO JANEIRO GIG  ;LHR;LONDON LHR       ;BA    0248 S S 15MAY2225 1340 16MAY;HK01;HK01;M ;0;777;;;;1 ;;ET;1115 ;N;;5730;;BR;GB;5 
			
			data					= data.split(';')
			
      begin
			  # Lookup the AIRLINE (supplier) in our database: (airline_id is just an alias for supplier_id)
			  airline_code	= data[5].slice(0,2).strip
			  airline				= airline_code.blank? ? nil : Supplier.first( :type_id => 1, :code => airline_code )
      rescue Exception => details
        errors << "Unable to parse airline_code (from #{data}) #{details}"
      end
  
      begin
			  # Lookup the AIRPORTS in our database:
			  depart_airport_code	= data[1].slice(-3,3).strip
			  arrive_airport_code = data[3].slice(-3,3).strip
			  depart_airport = depart_airport_code.blank? ? nil : Airport.first( :code => depart_airport_code )
			  arrive_airport = arrive_airport_code.blank? ? nil : Airport.first( :code => arrive_airport_code )
      rescue Exception => details
        errors << "Unable to parse depart/arrive_airport (from #{data}) #{details} (from #{data})"
      end

		  flight = {
			  :pnr_booking_date					=> pnr_booking_date,
			  :pnr_number								=> pnr_number,
			  :pnr_reminder_day					=> pnr_reminder_day,
			  :pnr_reminder_month				=> pnr_reminder_month,
			  :pnr_reminder_date				=> pnr_reminder_date
      }
			
      begin
        flight.merge!(
				  :pnr_line_number					=> data[0].slice(2,3).to_i,								# Eg: 'U-001X;002OLHR...'	=> '001'
				  :pnr_line_revision				=> data[1].slice(0,3).to_i								# Eg: 'U-001X;002OLHR...'	=> '002'
        )
      rescue Exception => details
        errors << "Unable to parse flight line_number or revision number (from #{data}) #{details}"
      end

			
      begin
        flight.merge!(
				  :flight_code							=> data[5].slice(0,10).sub( /\s+0*/,' ' ),# Eg: 'BA    0249'				=> 'BA 249'
				  :flight_class							=> data[5].slice(11,1),
				  :flight_detail						=> data[5]																# Eg: 'BA    0249 S S 01MAY1315 2055 01MAY'
        )
      rescue Exception => details
        errors << "Unable to parse flight code or class (from #{data}) #{details}"
      end

			
      begin
        flight.merge!(
				  :airline_code							=> airline_code,													# Eg: 'BA    0249'				=> 'BA'
				  :airline_id								=> airline ? airline.id : nil,
				  :supplier_id							=> airline ? airline.id : nil 						# :airline_id is just an alias for :supplier_id
        )
      rescue Exception => details
        errors << "Unable to set flight airline (from #{data}) #{details}"
      end

			
      # Departure Airport:
      begin
        flight.merge!(
				  :depart_airport_id				=> depart_airport ? depart_airport.id : nil,
				  :depart_airport_code			=> depart_airport_code,
				  :depart_airport_name			=> data[2].strip,							            # Name according to amadeus. Not necessarily identical to airport name in database
				  :depart_terminal					=> data[14].strip
				  #:depart_airport_name			=> ( data[2]  || '' ).strip,							# Name according to amadeus. Not necessarily identical to airport name in database
				  #:depart_terminal					=> ( data[14] || '' ).strip
        )
      rescue Exception => details
        errors << "Unable to parse flight depart_airport (from #{data}) #{details}"
      end

      # Arrival Airport:
      begin
        flight.merge!(
				  :arrive_airport_id				=> arrive_airport ? arrive_airport.id : nil,
				  :arrive_airport_code			=> arrive_airport_code,
				  :arrive_airport_name			=> data[4].strip,							            # Name according to amadeus. Not necessarily identical to airport name in database
				  :arrive_terminal					=> data[24].strip
				  #:arrive_airport_name			=> ( data[4]  || '' ).strip,							# Name according to amadeus. Not necessarily identical to airport name in database
				  #:arrive_terminal					=> ( data[24] || '' ).strip
        )
      rescue Exception => details
        errors << "Unable to parse flight arrive_airport (from #{data}) #{details}"
      end

      # Departure Date/Time:
      begin
        flight.merge!(
				  :depart_year							=> pnr_booking_date.year,
				  :depart_month							=> Date::Format::ABBR_MONTHS[ data[5].slice(17,3).downcase ],
				  :depart_day								=> data[5].slice(15,2).to_i,
				  :depart_time							=> data[5].slice(20,4),
				  :depart_hour							=> data[5].slice(20,2).to_i,
				  :depart_minute						=> data[5].slice(22,2).to_i
        )
      rescue Exception => details
        errors << "Unable to parse flight depart_datetime (from #{data}) #{details}"
      end
  				

      # Arrival Date/Time:
      begin
        flight.merge!(
				  :arrive_year							=> pnr_booking_date.year,
				  :arrive_month							=> Date::Format::ABBR_MONTHS[ data[5].slice(32,3).downcase ],
				  :arrive_day								=> data[5].slice(30,2).to_i,
				  :arrive_time							=> data[5].slice(25,4),
				  :arrive_hour							=> data[5].slice(25,2).to_i,
				  :arrive_minute						=> data[5].slice(27,2).to_i
        )
      rescue Exception => details
        errors << "Unable to parse flight arrive_datetime (from #{data}) #{details}"
      end

    

			begin

        #if flight[:depart_year] && flight[:depart_month] && flight[:depart_day] && flight[:depart_hour] && flight[:depart_minute]

			    # Derive complete FLIGHT DATES AND TIMES:
			    flight[:depart_date]		= DateTime::civil( flight[:depart_year], flight[:depart_month], flight[:depart_day], flight[:depart_hour], flight[:depart_minute], 0, 0 )
			    flight[:arrive_date]		= DateTime::civil( flight[:arrive_year], flight[:arrive_month], flight[:arrive_day], flight[:arrive_hour], flight[:arrive_minute], 0, 0 )

          # Because flight dates do not include YEAR we must deduce year based on pnr_booking_date:
          # So, if depart_date is earlier than pnr_booking_date then add a year to it!
          # TODO: Is there a simpler way to increment the year?!
          if flight[:depart_date] && flight[:depart_date].jd < pnr_booking_date.jd
			      flight[:depart_date]	= DateTime::civil( pnr_booking_date.year + 1, flight[:depart_month], flight[:depart_day], flight[:depart_hour], flight[:depart_minute], 0, 0 )
			      flight[:arrive_date]	= DateTime::civil( pnr_booking_date.year + 1, flight[:arrive_month], flight[:arrive_day], flight[:arrive_hour], flight[:arrive_minute], 0, 0 )
          end
            
			    # Increment ARRIVAL YEAR when arrival month is earlier than departure month:
			    # This is necessary because amadeus does not provide flight-year so dates must always be within a year of booking date!
          # TODO: Is there a simpler way to increment the year?!
			    if flight[:depart_date] && flight[:arrive_date] && flight[:arrive_date].jd < flight[:depart_date].jd
				    flight[:arrive_year] += 1
				    flight[:arrive_date] = DateTime::civil( flight[:arrive_year], flight[:arrive_month], flight[:arrive_day], flight[:arrive_hour], flight[:arrive_minute] )
			    end

        #end

      rescue Exception => details
        errors << "Unable to validate flight depart/arrive_date #{details}"
      end
			
      
			flights << flight
			
		end
		
		
		# Now that we have parsed flight data we can deduce first_flight_date: .sort{ |a,b| a[:depart_date].jd <=> b[:depart_date].jd }
		pnr_first_flight_date = flights.empty? ? nil : flights.first[:depart_date]
		
		
		# When no reminder date specified in PNR then derive it using default reminder period (eg 21 days before flight)
		if pnr_reminder_date.nil? && !pnr_first_flight_date.nil?
			
			# Derive reminder date from the date of the earliest flight in this PNR:
			pnr_reminder_date	= pnr_first_flight_date - CRM[:flight_reminder_period].to_i
			
			# Store the reminder date in each flight hash:
			flights.each do |flight|
				flight[:pnr_first_flight_date]	= pnr_first_flight_date
				flight[:pnr_reminder_date]			= pnr_reminder_date
				flight[:pnr_reminder_day]				= pnr_reminder_date.day
				flight[:pnr_reminder_month]			= pnr_reminder_date.month
			end
			
		end
		
		
		
		
		# Parse the client data:
		clients_data.each do |data|
			
      begin

			  # Eg: "I-001;01ARMITAGE/JAMESMR;;APSTEPPES TRAVEL 01285 885333 JAMES;;"
			  data = data.split(';')	
  			
			  clients << {
				  :client_pnr_name => data[1]
			  }

      rescue Exception => details
        errors << "Unable to parse client attributes #{details} #{ data.inspect }"
      end
    
		end
		
		
		
		# Return a hash containing all the PNR info:
		return {
			
			:pnr_number							=> pnr_number,
			:pnr_booking_date				=> pnr_booking_date,
			:pnr_first_flight_date	=> pnr_first_flight_date,
			:pnr_reminder_date			=> pnr_reminder_date,
			
			:clients								=> clients,
			:flights								=> flights,
      :errors                 => errors 
      
		}
		
	end
	
	
	
	
	
	# Prepare an array of new Pnr objects ready to save, generqated from PNR data in the latest Amadeus AIR files:
	# Used by Pnr.import_latest_amadeus_records to prepare the records to be created/updated.
	def self.prepare_latest_amadeus_records( since_date = nil, pnr_folder_path = nil )
		
    @@import_is_running = true
    
    begin

		  # Fetch array of new AIR file info sorted by last-updated-date: (Assumes defaults where arguments not specified)
		  pnrs = []
      info_for_debugging = "Pnr.latest_amadeus_records( #{ since_date.inspect }, #{ pnr_folder_path } )"
		  pnr_files  = Pnr.latest_amadeus_records( since_date, pnr_folder_path )
      pnr_number = nil
  		
		  #Pnr.logger.info "\nStarted prepare_latest_amadeus_records for #{ pnr_files.length } files #{ Time.now.to_s }\n"
  		
		  # Create or update PNR records in our database: (The file argument is a hash of file properties)
		  pnr_files.each do |file_info|
  			
        pnr_number = ''
        
        # Parse the air file data:
        begin

          info_for_debugging = "get_pnr_attrs_from( {:file_name=>\"#{ file_info[:file_name] }\"...} ) "
			    attributes         = get_pnr_attrs_from( file_info )
          
          info_for_debugging = "Reading pnr number from parsed file"

          pnr_number         = attributes[:name]
			    conditions         = { :name => pnr_number }

          if pnr_number.blank? || pnr_number.length != 6
            raise "Unable to parse PNR Number #{ pnr_number } from file #{ file_info[:file_name] }"
          elsif !attributes[error_log].blank?
            copy_file_to_folder file_info[:file_name], :failed
          end
    			
			    # See if we already have a record of this PNR on the database, otherwise create one:
			    # We also allow for PNRs that are being updated more than once in this batch (to prevent duplicate)
          info_for_debugging = "Deciding whether parsed air file pnr needs to be created or updated"
			    pnr_duplicate 		 = pnrs.select{ |pnr| pnr.number == pnr_number }.first
			    pnr								 = pnr_duplicate || Pnr.first_or_new( conditions, attributes )
			    pnr.attributes		 = attributes if !pnr.new? || pnr_duplicate
			    pnrs << pnr unless pnr_duplicate

        rescue Exception => details

          error_message = "FAILED while parsing AIR File for PNR #{ pnr_number }: #{ info_for_debugging }: #{ details }"
          Merb.logger.error error_message
          Pnr.logger.error  error_message
          copy_file_to_folder file_info[:file_name], :failed

        end

      end
  		
    rescue Exception => details

      @@import_is_running = false
      @@last_import_date  = DateTime.now
      error_message = "FAILED while preparing AIR File data for PNR #{ pnr_number }: #{ info_for_debugging }: #{ details }"
      Merb.logger.error error_message
      Pnr.logger.error  error_message

	  end

		#Pnr.logger.info! "Finished prepare_latest_amadeus_records for #{ pnrs.length } PNRs #{ Time.now.to_s }\n"
		
    @@import_is_running = false
    @@last_import_date  = DateTime.now
				
		return pnrs
		
	end

	
	
	def self.import_latest_amadeus_records( since_date = nil, pnr_folder_path = nil )
	
		Pnr.logger.info! "Starting PNR import #{ Time.now.inspect }"
		
		pnrs					    = Pnr.prepare_latest_amadeus_records( since_date, pnr_folder_path )
		pnr_numbers		    = pnrs.map{ |pnr| pnr.number }
		existing_pnrs     = Pnr.all( :name => pnr_numbers )
		
		pnrs.each do |pnr|

			old_pnr         = existing_pnrs.first( :name => pnr.number )
      this_pnr        = "PNR #{ pnr.number } #{ pnr.new? ? 'created' : 'updated' } from #{ pnr.file_name } #{ pnr.error_log }"
      pnr.updated_at  = DateTime.now
			
			if old_pnr && old_pnr.file_date && pnr.file_date && old_pnr.file_date >= pnr.file_date
			
				Pnr.logger.info! "Skipping #{ this_pnr } - It is already up to date"

			elsif pnr.save!
			
				Pnr.logger.info! "Imported #{ this_pnr }"
			
				pnr.trips.each do |trip|
					
					# UPDATE TRIPS: Refresh every affected flight element:
          how_many = pnr.refresh_flight_elements_for(trip)
					
				end

			else
			
				Pnr.logger.error! "Failed to import #{ this_pnr }"
			
			end
		
		end
	
		Pnr.logger.info! "Finished PNR import #{ Time.now.inspect }"

		return pnrs
		
	end
	
	
	
	
	# Helper to build a hash of Pnr model attributes from the little hash of pnr file attributes generated by Pnr.latest_amadeus_records()
	# Expects pnr_file_info to be like: { :file_name => 'name', :file_date => datetime, :data => 'contents of file' }
	def self.get_pnr_attrs_from( file_info_or_parsed_pnr )

    # Decide whether argument is a file_attr hash: (Typically created by Pnr.latest_amadeus_records()
    if file_info_or_parsed_pnr.has_key?(:data)

      file_info  = file_info_or_parsed_pnr
      parsed_pnr = Pnr.parse_amadeus_record( file_info[:data] )
      #raise "PNR parser error #{ parsed_pnr[:errors].inspect }" unless parsed_pnr[:errors].empty?

    # Otherwise it must be a parsed_pnr hash: (Typically created by Pnr.parse_amadeus_record()
    else

      file_info  = {}
      parsed_pnr = file_info_or_parsed_pnr

    end

		attributes = {
			:name								=> parsed_pnr[:pnr_number],
			:booking_date				=> parsed_pnr[:pnr_booking_date],
			:first_flight_date	=> parsed_pnr[:pnr_first_flight_date],
			:reminder_date			=> parsed_pnr[:pnr_reminder_date],
			:flight_count				=> parsed_pnr[:flights].length,
			:client_count				=> parsed_pnr[:clients].length,
      :error_log          => ''
		}

    # Store array of parser errors as a string, if any:
    attributes[:error_log] = parsed_pnr[:errors].inspect unless parsed_pnr[:errors].blank?

		# If argument was a file_attr hash then it provides more attributes:
		attributes[:file_name] = file_info[:file_name] if file_info.has_key?(:file_name)
		attributes[:file_date] = file_info[:file_date] if file_info.has_key?(:file_date)	# File updated date
		attributes[:data]      = file_info[:data]      if file_info.has_key?(:data)		    # Raw PNR data extracted from file
		
		return attributes
		
	end
	
	
	# Helper to return a hash of flight attributes ready to create or update a flight trip_element.
	# The attribute names match those of trip_elements.
	# Expects a hash of pnr flight data of the format returned in the Pnr.parse_amadeus_record().flights array.
	def self.get_flight_element_attrs_from( pnr_flight_record )
		
		return {
			
			:type_id								=> 1,																				# trip_element_type: Flight
			:supplier_id						=> pnr_flight_record[:airline_id],
			
			:booking_code						=> pnr_flight_record[:pnr_number],					# Only elements created from a PNR will have a booking_code (PNR Number).
			:booking_reminder 	    => pnr_flight_record[:pnr_reminder_date],
			:booking_line_number		=> pnr_flight_record[:pnr_line_number],			#
			:booking_line_revision	=> pnr_flight_record[:pnr_line_revision],		#
			
			:flight_code						=> pnr_flight_record[:flight_code],					# AKA Flight number.
			:start_date							=> pnr_flight_record[:depart_date],					# Departure date and time.
			:end_date								=> pnr_flight_record[:arrive_date],					# Arrival date and time.
			
			:depart_airport_id			=> pnr_flight_record[:depart_airport_id],
			:depart_airport_code		=> pnr_flight_record[:depart_airport_code],	# Airport code on a flight element does not get saved but exists as an instance variable.
			:depart_terminal				=> pnr_flight_record[:depart_terminal],
			
			:arrive_airport_id			=> pnr_flight_record[:arrive_airport_id],
			:arrive_airport_code		=> pnr_flight_record[:arrive_airport_code],	# Airport code on a flight element does not get saved but exists as an instance variable.
			:arrive_terminal				=> pnr_flight_record[:arrive_terminal]		
			
		}
		
	end
	
  
  def self.copy_file_to_folder( file_name, to_folder = nil, from_folder = nil )
    
    begin
      
      to_folder   ||= :failed
      from_folder ||= CRM[:pnr_folder_path] || ''
      copy_from     = from_folder	/ file_name
      copy_to       = to_folder.is_a?(Symbol) ? ( from_folder	/ to_folder ) : to_folder
      
      FileUtils.copy copy_from, copy_to
      
    rescue Exception => reason_for_failure
      Pnr.logger.error " Tried to copy the problem file to the 'failed' folder but something went wrong #{ reason_for_failure } (Tried to copy from #{ copy_from } to #{ copy_to })"
      return false
    else
      Pnr.logger.info " A copy of the problem file has been placed in #{ copy_to }"
    end
    
    return true
    
  end
  
	
	def self.logger
	
		unless defined?(@@pnr_log)
			@@pnr_log = Merb::Logger.new File.new( Merb.root / "log" / "pnr_import.log", 'a' ), :info
		end
		
		return @@pnr_log
		
	end	
	
end



# Pnr.auto_migrate!		# Warning: Running this will clear the table!




#
# EXAMPLE of typical AIR file contents:
#
=begin

AIR-BLK207;IM;;233;1500012976;1A1203214;001001
AMD 1500000001;1/1;              
GW4464979;1A1203214
MUC1A 3OQC6X002;0101;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;;;;;;;;;;;;;;;;;;;;;;BA NOSYNC
A-
B-BT
C-    / 8888GGSU-8888GGSU----
D-100315;100315;100315
U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 01MAY1315 2055 01MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1 
U-002X;003OGIG;RIO JANEIRO GIG  ;LHR;LONDON LHR       ;BA    0248 S S 15MAY2225 1340 16MAY;HK01;HK01;M ;0;777;;;;1 ;;ET;1115 ;N;;5730;;BR;GB;5 
I-001;01ARMITAGE/JAMESMR;;APSTEPPES TRAVEL 01285 885333 JAMES;;
OSI BA  LMSB
K-
L-
M-
O-
Q-
TKTL20MAR/LONU12102
ENDX

=end
