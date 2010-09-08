require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/pnr_spec.rb


describe Pnr do

	before :all do

    #DataMapper.auto_migrate! if Merb.environment == 'test'		

		# Live and Test PNR-Grabs folders:
		@live_pnr_grabs_folder = CRM[:pnr_folder_path]
		@test_pnr_grabs_folder = 'c:/temp/' #Dir.tmpdir               # Or: Dir.tmpdir eg: C:\Users\george\AppData\Local\Temp\2
    Dir.mkdir(@test_pnr_grabs_folder) unless File.exist?(@test_pnr_grabs_folder)

		@air_file_names		= []
		@air_file_paths		= []
		@pnr_numbers			= [ valid_pnr_attributes[:name], 'DUMMY' ]
		
#		Airport.first_or_new(  { :code => 'LHR' }, { :name => 'London Heathrow', :code => 'LHR', :country_id => 1, :city => 'London' } ).save!
#		Airport.first_or_new(  { :code => 'GIG' }, { :name => 'Rio de Janeiro',  :code => 'GIG', :country_id => 1, :city => 'Rio' } ).save!
#		Supplier.first_or_new( { :code => 'BA'  }, { :name => 'British Airways', :code => 'BA',  :country_id => 1, :currency_id => 1, :type_id => 1 } ).save!
		
		
		# Remove any old test PNRs from database:
		Pnr.all( :name => @pnr_numbers ).destroy
		
		# Dummy pnr in the pnrs table:
		pnr           = Pnr.new(valid_pnr_attributes)
		pnr.name      = 'DUMMY'
		pnr.file_name = 'DUMMY.txt'
		pnr.data      = ( pnr.data ||= '' ).gsub( valid_pnr_attributes[:name], 'DUMMY')
		pnr.save!

	end
	
	before :each do
		
		@air_file = valid_pnr_file()
		@pnr      = Pnr.new(valid_pnr_attributes)		
    
	end
	
	after :each do
		
		@air_file_paths.each_with_index do |file_path,index|
			File.delete file_path unless @air_file_names[index].blank? || !File.exist?(file_path)
		end

		# Remove test PNRs from database:
		Pnr.all( :name => @pnr_numbers ).destroy
		
	end

	after :all do
		
		@air_file_paths.each_with_index do |file_path,index|
			File.delete file_path unless @air_file_names[index].blank? || !File.exist?(file_path)
		end
		
		# Remove test PNRs from database:
		#Pnr.all( :name => @pnr_numbers ).destroy

	end
	
	
	
	
	


  it "should be valid" do
		@pnr.should be_valid
  end
	
  it "should require PNR Number" do
		@pnr.name = ''
		@pnr.should_not be_valid
  end
	
  it "should require data" do
		@pnr.data = ''
		@pnr.should_not be_valid
  end
	
	# some tests cause jruby error: DummyDynamicScope.java:49:in `getBackRef': java.lang.RuntimeException: DummyDynamicScope should never be used for backref storage
	
  it "should require booking date" do
		@pnr.booking_date = nil
		@pnr.should_not be_valid
  end

	it "should require file_name" do
		@pnr.file_name = ''
		@pnr.should_not be_valid
	end

	it "should require file_date" do
		@pnr.file_date = nil
		@pnr.should_not be_valid
	end

	it "should require flight_count" do
		@pnr.flight_count = nil
		@pnr.should_not be_valid
	end
	
	#	it "should require client_count" do
	#		@pnr.client_count = nil
	#		@pnr.should_not be_valid
	#	end

	it "should provide a flights method" do
		@pnr.should respond_to(:flights)
	end
	
	it "should provide a flights method containing the correct number of flights" do
		@pnr.flights.should have(2).items
	end
	
	
	
	
	
	describe ".parse_amadeus_record" do
		
		it "should derive hash of attributes from raw pnr data" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data.should have_key(:pnr_number)
		end
		
		it "should parse pnr_number from raw pnr data" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data[:pnr_number].should == valid_pnr_attributes[:name]
		end
		
		it "should parse booking_date from raw pnr data" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data[:pnr_booking_date].should == valid_pnr_attributes[:booking_date]
		end
		
		it "should parse flight_count from raw pnr data" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data[:flights].should have( valid_pnr_attributes[:flight_count] ).items
		end
		
		it "should parse client_count from raw pnr data" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data[:clients].should have( valid_pnr_attributes[:client_count] ).items
		end
		
		it "should derive first_flight_date from raw pnr data" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data[:pnr_first_flight_date].should == valid_pnr_attributes[:first_flight_date]
		end
		
		it "should derive reminder_date from raw pnr data when present" do
			raw_pnr_data = valid_pnr_attributes[:data]
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			parsed_pnr_data[:pnr_reminder_date].should == valid_pnr_attributes[:reminder_date]
		end
		
		it "should derive default reminder_date when not present in raw pnr data" do
			
			CRM[:flight_reminder_period] ||= 21
			default_reminder_date = valid_pnr_attributes[:first_flight_date] - CRM[:flight_reminder_period].to_i
			
			# Remove the ticket reminder line from the raw pnr: 'TKTL20MAR/LONU12102'
			raw_pnr_data    = valid_pnr_attributes[:data].sub( /TKTL.*\n/, '' )
			parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
			
			parsed_pnr_data[:pnr_reminder_date].should == default_reminder_date
			
		end
		
		it "should parse correct attributes for flight 1" do

			raw_pnr_data = valid_pnr_attributes[:data]

			Pnr.parse_amadeus_record(raw_pnr_data)[:flights][0].should satisfy { |f|
        
        f[:pnr_number]              == valid_pnr_attributes[:name] &&
        f[:pnr_booking_date]        == valid_pnr_attributes[:booking_date] &&
        f[:pnr_reminder_date]       == valid_pnr_attributes[:reminder_date] &&
        f[:depart_date]             == valid_pnr_attributes[:first_flight_date] &&

        # The depart_date is the most useful test because the date is actially parsed from a line of flight data.

        # More tests of flight attributes would be ideal!
        f[:supplier_id]             == @supplier.id &&
        f[:depart_airport_code]     == 'LHR' && 
        f[:arrive_airport_code]     == 'GIG'
        
			}

		end
				
		it "should assume flight date is next year when flight month is earlier than booking month" do

      # Parse the pnr data and read the booking date and first flight date:
			raw_pnr_data     = valid_pnr_attributes[:data]
			parsed_pnr_data  = Pnr.parse_amadeus_record(raw_pnr_data)
      old_booking_date = parsed_pnr_data[:pnr_booking_date]
      flight_date      = parsed_pnr_data[:pnr_first_flight_date]

      # Derive a booking month that is AFTER the flight:
      new_booking_date = Date::civil( flight_date.year, flight_date.month + 1, old_booking_date.day )
      old_booking_date_string = old_booking_date.strftime('%y%m%d')  # Eg: "100315"
      new_booking_date_string = new_booking_date.strftime('%y%m%d')  # Eg: "100615"
      
      # Create new raw pnr data (with later booking month) and parse it:
      new_raw_pnr_data = raw_pnr_data.gsub(old_booking_date_string, new_booking_date_string)
			new_parsed_pnr_data = Pnr.parse_amadeus_record(new_raw_pnr_data)
      
      # Original data should assume same year but new data should assume next year:
      parsed_pnr_data[:pnr_first_flight_date].year.should == old_booking_date.year
      new_parsed_pnr_data[:pnr_first_flight_date].year.should == old_booking_date.year + 1

		end

	end

	
	
	describe "apply modified data attribute" do
	
	  it "should update pnr attributes when new data! is applied" do
       
      # Derive the time of the first flight in the format used by amadeus pnr:
      old_datetime  =  @pnr.first_flight_date
      old_time      = "#{ old_datetime.hour   }#{ old_datetime.min }"  # Eg: '1315'
      new_time      = "#{ old_datetime.hour-1 }#{ old_datetime.min }"  # Eg: '1215'
      new_data      = @pnr.data.sub(old_time,new_time)
      
      # Eg: change '1315' to '1215' then call data! to update pnr attributes from raw data:
      @pnr.data!(new_data)
      
      # Compare using ruby time because datetime comparisons get muddled about timezone offsets:
      @pnr.first_flight_date.to_time.should == ( old_datetime.to_time - 1.hours )
	
	  end
	

	  it "should update pnr.flights attributes when new data! is applied" do

      # Locate end_date of first flight in the raw data and modify it:
      old_pnr_date  = '01MAY;'
      new_pnr_date  = '02MAY;'
      old_data      = @pnr.data
      new_data      = @pnr.data.sub(old_pnr_date,new_pnr_date)
        
      @pnr.data! new_data
      
      @pnr.flights.first[:end_date].day.should == 2
	
	  end
	
	end
	
	
	
	
	describe " folders" do
		
		it "should have app_setting that defines the *live* PNR Grabs folder" do
			@live_pnr_grabs_folder.should_not be_blank
		end	
		
		it "should be able to see the *live* PNR Grabs folder" do
			File.exist?( @live_pnr_grabs_folder.gsub('/','\\') ).should be_true
			#File.directory?( @live_pnr_grabs_folder.gsub('/','\\') / '' ).should be_true # Depricated because it fails even when directory exists!
		end	
		
		it "should have permission to list files in the *live* PNR Grabs folder" do
			
			pnr_search_path	= @live_pnr_grabs_folder.gsub('\\','/') / '*.txt'	
			
			# Get array of paths of every file in pnr folder, then
			Dir.glob( pnr_search_path ).should_not be_empty
			
		end
		
		it "should have permission to list files in our test PNR AIR 'Grabs' folder!" do
			
			pnr_search_path	= @test_pnr_grabs_folder.gsub('\\','/') / '*.txt'	
			
			# Get array of paths of every file in pnr folder, then
			Dir.glob( pnr_search_path ).should_not be_empty
			
		end

	end
	
	

	describe ".latest_amadeus_records" do
			
		it "should ignore old PNR AIR files" do
			air_files = Pnr.latest_amadeus_records( Date.today+1, @test_pnr_grabs_folder )
			air_files.should be_empty
		end
		
		it "should find new PNR AIR files" do
			air_files = Pnr.latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			air_files.should have( @air_file_names.length ).items
		end	
		
		it "should find PNR AIR files newer than those in DB" do

			recent_pnr = Pnr.first( :order => [:updated_at.desc] )
			since_date = ( recent_pnr && recent_pnr.updated_at ) ? recent_pnr.updated_at : ( Date.today - 10 )

			air_files = Pnr.latest_amadeus_records( since_date, @test_pnr_grabs_folder )
			air_files.should have( @air_file_names.length ).items
			
		end
		
		it "should read :file_name attr from PNR AIR file" do
			air_files = Pnr.latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			air_files.first[:file_name].should == valid_pnr_attributes[:file_name]
		end
		
		it "should read :file_date attr from PNR AIR file" do
			air_files = Pnr.latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			file_path = @test_pnr_grabs_folder / air_files.first[:file_name]
			air_files.first[:file_date].should == File.mtime(file_path).to_datetime
		end
		
		it "should read :data (contents) from PNR AIR file" do
			air_files = Pnr.latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			air_files.first[:data].should == valid_pnr_attributes[:data]
		end
		
	end
	
	
	describe ".prepare_latest_amadeus_records:" do
		
		it "should prepare new PNR AIR records for import into DB" do
			pnrs = Pnr.prepare_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			pnrs.should have(1).pnr
		end
		
		it "should prepare *new* PNR AIR records that are valid for import" do
			pnrs = Pnr.prepare_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			pnrs.first.new?.should be_true
		end
		
		it "should prepare new PNR AIR records that are valid for import" do
			pnrs = Pnr.prepare_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			#pending "rspec jruby crash fix"		# Pending
			pnrs.first.should be_valid				# Causes crash!
		end
		
	end
	
	
	
	describe ".import_latest_amadeus_records" do
		
		it "should import *new* valid PNR AIR files into DB" do
			pnr_file = valid_pnr_file()
			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			Pnr.all( :name => pnrs.first.number ).should have(1).pnr
		end
		
		it "should skip import of *older* PNR AIR files into DB" do

			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )

			# Modify an attribute of the stored pnr so we can test whether it gets overwritten:
			pnrs.first.data = 'dummy_data'
			pnrs.first.save!

			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			pnrs.first.reload
			pnrs.first.data.should == 'dummy_data'
						
		end
		
		it "should import *newer* PNR AIR files into DB" do

			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			
			# Modify file_date so stored pnr is older and the newer file will be imported:
			pnrs.first.data = 'dummy_data'
			pnrs.first.file_date -= 1 
			pnrs.first.save!
			
			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			pnrs.first.reload
			pnrs.first.data.should_not == 'dummy_data'
			
		end

		it "should update flight_count when importing" do

			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			correct_flight_count = pnrs.first.flight_count
			
			# Modify file_date so stored pnr is older and the newer file will be imported:
			pnrs.first.flight_count = -1
			pnrs.first.file_date -= 1 
			pnrs.first.save!
			
			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			pnrs.first.reload
			pnrs.first.flight_count.should == correct_flight_count
			
		end

		it "should update client_count when importing" do
			
			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			correct_client_count = pnrs.first.client_count
			
			# Modify file_date so stored pnr is older and the newer file will be imported:
			pnrs.first.client_count = -1
			pnrs.first.file_date -= 1 
			pnrs.first.save!
			
			pnrs = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
			pnrs.first.reload
			pnrs.first.client_count.should == correct_client_count
			
		end
	
		
	end
	


	
	
	
	describe "trip-flights:" do
	

	  describe "add flights to new trip" do
  	
      before :each do
  		
	      # Ensure we have suppliers and airports to reference: (Otherwise PNR flights cannot be saved)
	      company = Company.first_or_create()
	      @supplier = Supplier.first_or_create( {:type_id => 1, :code => 'BA' }, { :name => 'British Airways', :code => 'BA',  :country_id => 1, :type_id => 1, :currency_id => 1, :companies_ids => [company.id] } ) #unless Supplier.first( :type_id => 1, :code => 'BA' )
	      @airportA = Airport.first_or_create(  { :code => 'LHR' }, { :name => 'London Heathrow', :code => 'LHR', :country_id => 1, :city => 'London' } )  # unless Airport.first( :code => 'LHR' )
	      @airportB = Airport.first_or_create(  { :code => 'GIG' }, { :name => 'Rio de Janeiro',  :code => 'GIG', :country_id => 1, :city => 'Rio'    } )  # unless Airport.first( :code => 'GIG' )

        @trip = Trip.new(valid_trip_attributes)
        @pnr  = Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder ).first

		    raw_pnr_data     = valid_pnr_attributes[:data]
		    @parsed_pnr_data = Pnr.parse_amadeus_record(raw_pnr_data)
        
      end
      
	    after :each do
	      @trip.destroy
	    end
      



      it "should be testing with a valid trip" do
        @trip.should be_valid
        @pnr.should be_valid
      end
    	
      it "should save valid trip that has no PNRs" do
        @trip.save.should be_true
      end
    	
      it "should save valid trip with 1 PNR (using pnrs<<pnr)" do
        @trip.pnrs << @pnr
        @trip.save.should be_true
        #print @trip.errors.inspect
      end
    	
      it "should save valid trip with 1 PNR and recall correct pnr_numbers method" do
        @trip.pnr_numbers = [@pnr.number]
        @trip.save.should be_true
        @trip.reload
        @trip.pnr_numbers.should == [@pnr.number]
      end
    	  	
      it "should save valid trip with 1 PNR and apply flight elements" do
        # Note: Flights without a handler can only be added by a PNR.
        @trip.save
        @trip.flights.should have(0).trip_elements
        @trip.pnrs << @pnr
        @trip.save.should be_true
        @trip.pnrs.should have(1).pnr
        @trip.reload
        @trip.flights.should have(2).trip_elements
      end
    	  	
      it "should remove flight elements when PNR is removed" do

        @trip.pnrs << @pnr
        @trip.save.should be_true
        @trip.reload
        @trip.pnrs.should have(1).pnr
        @trip.flights.should have(2).trip_elements

        @trip.pnrs.delete @pnr
        @trip.save.should be_true
        @trip.reload
        @trip.pnrs.should have(0).pnr
        @trip.flights.should have(0).trip_elements

      end
          
      it "should not apply flight elements when airline (supplier) is not recognosed" do
        Supplier.first( :code => 'BA' ).destroy!
        @trip.pnrs << @pnr
        @trip.save
        @trip.flights.should have(0).trip_elements
      end

      #  Example of @trip.errors =>                                            {:pnr_numb
      #  ers=>["ABCDEF line 1: Supplier must not be blank, The Airline code was not recog
      #  nised. (Try examining the PNR and ensure the airline has an Airline Code defined
      #   in the System Admin pages), The Departure Airport code was not recognised. (Try
      #   examining the PNR and ensure the airport has an Airport Code defined in the Sys
      #  tem Admin pages)", "ABCDEF line 2: Supplier must not be blank, The Airline code
      #  was not recognised. (Try examining the PNR and ensure the airline has an Airline
      #   Code defined in the System Admin pages), The Arrival Airport code was not recog
      #  nised. (Try examining the PNR and ensure the airport has an Airport Code defined
      #  in the System Admin pages)"]}
    	
      it "should report 1 error when an airline (supplier) is not recognosed" do
        Supplier.first( :code => 'BA' ).destroy!
        #@trip.pnrs << @pnr
        @trip.pnr_numbers = [@pnr.number]
        @trip.save.should be_true
        @trip.errors.should have(1).item
        @trip.errors.inspect.should match(/Airline/i) #|| match(/Supplier must not be blank/i)
      end

      it "should not apply flight elements when airport is not recognosed" do
        Airport.first( :code => 'LHR' ).destroy!
        #@trip.pnrs << @pnr
        @trip.pnr_numbers = [@pnr.number]
        @trip.save
        @trip.errors.should have(1).item
        @trip.flights.should have(0).trip_elements
      end

      it "should report 1 error when an airport is not recognosed" do
        Airport.first( :code => 'LHR' ).destroy!
        #@trip.pnrs << @pnr
        @trip.pnr_numbers = [@pnr.number]
        @trip.save
        @trip.errors.should have(1).item
        @trip.errors.inspect.should match /Airport/
      end

      it "should report 2 errors when airline & airport are not recognosed" do
        Supplier.first( :code => 'BA'  ).destroy! # Airline
        Airport.first(  :code => 'LHR' ).destroy! # Airports
        #@trip.pnrs << @pnr
        @trip.pnr_numbers = [@pnr.number]
        @trip.save
        @trip.errors.should have_at_least(1).items
        @trip.errors.inspect.should match(/Supplier/i) && match(/Airline/i) && match(/Departure Airport/i) && match(/Arrival Airport/i)
      end

  	
      it "should have correct attributes on trip's 1st flight element" do
        
        @trip.pnrs << @pnr
        @trip.save.should be_true
        @trip.reload
        
        flight        = @trip.flights[0]
        parsed_flight = @parsed_pnr_data[:flights][0]

        flight.booking_code.should          == @parsed_pnr_data[:pnr_number]
        flight.booking_reminder.should      == @parsed_pnr_data[:pnr_reminder_date]
        flight.booking_line_number.should   == parsed_flight[:pnr_line_number]
        flight.booking_line_revision.should == parsed_flight[:pnr_line_revision]
        flight.flight_code.should           == parsed_flight[:flight_code]
        flight.depart_airport.code.should   == parsed_flight[:depart_airport_code] 
        flight.arrive_airport.code.should   == parsed_flight[:arrive_airport_code] 
        flight.depart_terminal.should       == parsed_flight[:depart_terminal]
        flight.arrive_terminal.should       == parsed_flight[:arrive_terminal]
        flight.start_date.should            == parsed_flight[:depart_date]
        flight.end_date.should              == parsed_flight[:arrive_date]

      end

    	
      it "should have correct attributes on trip's 2nd flight element" do
        
        @trip.pnrs << @pnr
        @trip.save.should be_true
        @trip.reload
        
        flight        = @trip.flights[1]
        parsed_flight = @parsed_pnr_data[:flights][1]

        flight.booking_code.should          == @parsed_pnr_data[:pnr_number]
        flight.booking_reminder.should      == @parsed_pnr_data[:pnr_reminder_date]
        flight.booking_line_number.should   == parsed_flight[:pnr_line_number]
        flight.booking_line_revision.should == parsed_flight[:pnr_line_revision]
        flight.flight_code.should           == parsed_flight[:flight_code]
        flight.depart_airport.code.should   == parsed_flight[:depart_airport_code] 
        flight.arrive_airport.code.should   == parsed_flight[:arrive_airport_code] 
        flight.depart_terminal.should       == parsed_flight[:depart_terminal]
        flight.arrive_terminal.should       == parsed_flight[:arrive_terminal]
        flight.start_date.should            == parsed_flight[:depart_date]
        flight.end_date.should              == parsed_flight[:arrive_date]
        
      end



      # Just a belt and braces test to ensure that the effects of PNRs on trips remain under control!
      it "should not destroy and recreate PNR flight elements when updating trip" do
        
        @trip.pnr_numbers = [@pnr.number]
        @trip.save.should be_true

        flights_from_pnr = @trip.flights.all( :booking_code => @pnr.number )
        flights_from_pnr.should have(2).trip_elements
        orig_flight      = flights_from_pnr.first
        orig_flight_id   = orig_flight.id
                
        @pnr.save
        @trip.save
        @trip.reload

        flights_from_pnr = @trip.flights.all( :booking_code => @pnr.number )
        flights_from_pnr.should have(2).trip_elements
        flights_from_pnr.first.should    == orig_flight
        flights_from_pnr.first.id.should == orig_flight_id
        
      end


      # This just confirms that normal flights can be modified, before we test PNR-flights next:
      it "should allow non-PNR flight element costs to be modified" do

        @trip.save.should be_true
        flight = @trip.flights.create( valid_flight_attributes )
        flight.attributes = { :cost_per_adult => 1234.56 }
        flight.save.should be_true
        flight.reload
        flight.cost_per_adult.should == 1234.56

      end

      it "should allow PNR flight element costs to be modified" do
        
        @trip.save.should be_true
        @trip.pnr_numbers = [@pnr.number]
        @trip.save.should be_true
        @trip.reload
        @trip.pnr_numbers.should == [@pnr.number]
        @trip.pnr_numbers.should have(1).items

        @pnr.save
        flights_from_pnr = @trip.flights.all( :booking_code => @pnr.number )
        flights_from_pnr.should have(2).trip_elements

        flight = flights_from_pnr.first
        flight.attributes = { :cost_per_adult => 1234.56 }
        flight.handler = flight.supplier
        flight.save.should be_true
        flight.cost_per_adult.should == 1234.56

      end

      it "should allow PNR flight element handler to be modified" do
        
        @trip.pnr_numbers = [@pnr.number]
        @trip.save.should be_true
        @trip.reload

        flights_from_pnr = @trip.flights.all( :booking_code => @pnr.number )
        flights_from_pnr.should have(2).trip_elements

        flight = flights_from_pnr.first
        flight.handler = flight.supplier
        flight.save.should be_true
        flight.reload

        flight.handler.should == flight.supplier
        
      end

    end
    

    

    
	  describe "update trip when pnr data changes" do
	  
	    before :all do
	  
	      # Ensure we have all the lookup tables we need:
	      company = Company.first_or_create()
	      Supplier.create( :name => 'British Airways', :code => 'BA',  :country_id => 1, :type_id => 1, :currency_id => 1, :companies_ids => [company.id] ) unless Supplier.first( :type_id => 1, :code => 'BA' )
	      Supplier.create( :name => 'LAN',             :code => 'LA',  :country_id => 1, :type_id => 1, :currency_id => 1, :companies_ids => [company.id] ) unless Supplier.first( :type_id => 1, :code => 'LA' )
	      Supplier.create( :name => 'Kenya Airways',   :code => 'KQ',  :country_id => 1, :type_id => 1, :currency_id => 1, :companies_ids => [company.id] ) unless Supplier.first( :type_id => 1, :code => 'KQ' )
	      Airport.create(  :name => 'London Heathrow', :code => 'LHR', :country_id => 1, :city => 'London' )  unless Airport.first( :code => 'LHR' )
	      Airport.create(  :name => 'Rio de Janeiro',  :code => 'GIG', :country_id => 1, :city => 'Rio' )     unless Airport.first( :code => 'GIG' )
      
      end
      
      before :each do
        
        Pnr.all( :name => @pnr_numbers ).destroy
        
        @pnr  = Pnr.create(valid_pnr_attributes)
        @trip = Trip.create(valid_trip_attributes)
        #debug "#{ Trip.all.length } Trips", "#{ TripPnr.all.length } TripPnrs", "#{ Pnr.all.length } Pnrs"
      
      end
      
      after :each do
        
        Pnr.all( :name => @pnr_numbers ).destroy
        @trip.trip_elements.destroy
        @trip.destroy
      
      end
   
   
      it "should update trip flights when PNR is updated" do
        
        # Assumes @trip and @pnr ready in database.

        new_data      = updated_pnr_attributes[:data]
        new_day       = Pnr.parse_amadeus_record(new_data )[:flights][0][:arrive_date].day
        old_day       = Pnr.parse_amadeus_record(@pnr.data)[:flights][0][:arrive_date].day
        
        # Apply the 'older' pnr to the trip:
        @trip.pnrs << @pnr
        @trip.save

        @trip.reload
        @trip.flights[0].end_date.day.should == old_day

        # Update the pnr with new data data to trigger update of trip's flight elements:
        @pnr.data! new_data
        @pnr.save
        @pnr.refresh_trip_flights
        @trip.reload

        @trip.flights[0].end_date.day.should == new_day
        
      end
   
      it "should UPDATE trip flights when PNR FILE is updated" do
        
        # Assumes @trip and @pnr ready in database.

        new_data      = updated_pnr_attributes[:data]
        new_day       = Pnr.parse_amadeus_record(new_data )[:flights][0][:arrive_date].day
        old_day       = Pnr.parse_amadeus_record(@pnr.data)[:flights][0][:arrive_date].day
        
        # Apply the 'older' pnr to the trip:
        @trip.pnrs << @pnr
        @trip.save
        @trip.flights[0].end_date.day.should == old_day

        # Save new pnr file in the pnr folder and trigger update of trip's flight elements:
        dummy_pnr_file_with(updated_pnr_attributes)
        Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
        
        @trip.reload
        @trip.flights[0].end_date.day.should == new_day
        
      end
   
      it "should CREATE new trip flights when PNR FILE is updated" do
        
        # Apply the 'older' pnr to the trip:
        @trip.pnrs << @pnr
        @trip.save
        @trip.flights.all( :booking_line_number => 5 ).should have(0).trip_elements
        
        # Save new pnr file in the pnr folder and trigger update of trip's flight elements:
        dummy_pnr_file_with(updated_pnr_attributes)
        Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
        
        @pnr.reload
        @trip.reload
        @trip.flights.all( :booking_code => @pnr.number ).should have(@pnr.flights.length).trip_elements
        @trip.flights.all( :booking_code => @pnr.number, :booking_line_number => 5 ).should have(1).trip_elements
        
      end

      it "should DELETE trip flights that are no longer in pnr when PNR FILE is updated" do
        
        # Apply the 'older' pnr to the trip:
        @trip.pnrs << @pnr
        @trip.save
        @trip.flights.all( :booking_line_number => 2 ).should have(1).trip_elements
        
        # Save new pnr file in the pnr folder and trigger update of trip's flight elements:
        dummy_pnr_file_with(updated_pnr_attributes)
        Pnr.import_latest_amadeus_records( Date.today, @test_pnr_grabs_folder )
        
        @pnr.reload
        @trip.reload
        @trip.flights.all( :booking_code => @pnr.number ).should have(@pnr.flights.length).trip_elements
        @trip.flights.all( :booking_code => @pnr.number, :booking_line_number => 2 ).should have(0).trip_elements
        
      end

	  end
  	


	end
	






	# Helper to generate a pnr file for testing:
  # Note: Use this for creating pnrs files and the after() method will clear them up for you after testing.
	def dummy_pnr_file_with( pnr_attributes = nil )

		@air_file_names		||= []
		@air_file_paths		||= []
		@pnr_numbers			||= []
		pnr_attributes		||= valid_pnr_attributes

		@pnr_numbers			 << pnr_attributes[:name]
		file_name						= pnr_attributes[:file_name]
		file_path						= @test_pnr_grabs_folder / file_name
		file_date						= nil # Date will be set in a moment when file is created.

		unless @air_file_paths.include?(file_path)
			@air_file_names	 << file_name
			@air_file_paths	 << file_path
		end

		File.open( file_path, 'w' ){ |file|

			file.write pnr_attributes[:data]
			file_date = file.mtime.to_datetime
			
		} unless file_name.blank?

		return {
			:file_name	=> file_name,
			:file_date	=> file_date,
			:data				=> pnr_attributes[:data]
		}

	end


	# Helper to generate a VALID pnr file for testing:
	def valid_pnr_file
		dummy_pnr_file_with( valid_pnr_attributes )
	end



	
	
	
	# Helper for outputting simple debug info to the console
	# Eg: debug old_start_date.to_s, @trip.flights[0].start_date.to_s
	#     -->  "2010-05-01T13:15:00+00:00" \n "2010-05-01T13:15:00+00:00"
	def debug(*args)
	  
	  args.map!{ |a| ( a.is_a?(Date) || a.is_a?(DateTime) || a.is_a?(Time) ) ? a.to_s.inspect : a.inspect }
	  
	  print "\\ Debug:\n #{ args.join("\n ") }\n/\n"
	end
  

end
