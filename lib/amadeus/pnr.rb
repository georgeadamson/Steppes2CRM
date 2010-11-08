#
# Helpers for handling Amadeus Interface Record (AIR) files and parsing PNR data out of them.
#

#module PnrUtils

	# Return an array of new AIR files sorted by ascending order of file-updated-date:
	def latest_amadeus_records( since_date = nil, pnr_folder_path = nil )
		
		# Default to import files modified since the last PNR was imported:
		recently_imported_pnr	= Pnr.first( :order => [:file_date.desc] )
		since_date					||= recently_imported_pnr.nil? ? ( -5.days.since(Date.today) ) : recently_imported_pnr.file_date
		
		# Default to the standard PNR AIR folder:
		pnr_folder_path			||= CRM[:pnr_folder_path] || ''
		pnr_search_path				= pnr_folder_path.gsub('\\','/') + '/*.txt'	

		# Create a file object to represent each file path,
		# Filter by files updated since since_date,
		# Sort selected files by last-updated-date:
		return Dir.glob( pnr_search_path ).
			map{    |path| File.new( path ) }.
			select{ |file| file.ctime.to_datetime > since_date }.
			sort{   |a, b| a.ctime.to_datetime <=> b.ctime.to_datetime	}
		
	end


	# Helper for parsing the text of an Amadeus Interface Record (AIR) file containing PNR details.
	# Expects to receive the contents of an AIR file.
	# At time of writing, the AIR files were stored in \\selsvr01\central files\Flights\Flight System\Amadeus\PNR-grabs
	def parse_amadeus_record(air)

		clients = []
		flights = []
		
		# Parse out the important lines from the AIR text:
		data_rows			= air.split(/\n/)
		codes_data		= data_rows.select{ |row| row =~ /^MUC/ }		# Eg: "MUC1A 3OQC6X002;0101;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;LONU12102;91497221;;;;;;;;;;;;;;;;;;;;;;BA NOSYNC"
		expiry_data		= data_rows.select{ |row| row =~ /^TKTL/ }	# Eg: "TKTL20MAR/LONU12102"
		dates_data		= data_rows.select{ |row| row =~ /^D-/ }		# Eg: "D-100315;100315;100315"
		clients_data	= data_rows.select{ |row| row =~ /^I-/ }		# Eg: "I-001;01ARMITAGE/JAMESMR;;APSTEPPES TRAVEL 01285 885333 JAMES;;"
		flights_data	= data_rows.select{ |row| row =~ /^U-/ }		# Eg: "U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 01MAY1315 2055 01MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1"
		
		# Extract the booking date:
		# Important: The year of the booking is required to derive the year of the flight departure and arrival dates.
		pnr_booking_date	= Date.strptime( dates_data.first.slice(2,6), '%y%m%d')	# Eg: 'D-100315;100315;100315' => '2010-03-15'
		
		# Assemble PNR Booking expiry date:
		# TODO: Allow for expiry next year!
		pnr_number					= codes_data.first.slice(6,6)
		pnr_reminder_day		= expiry_data.first.slice(4,2).to_i
		pnr_reminder_month	= Date::Format::ABBR_MONTHS[ expiry_data.first.slice(6,3).downcase ]
		pnr_reminder_date		= Date::civil( pnr_booking_date.year, pnr_reminder_month, pnr_reminder_day )
		
		
		# Extract details of each flight row:
		flights_data.each do |data|
			
			# Parse the data eg: 
			#		U-001X;002OLHR;LONDON LHR       ;GIG;RIO JANEIRO GIG  ;BA    0249 S S 01MAY1315 2055 01MAY;HK01;HK01;M ;0;777;;;;5 ;;ET;1140 ;N;;5730;;GB;BR;1
			#		U-002X;003OGIG;RIO JANEIRO GIG  ;LHR;LONDON LHR       ;BA    0248 S S 15MAY2225 1340 16MAY;HK01;HK01;M ;0;777;;;;1 ;;ET;1115 ;N;;5730;;BR;GB;5 
			
			data = data.split(';')
			
			detail = data[5].strip
			
			flight = {
				
				:pnr_booking_date					=> pnr_booking_date,
				:pnr_number								=> pnr_number,
				:pnr_reminder_day					=> pnr_reminder_day,
				:pnr_reminder_month				=> pnr_reminder_month,
				:pnr_reminder_date				=> pnr_reminder_date,
				
				:airline_code							=> detail.slice(0,2),
				:number										=> detail.slice(0,10).sub( /\s+0*/, ' ' ),	# Eg: 'BA    0249' => 'BA 249'
				:class										=> detail.slice(11,1),
				:detail										=> detail,
				
				:depart_airport_code			=> data[1].slice(-3,3),
				:depart_airport_name			=> data[2].strip,
				:depart_airport_terminal	=> data[14].strip,
				
				:arrive_airport_code			=> data[3].slice(-3,3),
				:arrive_airport_name			=> data[4].strip,
				:arrive_airport_terminal	=> data[24].strip,
				
				:depart_year							=> pnr_booking_date.year,
				:depart_month							=> Date::Format::ABBR_MONTHS[ detail.slice(17,3).downcase ],
				:depart_day								=> detail.slice(15,2).to_i,
				:depart_time							=> detail.slice(20,4),
				:depart_hour							=> detail.slice(20,2).to_i,
				:depart_minute						=> detail.slice(22,2).to_i,
				
				:arrive_year							=> pnr_booking_date.year,
				:arrive_month							=> Date::Format::ABBR_MONTHS[ detail.slice(32,3).downcase ],
				:arrive_day								=> detail.slice(30,2).to_i,
				:arrive_time							=> detail.slice(25,4),
				:arrive_hour							=> detail.slice(25,2).to_i,
				:arrive_minute						=> detail.slice(27,2).to_i
				
			}
			
			
			# Derive complete flight dates and times:
			flight[:depart_date]		= DateTime::civil( flight[:depart_year], flight[:depart_month], flight[:depart_day], flight[:depart_hour], flight[:depart_minute] )
			flight[:arrive_date]		= DateTime::civil( flight[:arrive_year], flight[:arrive_month], flight[:arrive_day], flight[:arrive_hour], flight[:arrive_minute] )
			
			# Increment arrival year when arrival month is earlier than departure month:
			# This is necessary because amadeus does not provide flight year so dates must always be within a year of booking date!
			if flight[:arrive_date].jd < flight[:depart_date].jd
				flight[:arrive_year] += 1
				flight[:arrive_date] = DateTime::civil( flight[:arrive_year], flight[:arrive_month], flight[:arrive_day], flight[:arrive_hour], flight[:arrive_minute] )
			end
			
			# Lookup airports in our database:
			depart_airport = Airport.first( :code => flight[:depart_airport_code] )
			arrive_airport = Airport.first( :code => flight[:arrive_airport_code] )
			flight[:depart_airport_id] = depart_airport ? depart_airport.id : nil
			flight[:arrive_airport_id] = arrive_airport ? arrive_airport.id : nil
			
			# Lookup airline in our database:
			airline = Supplier.first( :kind_id => 1, :code => flight[:airline_code] )
			flight[:airline_id] = airline ? airline.id : nil
			
			flights << flight
			
		end
		
		
		# Parse the client data
		clients_data.each do |data|
			
			data = data.split(';')	
			
			clients << {
				:client_pnr_name => data[1]
			}
			
		end
		
		
		# Return a hash containing all the PNR info:
		return {
			
			:pnr_number					=> pnr_number,
			:pnr_booking_date		=> pnr_booking_date,
			:pnr_reminder_date	=> pnr_reminder_date,
			
			:clients						=> clients,
			:flights						=> flights
		}
		
	end
	

	# Import PNR data from Amadeus AIR files:
	def import_amadeus_records( since_date = nil, pnr_folder_path = nil )
		
		# Fetch array of new AIR files sorted by last-updated-date:
		pnr_files = latest_amadeus_records( since_date, pnr_folder_path )
		
		# Create or update PNR records in our database:
		pnr_files.each do |file|
			
			raw_pnr			= file.read
			parsed_pnr	= parse_amadeus_record( raw_pnr )
			
			# Prepare a hash of attributes to apply to PNR model object:
			pnr_attr		= {
				:name					=> parsed_pnr[:pnr_number],				# AKA pnr number
				:data					=> raw_pnr,
				:booking_date	=> parsed_pnr[:pnr_booking_date],
				:flight_count	=> parsed_pnr[:flights].length,
				:client_count	=> parsed_pnr[:clients].length,
				:file_name		=> File.basename( file.path ),
				:file_date		=> file.ctime.to_datetime					# File updated date
			}

			# Only override the default reminder_date when one has been specified in the PNR:
			pnr_attr[:reminder_date] = parsed_pnr[:pnr_reminder_date] unless parsed_pnr[:pnr_reminder_date].blank?
			
			pnr = Pnr.first( :name => parsed_pnr[:pnr_number] )
			
			if pnr.nil?
				
				pnr = Pnr.new(pnr_attr)
				
				unless pnr.save
					Merb.logger.info("Create failed while importing PNR: #{ pnr.errors }")
				end
				
			elsif file.ctime.to_datetime > pnr.file_date
				
				unless pnr.update(pnr_attr)
					Merb.logger.info("Update failed while importing PNR: #{ pnr.errors }")
				end
				
			end
			
		end
		
	end
	
	
#end



=begin	# Example of typical AIR file contents:

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
