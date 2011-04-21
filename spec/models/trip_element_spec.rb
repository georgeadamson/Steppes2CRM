require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/trip_element_spec.rb



describe TripElement do
    

  before :all do

    @title        = Title.first_or_create( { :name => 'Mr' }, { :name => 'Mr' } )
    @company      = Company.first_or_create()
    @world_region = WorldRegion.first_or_create( { :name => 'Dummy Region' }, { :name => 'Dummy Region' } )
    @mailing_zone = MailingZone.first_or_create( { :name => 'Dummy Zone'   }, { :name => 'Dummy Zone'   } )
    @country1     = Country.first_or_create( { :name => 'Country 1' }, { :code => 'C1', :name => 'Country 1', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @country2     = Country.first_or_create( { :name => 'Country 2' }, { :code => 'C2', :name => 'Country 2', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @country3     = Country.first_or_create( { :name => 'Country 3' }, { :code => 'C3', :name => 'Country 3', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @client1      = Client.first_or_create(  { :name => 'Client 1'  }, {  :title => @title, :name => 'Client 1', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @client2      = Client.first_or_create(  { :name => 'Client 2'  }, {  :title => @title, :name => 'Client 2', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @client3      = Client.first_or_create(  { :name => 'Client 3'  }, {  :title => @title, :name => 'Client 3', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @trip_element_type = TripElementType.first_or_create( { :code => 'flight' }, { :name => 'Flight', :code => 'flight' } )

    # Prepare options for use when calling the .calc method:
    @options                          = { :string_format => false, :to_currency => false } # This option ensures results are numeric
    @taxes_options                    = @options.merge( :taxes         => true )
    @with_taxes_options               = @options.merge( :with_taxes    => true )
    @biz_supp_options                 = @options.merge( :biz_supp      => true )
    @with_biz_supp_options            = @options.merge( :with_biz_supp => true )
    @with_biz_supp_and_taxes_options  = @options.merge( :with_biz_supp => true, :with_taxes => true )

  end

  before :each do

    client_counts = {
      :adults    => valid_flight_attributes[:adults],    
      :children  => valid_flight_attributes[:children],    
      :infants   => valid_flight_attributes[:infants],    
    }
    
    # Prepare trip and flight with same numbers of travellers:
    @trip     = Trip.create( valid_trip_attributes.merge(client_counts) )
    @flight   = @trip.trip_elements.create(valid_flight_attributes)
    @elem     = @flight

    @elem.margin_type               = '%'
    @elem.biz_supp_margin_type      = '%'
    
    @margin_multiplier              = (100 - @elem.margin) / 100
    @taxes_margin_multiplier        = (100 - @elem.margin) / 100
    @biz_supp_margin_multiplier     = (100 - @elem.biz_supp_margin) / 100
    
    # Some handy pre-calculated values:
    @gross_per_adult                = ( @elem.cost_per_adult  / @margin_multiplier )
    @gross_per_child                = ( @elem.cost_per_child  / @margin_multiplier )
    @gross_per_infant               = ( @elem.cost_per_infant / @margin_multiplier )
    @gross_per_single               = ( @elem.cost_per_single / @margin_multiplier )
    
    @adult_percent_margin           = @gross_per_adult  - @elem.cost_per_adult
    @child_percent_margin           = @gross_per_child  - @elem.cost_per_child
    @infant_percent_margin          = @gross_per_infant - @elem.cost_per_infant
    @single_percent_margin          = @gross_per_single - @elem.cost_per_single

    @adult_biz_supp_percent_margin  = ( @flight.biz_supp_per_adult  / @biz_supp_margin_multiplier ) - @flight.biz_supp_per_adult 
    @child_biz_supp_percent_margin  = ( @flight.biz_supp_per_child  / @biz_supp_margin_multiplier ) - @flight.biz_supp_per_child 
    @infant_biz_supp_percent_margin = ( @flight.biz_supp_per_infant / @biz_supp_margin_multiplier ) - @flight.biz_supp_per_infant
    @single_biz_supp_percent_margin = 0

    @trip.save
    
  end
  
  after :each do
    @trip.trip_clients.destroy
    @trip.trip_countries.destroy
    @elem.destroy
    @trip.destroy
  end
  
  after :all do
    @client1.destroy
    @client2.destroy
    @client3.destroy
    @country1.destroy
    @country2.destroy
    @country3.destroy
    @mailing_zone.destroy
    @world_region.destroy
    @company.destroy
  end
  



  # General belt and braces tests:

  it "should be valid" do

	  @elem.should be_valid

  end

  it "should be testing with valid test objects" do

	  @company.should be_valid
	  @world_region.should be_valid
	  @mailing_zone.should be_valid
	  @country1.should be_valid
	  @country2.should be_valid
	  @country3.should be_valid
	  @client1.should be_valid
	  @client2.should be_valid
	  @client3.should be_valid
	  @trip.should be_valid

  end


  it "should provide correct margin_multipliers" do

    @elem.margin_type           = '%'
    @elem.biz_supp_margin_type  = '%'
    @elem.margin_multiplier.should          == @margin_multiplier                    
    @elem.biz_supp_margin_multiplier.should == @biz_supp_margin_multiplier  

    # Neutral multiplier when margin type is not %
    @elem.margin_type           = ''
    @elem.biz_supp_margin_type  = ''
    @elem.margin_multiplier.should          == 1                             
    @elem.biz_supp_margin_multiplier.should == 1                            

  end


  it "should save and reload cost_per_adult/child/infant etc" do

    @elem.update(
      :cost_per_adult  => 11111,
      :cost_per_child  => 22222,
      :cost_per_infant => 33333,
      :cost_per_single => 44444
    )
    @elem.reload
    @elem.cost_per_adult.should  == 11111
    @elem.cost_per_child.should  == 22222
    @elem.cost_per_infant.should == 33333
    @elem.cost_per_single.should == 44444
    
  end


  it "should save new flight with correct flight times" do

    flight = @trip.trip_elements.new( valid_flight_attributes.merge( :start_time => '10:11', :end_time => '12:13' ) )
    flight.save
    flight.reload
    flight.start_time.should == '10:11'
    flight.end_time.should   == '12:13'
    
  end


  it "should return flight number in upper case" do

    flight = @trip.trip_elements.new( valid_flight_attributes.merge( :flight_code => 'abc123' ) )
    flight.save
    flight.reload
    flight.flight_code.should == 'ABC123'
    
  end


  #  # Test moved to pnr_spec.rb because the test data is already available there.
  #  it "should allow PNR flight element costs to be modified" do
  #
  #    pnr = Pnr.new(valid_pnr_attributes)
  #    
  #    @trip.pnr_numbers = [pnr.number]
  #    @trip.save.should be_true
  #    @trip.reload
  #    @trip.pnr_numbers.should == [pnr.number]
  #    @trip.pnr_numbers.should have(1).items
  #    @trip.flights.all( :booking_code => valid_pnr_attributes[:name] ).should have(1).trip_element
  #
  #  end


  it "should save and reload start/end_time without messing up timezones" do

    # This may only be a problem during BST!
    @elem.start_time              =  "08:10"
    @elem.end_time                =  "12:50"
    @elem.start_time.should       == "08:10"
    @elem.end_time.should         == "12:50"
	  @elem.save.should be_true
    @elem.reload
    @elem.start_time.should       == "08:10"
    @elem.end_time.should         == "12:50"

    # This may only be a problem during BST!
    @elem.start_time              =  "13:15"
    @elem.end_time                =  "14:30"
    @elem.start_date              =  DateTime.civil( 2010, 5, 1,  13, 15, 0, 0 )
    @elem.end_date                =  DateTime.civil( 2010, 6, 10, 14, 30, 0, 0 )
    @elem.start_time.should       == "13:15"
    @elem.end_time.should         == "14:30"
    @elem.start_date.to_s.should  == "2010-05-01T13:15:00+00:00" # No +01:00 timezone offset.
	  @elem.save.should be_true
    @elem.reload
    @elem.start_time.should       == "13:15"
    @elem.end_time.should         == "14:30"
    
  end


  it "should save and reload start/end_date without messing up timezones" do

    # This may only be a problem during BST!
    @elem.start_time              =  "13:15"
    @elem.end_time                =  "14:30"
    @elem.start_date = DateTime.civil( 2010, 5, 1,  13, 15, 0, 0 )
    @elem.end_date   = DateTime.civil( 2010, 6, 10, 14, 30, 0, 0 )
    @elem.start_date.to_s.should      == "2010-05-01T13:15:00+00:00" # No +01:00 timezone offset.
    @elem.end_date.to_s.should        == "2010-06-10T14:30:00+00:00" # No +01:00 timezone offset.
	  @elem.save.should be_true
    @elem.reload
    @elem.start_date.to_s.should      == "2010-05-01T13:15:00+00:00" # No +01:00 timezone offset.
    @elem.end_date.to_s.should        == "2010-06-10T14:30:00+00:00" # No +01:00 timezone offset.
    
  end
  
  it "should save and reload late start/end_time without changing date to next day" do
    
    # This may only be a problem during BST!
    @elem.start_time              =  "23:45"
    @elem.end_time                =  "01:50"
    @elem.start_time.should       == "23:45"
    @elem.end_time.should         == "01:50"
	  @elem.save.should be_true
    @elem.reload
    @elem.start_time.should       == "23:45"
    @elem.end_time.should         == "01:50"
    
    # This may only be a problem during BST!
    @elem.start_time              =  "23:45"
    @elem.end_time                =  "06:45"
    @elem.start_date              =  "01/05/2010"
    @elem.end_date                =  "10/06/2010"
    @elem.start_time.should       == "23:45"
    @elem.end_time.should         == "06:45"
    @elem.start_date.to_s.should  == "2010-05-01T23:45:00+00:00" # Expecting no +01:00 timezone offset.
    @elem.end_date.to_s.should    == "2010-06-10T06:45:00+00:00" # Expecting no +01:00 timezone offset.
	  @elem.save.should be_true
    @elem.reload
    @elem.start_time.should       == "23:45"
    @elem.end_time.should         == "06:45"
    
    @elem.attributes = {
      :start_date => "28/07/2011",
      :start_time => "23:45",
      :end_date   => "29/07/2011",
      :end_time   => "06:45"
    }

    @elem.start_time.should       == "23:45"
    @elem.end_time.should         == "06:45"
    @elem.start_date.to_s.should  == "2011-07-28T23:45:00+00:00" # Expecting no +01:00 timezone offset.
    @elem.end_date.to_s.should    == "2011-07-29T06:45:00+00:00" # Expecting no +01:00 timezone offset.
    

  end

  it "should derive arrive_next_day flag correctly" do

    @elem.start_date = Time.now.to_datetime
    @elem.end_date   = Time.now.to_datetime
    @elem.save.should be_true
    @elem.arrive_next_day.should be_false    

    @elem.start_date = Time.now.to_datetime
    @elem.end_date   = (Time.now + 1.day ).to_datetime
    @elem.save.should be_true
    @elem.arrive_next_day.should be_true

  end



  

  describe ".calc" do    
    
    it "should calculate daily local  net    PER adult/child/infant/single (& test formatting options)" do
      
      # Test the simplest calculated values first:
      sf = false
      @elem.calc( :daily, :local, :net, :per, :adult,  :string_format => sf ).should match_currency @elem.cost_per_adult
      @elem.calc( :daily, :local, :net, :per, :child,  :string_format => sf ).should match_currency @elem.cost_per_child
      @elem.calc( :daily, :local, :net, :per, :infant, :string_format => sf ).should match_currency @elem.cost_per_infant
      @elem.calc( :daily, :local, :net, :per, :single, :string_format => sf ).should match_currency @elem.cost_per_single
      
      # Ensure the string_format option works too, on the same calculations:
      sf = "%.2f"
      @elem.calc( :daily, :local, :net, :per, :adult,  :string_format => sf ).should == format( sf, @elem.cost_per_adult )
      @elem.calc( :daily, :local, :net, :per, :child,  :string_format => sf ).should == format( sf, @elem.cost_per_child )
      @elem.calc( :daily, :local, :net, :per, :infant, :string_format => sf ).should == format( sf, @elem.cost_per_infant )
      @elem.calc( :daily, :local, :net, :per, :single, :string_format => sf ).should == format( sf, @elem.cost_per_single )
      
    end
    
    
    it "should calculate daily local  MARGIN per adult/child/infant/single (percent & fixed margin)" do
      
      @elem.calc( :daily, :local, :margin, :per, :adult,  @options ).should match_currency @adult_percent_margin
      @elem.calc( :daily, :local, :margin, :per, :child,  @options ).should match_currency @child_percent_margin
      @elem.calc( :daily, :local, :margin, :per, :infant, @options ).should match_currency @infant_percent_margin
      @elem.calc( :daily, :local, :margin, :per, :single, @options ).should match_currency @single_percent_margin
      
      @elem.margin_type = ''
      
      @elem.calc( :daily, :local, :margin, :per, :adult,  @options ).should match_currency @elem.margin
      @elem.calc( :daily, :local, :margin, :per, :child,  @options ).should match_currency @elem.margin
      @elem.calc( :daily, :local, :margin, :per, :infant, @options ).should match_currency @elem.margin
      @elem.calc( :daily, :local, :margin, :per, :single, @options ).should match_currency 0
      
    end
    
    it "should calculate daily local  GROSS  per adult/child/infant/single (percent & fixed margin)" do
      
      # With percent margin:
      @elem.calc( :daily, :local, :gross, :per, :adult,  @options ).should match_currency @elem.cost_per_adult  + @adult_percent_margin 
      @elem.calc( :daily, :local, :gross, :per, :child,  @options ).should match_currency @elem.cost_per_child  + @child_percent_margin 
      @elem.calc( :daily, :local, :gross, :per, :infant, @options ).should match_currency @elem.cost_per_infant + @infant_percent_margin
      @elem.calc( :daily, :local, :gross, :per, :single, @options ).should match_currency @elem.cost_per_single + @single_percent_margin
      
      # With fixed margin:
      @elem.margin_type = ''
      @elem.calc( :daily, :local, :gross, :per, :adult,  @options ).should match_currency @elem.cost_per_adult  + @elem.margin
      @elem.calc( :daily, :local, :gross, :per, :child,  @options ).should match_currency @elem.cost_per_child  + @elem.margin
      @elem.calc( :daily, :local, :gross, :per, :infant, @options ).should match_currency @elem.cost_per_infant + @elem.margin
      @elem.calc( :daily, :local, :gross, :per, :single, @options ).should match_currency @elem.cost_per_single + 0
      
    end
    
    
    it "should calculate daily ACTUAL net    per adult/child/infant/single" do
      
      @elem.calc( :daily, :actual, :net, :per, :adult,  @options ).should match_currency @elem.cost_per_adult  / @elem.exchange_rate
      @elem.calc( :daily, :actual, :net, :per, :child,  @options ).should match_currency @elem.cost_per_child  / @elem.exchange_rate
      @elem.calc( :daily, :actual, :net, :per, :infant, @options ).should match_currency @elem.cost_per_infant / @elem.exchange_rate
      @elem.calc( :daily, :actual, :net, :per, :single, @options ).should match_currency @elem.cost_per_single / @elem.exchange_rate
      
    end
    
    
    it "should calculate TOTAL actual net    per adult/child/infant/single" do
      
      @elem.calc( :total, :local, :net, :per, :adult,  @options ).should match_currency @elem.cost_per_adult  * @elem.days
      @elem.calc( :total, :local, :net, :per, :child,  @options ).should match_currency @elem.cost_per_child  * @elem.days
      @elem.calc( :total, :local, :net, :per, :infant, @options ).should match_currency @elem.cost_per_infant * @elem.days
      @elem.calc( :total, :local, :net, :per, :single, @options ).should match_currency @elem.cost_per_single * @elem.days
      
    end
    
    
    it "should calculate daily local  net    ALL adults/children/infants/singles" do
      
      @elem.calc( :daily, :local, :net, :all, :adult,  @options ).should match_currency @elem.cost_per_adult  * @elem.adults
      @elem.calc( :daily, :local, :net, :all, :child,  @options ).should match_currency @elem.cost_per_child  * @elem.children
      @elem.calc( :daily, :local, :net, :all, :infant, @options ).should match_currency @elem.cost_per_infant * @elem.infants
      @elem.calc( :daily, :local, :net, :all, :single, @options ).should match_currency @elem.cost_per_single * @elem.singles
      
      # Same as above but with alternative more readable syntax:
      @elem.calc( :daily, :local, :cost, :for_all, :adults,   @options ).should match_currency @elem.cost_per_adult  * @elem.adults
      @elem.calc( :daily, :local, :cost, :for_all, :children, @options ).should match_currency @elem.cost_per_child  * @elem.children
      @elem.calc( :daily, :local, :cost, :for_all, :infants,  @options ).should match_currency @elem.cost_per_infant * @elem.infants
      @elem.calc( :daily, :local, :cost, :for_all, :singles,  @options ).should match_currency @elem.cost_per_single * @elem.singles
      
    end
    
    
    it "should calculate daily local  net    ALL travellers" do
      
      adult_total  = @elem.calc( :daily, :local, :cost, :for_all, :adults,   @options )
      child_total  = @elem.calc( :daily, :local, :cost, :for_all, :children, @options )
      infant_total = @elem.calc( :daily, :local, :cost, :for_all, :infants,  @options )
      single_total = @elem.calc( :daily, :local, :cost, :for_all, :singles,  @options )
      
      # These first tests are the same as the previous example:
      adult_total.should  match_currency @elem.cost_per_adult  * @elem.adults
      child_total.should  match_currency @elem.cost_per_child  * @elem.children
      infant_total.should match_currency @elem.cost_per_infant * @elem.infants
      single_total.should match_currency @elem.cost_per_single * @elem.singles
      
      travellers_total = adult_total + child_total + infant_total + single_total
      
      # a fairly complex calc scenario:
      @elem.calc( :daily, :local, :cost, :for_all, :travellers, @options ).should match_currency travellers_total
      
    end
    
    
    it "should calculate TOTAL ACTUAL GROSS  ALL adults/children/infants/singles" do
      
      # Prepare expected values:
      adult_expected  = @gross_per_adult  / @elem.exchange_rate * @elem.adults   * @elem.days
      child_expected  = @gross_per_child  / @elem.exchange_rate * @elem.children * @elem.days
      infant_expected = @gross_per_infant / @elem.exchange_rate * @elem.infants  * @elem.days
      single_expected = @gross_per_single / @elem.exchange_rate * @elem.singles  * @elem.days
      
      # a fairly complex calc scenario:
      adult_total  = @elem.calc( :total, :actual, :gross, :all, :adults,   @options )
      child_total  = @elem.calc( :total, :actual, :gross, :all, :children, @options )
      infant_total = @elem.calc( :total, :actual, :gross, :all, :infants,  @options )
      single_total = @elem.calc( :total, :actual, :gross, :all, :singles,  @options )
      
      adult_total.should  match_currency adult_expected
      child_total.should  match_currency child_expected
      infant_total.should match_currency infant_expected
      single_total.should match_currency single_expected
      
    end
    
    
    it "should calculate TOTAL ACTUAL GROSS  ALL travellers" do
      
      adult_total  = ( @elem.cost_per_adult  + @adult_percent_margin  ) / @elem.exchange_rate * @elem.adults   * @elem.days 
      child_total  = ( @elem.cost_per_child  + @child_percent_margin  ) / @elem.exchange_rate * @elem.children * @elem.days 
      infant_total = ( @elem.cost_per_infant + @infant_percent_margin ) / @elem.exchange_rate * @elem.infants  * @elem.days 
      single_total = ( @elem.cost_per_single + @single_percent_margin ) / @elem.exchange_rate * @elem.singles  * @elem.days 
      
      travellers_total = adult_total + child_total + infant_total + single_total
      
      # a fairly complex calc scenario:
      @elem.calc( :total, :actual, :gross, :all, :travellers, @options ).should match_currency travellers_total
      
    end
    
    
    
    
    
    
    
    
    
    describe " BIZ SUPP" do    
      
      it "should calculate daily local  net    per adult/child/infant/single BIZ SUPP" do
        
        # Same tests as before but now just biz_supp:
        @flight.calc( :daily, :local, :net, :per, :adult,  @biz_supp_options ).should match_currency @flight.biz_supp_per_adult
        @flight.calc( :daily, :local, :net, :per, :child,  @biz_supp_options ).should match_currency @flight.biz_supp_per_child
        @flight.calc( :daily, :local, :net, :per, :infant, @biz_supp_options ).should match_currency @flight.biz_supp_per_infant
        @flight.calc( :daily, :local, :net, :per, :single, @biz_supp_options ).should match_currency 0
        
      end
      
      
      it "should calculate daily local  MARGIN per adult/child/infant/single BIZ SUPP (percent & fixed margin)" do
        
        # With percent margin:
        @flight.calc( :daily, :local, :margin, :per, :adult,  @biz_supp_options ).should match_currency @adult_biz_supp_percent_margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @biz_supp_options ).should match_currency @child_biz_supp_percent_margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @biz_supp_options ).should match_currency @infant_biz_supp_percent_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @biz_supp_options ).should match_currency @single_biz_supp_percent_margin
        
        # With fixed margin:
        @flight.biz_supp_margin_type = ''
        @flight.calc( :daily, :local, :margin, :per, :adult,  @biz_supp_options ).should match_currency @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @biz_supp_options ).should match_currency @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @biz_supp_options ).should match_currency @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @biz_supp_options ).should match_currency 0
        
      end
      
      
      it "should calculate daily local  GROSS  per adult/child/infant/single BIZ SUPP (percent & fixed margin)" do
        
        # With percent margin:
        @flight.calc( :daily, :local, :gross, :per, :adult,  @biz_supp_options ).should match_currency @flight.biz_supp_per_adult  / @biz_supp_margin_multiplier
        @flight.calc( :daily, :local, :gross, :per, :child,  @biz_supp_options ).should match_currency @flight.biz_supp_per_child  / @biz_supp_margin_multiplier
        @flight.calc( :daily, :local, :gross, :per, :infant, @biz_supp_options ).should match_currency @flight.biz_supp_per_infant / @biz_supp_margin_multiplier
        @flight.calc( :daily, :local, :gross, :per, :single, @biz_supp_options ).should match_currency 0
        
        # With fixed margin:
        @flight.biz_supp_margin_type = ''
        @flight.calc( :daily, :local, :gross, :per, :adult,  @biz_supp_options ).should match_currency @flight.biz_supp_per_adult  + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :gross, :per, :child,  @biz_supp_options ).should match_currency @flight.biz_supp_per_child  + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :gross, :per, :infant, @biz_supp_options ).should match_currency @flight.biz_supp_per_infant + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :gross, :per, :single, @biz_supp_options ).should match_currency 0
        
      end
      
      
      it "should calculate daily ACTUAL net    per adult/child/infant/single BIZ SUPP" do
        
        @flight.calc( :daily, :actual, :net, :per, :adult,  @biz_supp_options ).should match_currency @flight.biz_supp_per_adult  / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :child,  @biz_supp_options ).should match_currency @flight.biz_supp_per_child  / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :infant, @biz_supp_options ).should match_currency @flight.biz_supp_per_infant / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :single, @biz_supp_options ).should match_currency 0
        
      end
      
      
      it "should calculate TOTAL actual net    per adult/child/infant/single BIZ SUPP" do
        
        # This is a trick question because the daily/total argument should not make any difference to biz supp:
        
        adult_total  = @flight.calc( :total, :local, :net, :per, :adult,  @biz_supp_options )
        child_total  = @flight.calc( :total, :local, :net, :per, :child,  @biz_supp_options )
        infant_total = @flight.calc( :total, :local, :net, :per, :infant, @biz_supp_options )
        single_total = @flight.calc( :total, :local, :net, :per, :single, @biz_supp_options )
        
        adult_total.should  match_currency @flight.biz_supp_per_adult 
        child_total.should  match_currency @flight.biz_supp_per_child 
        infant_total.should match_currency @flight.biz_supp_per_infant
        single_total.should match_currency 0.0
        
        travellers_total = adult_total + child_total + infant_total + single_total
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :local, :net, :per, :traveller, @biz_supp_options ).should match_currency travellers_total
        
      end
      
      
      it "should calculate daily local  net    ALL adults/children/infants/singles BIZ SUPP" do
        
        @flight.calc( :daily, :local, :net, :all, :adult,  @biz_supp_options ).should match_currency @flight.biz_supp_per_adult  * @flight.adults
        @flight.calc( :daily, :local, :net, :all, :child,  @biz_supp_options ).should match_currency @flight.biz_supp_per_child  * @flight.children
        @flight.calc( :daily, :local, :net, :all, :infant, @biz_supp_options ).should match_currency @flight.biz_supp_per_infant * @flight.infants
        @flight.calc( :daily, :local, :net, :all, :single, @biz_supp_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL adults/children/infants/singles BIZ SUPP" do
        
        # Manually prepare the expected values:
        adult_expected  = @flight.biz_supp_per_adult  * @flight.adults   / @flight.exchange_rate / @biz_supp_margin_multiplier
        child_expected  = @flight.biz_supp_per_child  * @flight.children / @flight.exchange_rate / @biz_supp_margin_multiplier
        infant_expected = @flight.biz_supp_per_infant * @flight.infants  / @flight.exchange_rate / @biz_supp_margin_multiplier
        single_expected = 0.0
        
        # Run the test calculations:
        adult_total  = @flight.calc( :total, :actual, :gross, :all, :adults,   @biz_supp_options ) 
        child_total  = @flight.calc( :total, :actual, :gross, :all, :children, @biz_supp_options ) 
        infant_total = @flight.calc( :total, :actual, :gross, :all, :infants,  @biz_supp_options ) 
        single_total = @flight.calc( :total, :actual, :gross, :all, :singles,  @biz_supp_options ) 
        
        adult_total.should  match_currency adult_expected 
        child_total.should  match_currency child_expected 
        infant_total.should match_currency infant_expected
        single_total.should match_currency single_expected
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers BIZ SUPP" do
        
        # Manually prepare the expected values: (Same as previous example)
        adult_expected  = @flight.biz_supp_per_adult  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.adults   
        child_expected  = @flight.biz_supp_per_child  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.children 
        infant_expected = @flight.biz_supp_per_infant / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.infants  
        single_expected = 0
        
        travellers_total = adult_expected + child_expected + infant_expected + single_expected
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @biz_supp_options ).should match_currency travellers_total
        
      end
      
      
      it "should NOT calculate TOTAL ACTUAL GROSS  ALL travellers BIZ SUPP on non-flight elements" do
        
        # Make test element a non-flight element:
        @elem.type_id = 4 # 4=Accommodation
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @biz_supp_options ).should match_currency 0.0
        
      end
      
      
    end
    
    
    
    
    
    
    describe " INCL BIZ SUPP" do    
      
      it "should calculate daily local  net    per adult/child/infant/single + BIZ SUPP" do
        
        adult_total  = @flight.cost_per_adult 
        child_total  = @flight.cost_per_child 
        infant_total = @flight.cost_per_infant
        single_total = @flight.cost_per_single
        
        # Same tests as before but now including biz_supp:
        @flight.calc( :daily, :local, :net, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total  + @flight.biz_supp_per_adult 
        @flight.calc( :daily, :local, :net, :per, :child,  @with_biz_supp_options ).should match_currency child_total  + @flight.biz_supp_per_child 
        @flight.calc( :daily, :local, :net, :per, :infant, @with_biz_supp_options ).should match_currency infant_total + @flight.biz_supp_per_infant
        @flight.calc( :daily, :local, :net, :per, :single, @with_biz_supp_options ).should match_currency single_total + 0
        
      end
      
      
      it "should calculate daily local  MARGIN per adult/child/infant/single + BIZ SUPP (percent & fixed margin)" do
        
        # This means margin on cost+biz supp:
        
        # With percent margin:
        @flight.calc( :daily, :local, :margin, :per, :adult,  @with_biz_supp_options ).should match_currency @adult_percent_margin  + @adult_biz_supp_percent_margin 
        @flight.calc( :daily, :local, :margin, :per, :child,  @with_biz_supp_options ).should match_currency @child_percent_margin  + @child_biz_supp_percent_margin 
        @flight.calc( :daily, :local, :margin, :per, :infant, @with_biz_supp_options ).should match_currency @infant_percent_margin + @infant_biz_supp_percent_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @with_biz_supp_options ).should match_currency @single_percent_margin + @single_biz_supp_percent_margin
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.margin_type = ''
        @flight.biz_supp_margin_type = ''
        @flight.calc( :daily, :local, :margin, :per, :adult,  @with_biz_supp_options ).should match_currency @flight.margin + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @with_biz_supp_options ).should match_currency @flight.margin + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @with_biz_supp_options ).should match_currency @flight.margin + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @with_biz_supp_options ).should match_currency 0              + 0
        
      end
      
      it "should calculate daily local  GROSS  per adult/child/infant/single + BIZ SUPP (percent & fixed margin)" do
        
        adult_total  = @gross_per_adult  
        child_total  = @gross_per_child  
        infant_total = @gross_per_infant 
        single_total = @gross_per_single 
        
        adult_gross_biz_supp  = ( @flight.biz_supp_per_adult  / @biz_supp_margin_multiplier )
        child_gross_biz_supp  = ( @flight.biz_supp_per_child  / @biz_supp_margin_multiplier )
        infant_gross_biz_supp = ( @flight.biz_supp_per_infant / @biz_supp_margin_multiplier )
        single_gross_biz_supp = 0.0                                                          
        
        # With percent margin:
        @flight.calc( :daily, :local, :gross, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total  + adult_gross_biz_supp 
        @flight.calc( :daily, :local, :gross, :per, :child,  @with_biz_supp_options ).should match_currency child_total  + child_gross_biz_supp 
        @flight.calc( :daily, :local, :gross, :per, :infant, @with_biz_supp_options ).should match_currency infant_total + infant_gross_biz_supp
        @flight.calc( :daily, :local, :gross, :per, :single, @with_biz_supp_options ).should match_currency single_total + single_gross_biz_supp     
        
        # With fixed margin:
        @flight.biz_supp_margin_type = ''
        @flight.calc( :daily, :local, :gross, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total  + @flight.biz_supp_per_adult  + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :gross, :per, :child,  @with_biz_supp_options ).should match_currency child_total  + @flight.biz_supp_per_child  + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :gross, :per, :infant, @with_biz_supp_options ).should match_currency infant_total + @flight.biz_supp_per_infant + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :gross, :per, :single, @with_biz_supp_options ).should match_currency single_total + 0.0                                                 
        
      end
      
      
      it "should calculate daily ACTUAL net    per adult/child/infant/single + BIZ SUPP" do
        
        adult_total  = @flight.cost_per_adult  / @flight.exchange_rate
        child_total  = @flight.cost_per_child  / @flight.exchange_rate
        infant_total = @flight.cost_per_infant / @flight.exchange_rate
        single_total = @flight.cost_per_single / @flight.exchange_rate
        
        @flight.calc( :daily, :actual, :net, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total  + @flight.biz_supp_per_adult  / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :child,  @with_biz_supp_options ).should match_currency child_total  + @flight.biz_supp_per_child  / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :infant, @with_biz_supp_options ).should match_currency infant_total + @flight.biz_supp_per_infant / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :single, @with_biz_supp_options ).should match_currency single_total + 0.0
        
      end
      
      
      it "should calculate TOTAL actual net    per adult/child/infant/single + BIZ SUPP" do
        
        # This is a trick question because the daily/total argument should not make any difference to biz supp:
        
        adult_total  = @flight.cost_per_adult  / @flight.exchange_rate * @flight.days
        child_total  = @flight.cost_per_child  / @flight.exchange_rate * @flight.days
        infant_total = @flight.cost_per_infant / @flight.exchange_rate * @flight.days
        single_total = @flight.cost_per_single / @flight.exchange_rate * @flight.days
        
        @flight.calc( :total, :actual, :net, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total  + @flight.biz_supp_per_adult  / @flight.exchange_rate
        @flight.calc( :total, :actual, :net, :per, :child,  @with_biz_supp_options ).should match_currency child_total  + @flight.biz_supp_per_child  / @flight.exchange_rate
        @flight.calc( :total, :actual, :net, :per, :infant, @with_biz_supp_options ).should match_currency infant_total + @flight.biz_supp_per_infant / @flight.exchange_rate
        @flight.calc( :total, :actual, :net, :per, :single, @with_biz_supp_options ).should match_currency single_total + 0.0
        
      end
      
      
      it "should calculate daily local  net    ALL adults/children/infants/singles + BIZ SUPP" do
        
        adult_total  = @flight.cost_per_adult  * @flight.adults
        child_total  = @flight.cost_per_child  * @flight.children
        infant_total = @flight.cost_per_infant * @flight.infants
        single_total = @flight.cost_per_single * @flight.singles
        
        @flight.calc( :daily, :local, :net, :all, :adult,  @with_biz_supp_options ).should match_currency adult_total  + @flight.biz_supp_per_adult  * @flight.adults
        @flight.calc( :daily, :local, :net, :all, :child,  @with_biz_supp_options ).should match_currency child_total  + @flight.biz_supp_per_child  * @flight.children
        @flight.calc( :daily, :local, :net, :all, :infant, @with_biz_supp_options ).should match_currency infant_total + @flight.biz_supp_per_infant * @flight.infants
        @flight.calc( :daily, :local, :net, :all, :single, @with_biz_supp_options ).should match_currency single_total + 0
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL adults/children/infants/singles + BIZ SUPP" do
        
        adult_total  = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total  = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = @flight.biz_supp_per_adult  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.adults  
        child_biz_supp_total  = @flight.biz_supp_per_child  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.children
        infant_biz_supp_total = @flight.biz_supp_per_infant / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.infants 
        single_biz_supp_total = 0
        
        # a fairly complex calc scenario:
        @flight.calc( :total, :actual, :gross, :all, :adults,   @with_biz_supp_options ).should match_currency adult_total  + adult_biz_supp_total
        @flight.calc( :total, :actual, :gross, :all, :children, @with_biz_supp_options ).should match_currency child_total  + child_biz_supp_total
        @flight.calc( :total, :actual, :gross, :all, :infants,  @with_biz_supp_options ).should match_currency infant_total + infant_biz_supp_total
        @flight.calc( :total, :actual, :gross, :all, :singles,  @with_biz_supp_options ).should match_currency single_total + single_biz_supp_total
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers + BIZ SUPP" do
        
        adult_total  = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total  = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = @flight.biz_supp_per_adult  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.adults   
        child_biz_supp_total  = @flight.biz_supp_per_child  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.children 
        infant_biz_supp_total = @flight.biz_supp_per_infant / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.infants  
        single_biz_supp_total = 0
        
        travellers_total = ( adult_total  + adult_biz_supp_total  ) +
        ( child_total  + child_biz_supp_total  ) +
        ( infant_total + infant_biz_supp_total ) +
        ( single_total + single_biz_supp_total )
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @with_biz_supp_options ).should match_currency travellers_total
        
      end
      
      
      it "should NOT calculate TOTAL ACTUAL GROSS  ALL travellers + BIZ SUPP on non-flight elements" do
        
        # Make test element a non-flight element:
        @elem.type_id = 4 # 4=Accommodation
        
        adult_total  = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total  = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = 0 
        child_biz_supp_total  = 0
        infant_biz_supp_total = 0
        single_biz_supp_total = 0
        
        travellers_total = ( adult_total  + adult_biz_supp_total  ) +
        ( child_total  + child_biz_supp_total  ) +
        ( infant_total + infant_biz_supp_total ) +
        ( single_total + single_biz_supp_total )
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @with_biz_supp_options ).should match_currency travellers_total
        
      end
      
      
    end
    
    
    
    
    
    
    describe " TAXES" do    
      
      it "should calculate daily local  net    per adult/child/infant/single TAXES" do
        
        # Same tests as before but now just taxes:
        @flight.calc( :daily, :local, :net, :per, :adult,  @taxes_options ).should match_currency @flight.taxes_per_adult
        @flight.calc( :daily, :local, :net, :per, :child,  @taxes_options ).should match_currency @flight.taxes_per_child
        @flight.calc( :daily, :local, :net, :per, :infant, @taxes_options ).should match_currency @flight.taxes_per_infant
        @flight.calc( :daily, :local, :net, :per, :single, @taxes_options ).should match_currency @flight.taxes_per_single
        
      end
      
      
      it "should calculate daily local  MARGIN per adult/child/infant/single TAXES (percent & fixed margin)" do
        
        # With percent margin:
        tax_margin = ( @flight.taxes / @margin_multiplier ) - @flight.taxes
        @flight.calc( :daily, :local, :margin, :per, :adult,  @taxes_options ).should match_currency tax_margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @taxes_options ).should match_currency tax_margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @taxes_options ).should match_currency tax_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @taxes_options ).should match_currency 0.0
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.taxes_margin_type = ''
        @flight.calc( :daily, :local, :margin, :per, :adult,  @taxes_options ).should match_currency 0.0
        @flight.calc( :daily, :local, :margin, :per, :child,  @taxes_options ).should match_currency 0.0
        @flight.calc( :daily, :local, :margin, :per, :infant, @taxes_options ).should match_currency 0.0
        @flight.calc( :daily, :local, :margin, :per, :single, @taxes_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate daily local  GROSS  per adult/child/infant/single TAXES (percent & fixed margin)" do
        
        # With percent margin:
        gross_tax_per_person = ( @flight.taxes / @margin_multiplier )
        @flight.calc( :daily, :local, :gross, :per, :adult,  @taxes_options ).should match_currency gross_tax_per_person 
        @flight.calc( :daily, :local, :gross, :per, :child,  @taxes_options ).should match_currency gross_tax_per_person 
        @flight.calc( :daily, :local, :gross, :per, :infant, @taxes_options ).should match_currency gross_tax_per_person
        @flight.calc( :daily, :local, :gross, :per, :single, @taxes_options ).should match_currency 0.0 
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.taxes_margin_type = ''
        @flight.calc( :daily, :local, :gross, :per, :adult,  @taxes_options ).should match_currency @flight.taxes_per_adult 
        @flight.calc( :daily, :local, :gross, :per, :child,  @taxes_options ).should match_currency @flight.taxes_per_child 
        @flight.calc( :daily, :local, :gross, :per, :infant, @taxes_options ).should match_currency @flight.taxes_per_infant
        @flight.calc( :daily, :local, :gross, :per, :single, @taxes_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate daily ACTUAL net    per adult/child/infant/single TAXES" do
        
        @flight.calc( :daily, :actual, :net, :per, :adult,  @taxes_options ).should match_currency @flight.taxes_per_adult  / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :child,  @taxes_options ).should match_currency @flight.taxes_per_child  / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :infant, @taxes_options ).should match_currency @flight.taxes_per_infant / @flight.exchange_rate
        @flight.calc( :daily, :actual, :net, :per, :single, @taxes_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate TOTAL actual net    per adult/child/infant/single TAXES" do
        
        # This is a trick question because the daily/total argument should not make any difference to biz supp:
        
        @flight.calc( :total, :local, :net, :per, :adult,  @taxes_options ).should match_currency @flight.taxes_per_adult 
        @flight.calc( :total, :local, :net, :per, :child,  @taxes_options ).should match_currency @flight.taxes_per_child 
        @flight.calc( :total, :local, :net, :per, :infant, @taxes_options ).should match_currency @flight.taxes_per_infant
        @flight.calc( :total, :local, :net, :per, :single, @taxes_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate daily local  net    ALL adults/children/infants/singles TAXES" do
        
        @flight.calc( :daily, :local, :net, :all, :adult,  @taxes_options ).should match_currency @flight.taxes_per_adult  * @flight.adults
        @flight.calc( :daily, :local, :net, :all, :child,  @taxes_options ).should match_currency @flight.taxes_per_child  * @flight.children
        @flight.calc( :daily, :local, :net, :all, :infant, @taxes_options ).should match_currency @flight.taxes_per_infant * @flight.infants
        @flight.calc( :daily, :local, :net, :all, :single, @taxes_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL adults/children/infants/singles TAXES" do
        
        # a fairly complex calc scenario:
        @flight.calc( :total, :actual, :gross, :all, :adults,   @taxes_options ).should match_currency @flight.taxes_per_adult  * @flight.adults   / @flight.exchange_rate / @taxes_margin_multiplier
        @flight.calc( :total, :actual, :gross, :all, :children, @taxes_options ).should match_currency @flight.taxes_per_child  * @flight.children / @flight.exchange_rate / @taxes_margin_multiplier
        @flight.calc( :total, :actual, :gross, :all, :infants,  @taxes_options ).should match_currency @flight.taxes_per_infant * @flight.infants  / @flight.exchange_rate / @taxes_margin_multiplier
        @flight.calc( :total, :actual, :gross, :all, :singles,  @taxes_options ).should match_currency 0.0
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers TAXES" do
        
        adult_taxes_total  = @flight.taxes_per_adult  / @flight.exchange_rate / @taxes_margin_multiplier * @flight.adults   
        child_taxes_total  = @flight.taxes_per_child  / @flight.exchange_rate / @taxes_margin_multiplier * @flight.children 
        infant_taxes_total = @flight.taxes_per_infant / @flight.exchange_rate / @taxes_margin_multiplier * @flight.infants  
        single_taxes_total = 0.0
        
        travellers_total = adult_taxes_total + child_taxes_total + infant_taxes_total + single_taxes_total
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @taxes_options ).should match_currency travellers_total
        
      end
      
      
    end
    
    
    
    
    
    
    
    
    describe " INCL TAXES" do    
      
      it "should calculate daily local  net    per adult/child/infant/single + TAXES" do
        
        adult_total  = @flight.cost_per_adult 
        child_total  = @flight.cost_per_child 
        infant_total = @flight.cost_per_infant
        single_total = @flight.cost_per_single
        
        # Same tests as before but now including biz_supp:
        @flight.calc( :daily, :local, :net, :per, :adult,  @with_taxes_options ).should match_currency adult_total  + @flight.taxes 
        @flight.calc( :daily, :local, :net, :per, :child,  @with_taxes_options ).should match_currency child_total  + @flight.taxes 
        @flight.calc( :daily, :local, :net, :per, :infant, @with_taxes_options ).should match_currency infant_total + @flight.taxes
        @flight.calc( :daily, :local, :net, :per, :single, @with_taxes_options ).should match_currency single_total + 0
        
      end
      
      
      it "should calculate daily local  MARGIN per adult/child/infant/single + TAXES (percent & fixed margin)" do
        
        # This means testing margin on cost+taxes...
        
        adult_margin_on_tax  = ( @flight.taxes / @margin_multiplier ) - @flight.taxes
        child_margin_on_tax  = ( @flight.taxes / @margin_multiplier ) - @flight.taxes
        infant_margin_on_tax = ( @flight.taxes / @margin_multiplier ) - @flight.taxes
        single_margin_on_tax = 0
        
        # With percent margin:
        @flight.calc( :daily, :local, :margin, :per, :adult,  @with_taxes_options ).should match_currency @adult_percent_margin  + adult_margin_on_tax
        @flight.calc( :daily, :local, :margin, :per, :child,  @with_taxes_options ).should match_currency @child_percent_margin  + child_margin_on_tax
        @flight.calc( :daily, :local, :margin, :per, :infant, @with_taxes_options ).should match_currency @infant_percent_margin + infant_margin_on_tax
        @flight.calc( :daily, :local, :margin, :per, :single, @with_taxes_options ).should match_currency @single_percent_margin + single_margin_on_tax
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.margin_type = ''
        @flight.calc( :daily, :local, :margin, :per, :adult,  @with_taxes_options ).should match_currency @flight.margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @with_taxes_options ).should match_currency @flight.margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @with_taxes_options ).should match_currency @flight.margin
        @flight.calc( :daily, :local, :margin, :per, :single, @with_taxes_options ).should match_currency 0
        
      end
      
      
      it "should calculate daily local  GROSS  per adult/child/infant/single + TAXES (percent & fixed margin)" do
        
        adult_gross_tax  = ( @flight.taxes / @margin_multiplier )
        child_gross_tax  = ( @flight.taxes / @margin_multiplier )
        infant_gross_tax = ( @flight.taxes / @margin_multiplier )
        single_gross_tax = 0
        
        # With percent margin:
        @flight.calc( :daily, :local, :gross, :per, :adult,  @with_taxes_options ).should match_currency @gross_per_adult  + adult_gross_tax
        @flight.calc( :daily, :local, :gross, :per, :child,  @with_taxes_options ).should match_currency @gross_per_child  + child_gross_tax
        @flight.calc( :daily, :local, :gross, :per, :infant, @with_taxes_options ).should match_currency @gross_per_infant + infant_gross_tax
        @flight.calc( :daily, :local, :gross, :per, :single, @with_taxes_options ).should match_currency @gross_per_single + single_gross_tax
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.margin_type = ''
        @flight.calc( :daily, :local, :gross, :per, :adult,  @with_taxes_options ).should match_currency @flight.cost_per_adult  + @flight.margin + @flight.taxes
        @flight.calc( :daily, :local, :gross, :per, :child,  @with_taxes_options ).should match_currency @flight.cost_per_child  + @flight.margin + @flight.taxes
        @flight.calc( :daily, :local, :gross, :per, :infant, @with_taxes_options ).should match_currency @flight.cost_per_infant + @flight.margin + @flight.taxes
        @flight.calc( :daily, :local, :gross, :per, :single, @with_taxes_options ).should match_currency @flight.cost_per_single + 0
        
      end
      
      
      it "should calculate daily ACTUAL net    per adult/child/infant/single + TAXES" do
        
        adult_total  = @flight.cost_per_adult  / @flight.exchange_rate
        child_total  = @flight.cost_per_child  / @flight.exchange_rate
        infant_total = @flight.cost_per_infant / @flight.exchange_rate
        single_total = @flight.cost_per_single / @flight.exchange_rate
        
        @flight.calc( :daily, :actual, :net, :per, :adult,  @with_taxes_options ).should match_currency adult_total  + ( @flight.taxes / @flight.exchange_rate )
        @flight.calc( :daily, :actual, :net, :per, :child,  @with_taxes_options ).should match_currency child_total  + ( @flight.taxes / @flight.exchange_rate )
        @flight.calc( :daily, :actual, :net, :per, :infant, @with_taxes_options ).should match_currency infant_total + ( @flight.taxes / @flight.exchange_rate )
        @flight.calc( :daily, :actual, :net, :per, :single, @with_taxes_options ).should match_currency single_total + 0
        
      end
      
      
      it "should calculate TOTAL actual net    per adult/child/infant/single + TAXES" do
        
        # This is a trick question because the daily/total argument should not make any difference to taxes:
        
        adult_total  = @flight.cost_per_adult  / @flight.exchange_rate * @flight.days
        child_total  = @flight.cost_per_child  / @flight.exchange_rate * @flight.days
        infant_total = @flight.cost_per_infant / @flight.exchange_rate * @flight.days
        single_total = @flight.cost_per_single / @flight.exchange_rate * @flight.days
        
        @flight.calc( :total, :actual, :net, :per, :adult,  @with_taxes_options ).should match_currency adult_total  + ( @flight.taxes / @flight.exchange_rate )
        @flight.calc( :total, :actual, :net, :per, :child,  @with_taxes_options ).should match_currency child_total  + ( @flight.taxes / @flight.exchange_rate )
        @flight.calc( :total, :actual, :net, :per, :infant, @with_taxes_options ).should match_currency infant_total + ( @flight.taxes / @flight.exchange_rate )
        @flight.calc( :total, :actual, :net, :per, :single, @with_taxes_options ).should match_currency single_total + 0
        
      end
      
      
      it "should calculate daily local  net    ALL adults/children/infants/singles + TAXES" do
        
        adult_total  = @flight.cost_per_adult  * @flight.adults
        child_total  = @flight.cost_per_child  * @flight.children
        infant_total = @flight.cost_per_infant * @flight.infants
        single_total = @flight.cost_per_single * @flight.singles
        
        @flight.calc( :daily, :local, :net, :all, :adult,  @with_taxes_options ).should match_currency adult_total  + @flight.taxes_per_adult  * @flight.adults
        @flight.calc( :daily, :local, :net, :all, :child,  @with_taxes_options ).should match_currency child_total  + @flight.taxes_per_child  * @flight.children
        @flight.calc( :daily, :local, :net, :all, :infant, @with_taxes_options ).should match_currency infant_total + @flight.taxes_per_infant * @flight.infants
        @flight.calc( :daily, :local, :net, :all, :single, @with_taxes_options ).should match_currency single_total + 0
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL adults/children/infants/singles + TAXES" do
        
        adult_total  = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total  = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_total_taxes  = @flight.taxes_per_adult  / @flight.exchange_rate / @taxes_margin_multiplier * @flight.adults  
        child_total_taxes  = @flight.taxes_per_child  / @flight.exchange_rate / @taxes_margin_multiplier * @flight.children
        infant_total_taxes = @flight.taxes_per_infant / @flight.exchange_rate / @taxes_margin_multiplier * @flight.infants 
        single_total_taxes = 0
        
        
        # a fairly complex calc scenario:
        @flight.calc( :total, :actual, :gross, :all, :adults,   @with_taxes_options ).should match_currency adult_total  + adult_total_taxes 
        @flight.calc( :total, :actual, :gross, :all, :children, @with_taxes_options ).should match_currency child_total  + child_total_taxes 
        @flight.calc( :total, :actual, :gross, :all, :infants,  @with_taxes_options ).should match_currency infant_total + infant_total_taxes
        @flight.calc( :total, :actual, :gross, :all, :singles,  @with_taxes_options ).should match_currency single_total + single_total_taxes
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers + TAXES" do
        
        adult_total  = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total  = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_total_taxes  = @flight.taxes_per_adult  / @flight.exchange_rate / @taxes_margin_multiplier * @flight.adults  
        child_total_taxes  = @flight.taxes_per_child  / @flight.exchange_rate / @taxes_margin_multiplier * @flight.children
        infant_total_taxes = @flight.taxes_per_infant / @flight.exchange_rate / @taxes_margin_multiplier * @flight.infants 
        single_total_taxes = 0
        
        travellers_total =( adult_total  + adult_total_taxes  ) +
        ( child_total  + child_total_taxes  ) +
        ( infant_total + infant_total_taxes ) +
        ( single_total + single_total_taxes )
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @with_taxes_options ).should match_currency travellers_total
        
      end
      
      
    end
    
    
    
    
    
    
    
    
    describe " INCL BIZ SUPP & TAXES" do    
      
      it "should calculate daily local  net    per adult/child/infant/single + BIZ SUPP + TAXES" do
        
        # Same tests as before but now including biz_supp:
        @flight.calc( :daily, :local, :net, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_adult  + @flight.biz_supp_per_adult  + @flight.taxes
        @flight.calc( :daily, :local, :net, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_child  + @flight.biz_supp_per_child  + @flight.taxes
        @flight.calc( :daily, :local, :net, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_infant + @flight.biz_supp_per_infant + @flight.taxes
        @flight.calc( :daily, :local, :net, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_single + 0                           + 0
        
      end
      
      
      it "should calculate daily local  MARGIN per adult/child/infant/single + BIZ SUPP + TAXES (percent & fixed margin)" do
        
        # This means margin on cost+bizsupp+taxes:
        
        # With percent margin:
        tax_margin = ( @flight.taxes / @margin_multiplier ) - @flight.taxes
        @flight.calc( :daily, :local, :margin, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency @adult_percent_margin  + @adult_biz_supp_percent_margin  + tax_margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency @child_percent_margin  + @child_biz_supp_percent_margin  + tax_margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency @infant_percent_margin + @infant_biz_supp_percent_margin + tax_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency @single_percent_margin + @single_biz_supp_percent_margin + 0
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.margin_type = ''
        @flight.biz_supp_margin_type = ''
        @flight.calc( :daily, :local, :margin, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency @flight.margin + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency @flight.margin + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency @flight.margin + @flight.biz_supp_margin
        @flight.calc( :daily, :local, :margin, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency 0              + 0
        
      end
      
      
      it "should calculate daily local  GROSS  per adult/child/infant/single + BIZ SUPP + TAXES (percent & fixed margin)" do
        
        adult_gross_biz_supp  = @flight.biz_supp_per_adult  / @biz_supp_margin_multiplier
        child_gross_biz_supp  = @flight.biz_supp_per_child  / @biz_supp_margin_multiplier
        infant_gross_biz_supp = @flight.biz_supp_per_infant / @biz_supp_margin_multiplier
        single_gross_biz_supp = 0.0                                                          
        
        adult_gross_tax       = @flight.taxes / @margin_multiplier
        child_gross_tax       = @flight.taxes / @margin_multiplier
        infant_gross_tax      = @flight.taxes / @margin_multiplier
        single_gross_tax      = 0
        
        # With percent margin:
        @flight.calc( :daily, :local, :gross, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency @gross_per_adult  + adult_gross_biz_supp  + adult_gross_tax 
        @flight.calc( :daily, :local, :gross, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency @gross_per_child  + child_gross_biz_supp  + child_gross_tax 
        @flight.calc( :daily, :local, :gross, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency @gross_per_infant + infant_gross_biz_supp + infant_gross_tax
        @flight.calc( :daily, :local, :gross, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency @gross_per_single + single_gross_biz_supp + single_gross_tax     
        
        # With fixed margin: NO FIXED MARGIN SHOULD BE APPLIED ON TAXES:
        @flight.margin_type = ''
        @flight.biz_supp_margin_type = ''
        @flight.calc( :daily, :local, :gross, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_adult  + @flight.margin + @flight.biz_supp_per_adult  + @flight.biz_supp_margin + @flight.taxes 
        @flight.calc( :daily, :local, :gross, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_child  + @flight.margin + @flight.biz_supp_per_child  + @flight.biz_supp_margin + @flight.taxes 
        @flight.calc( :daily, :local, :gross, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_infant + @flight.margin + @flight.biz_supp_per_infant + @flight.biz_supp_margin + @flight.taxes
        @flight.calc( :daily, :local, :gross, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency @flight.cost_per_single + 0.0                                                     
        
      end
      
      
      it "should calculate daily ACTUAL net    per adult/child/infant/single + BIZ SUPP + TAXES" do
        
        adult_total     = @flight.cost_per_adult  / @flight.exchange_rate
        child_total     = @flight.cost_per_child  / @flight.exchange_rate
        infant_total    = @flight.cost_per_infant / @flight.exchange_rate
        single_total    = @flight.cost_per_single / @flight.exchange_rate
        
        adult_biz_supp  = ( @flight.biz_supp_per_adult  / @flight.exchange_rate )
        child_biz_supp  = ( @flight.biz_supp_per_child  / @flight.exchange_rate )
        infant_biz_supp = ( @flight.biz_supp_per_infant / @flight.exchange_rate )
        single_biz_supp = 0.0 
        
        adult_tax       = @flight.taxes / @flight.exchange_rate
        child_tax       = @flight.taxes / @flight.exchange_rate
        infant_tax      = @flight.taxes / @flight.exchange_rate
        single_tax      = 0.0
        
        @flight.calc( :daily, :actual, :net, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_total  + adult_biz_supp  + adult_tax 
        @flight.calc( :daily, :actual, :net, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_total  + child_biz_supp  + child_tax 
        @flight.calc( :daily, :actual, :net, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_total + infant_biz_supp + infant_tax
        @flight.calc( :daily, :actual, :net, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency single_total + single_biz_supp + single_tax
        
      end
      
      
      it "should calculate TOTAL actual net    per adult/child/infant/single + BIZ SUPP + TAXES" do
        
        # This is a trick question because the daily/total argument should not make any difference to biz supp:
        
        adult_total     = @flight.cost_per_adult  / @flight.exchange_rate * @flight.days
        child_total     = @flight.cost_per_child  / @flight.exchange_rate * @flight.days
        infant_total    = @flight.cost_per_infant / @flight.exchange_rate * @flight.days
        single_total    = @flight.cost_per_single / @flight.exchange_rate * @flight.days
        
        adult_biz_supp  = @flight.biz_supp_per_adult  / @flight.exchange_rate
        child_biz_supp  = @flight.biz_supp_per_child  / @flight.exchange_rate
        infant_biz_supp = @flight.biz_supp_per_infant / @flight.exchange_rate
        single_biz_supp = 0.0 
        
        adult_tax       = @flight.taxes / @flight.exchange_rate
        child_tax       = @flight.taxes / @flight.exchange_rate
        infant_tax      = @flight.taxes / @flight.exchange_rate
        single_tax      = 0.0
        
        @flight.calc( :total, :actual, :net, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_total  + adult_biz_supp  + adult_tax 
        @flight.calc( :total, :actual, :net, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_total  + child_biz_supp  + child_tax 
        @flight.calc( :total, :actual, :net, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_total + infant_biz_supp + infant_tax
        @flight.calc( :total, :actual, :net, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency single_total + single_biz_supp + single_tax
        
      end
      
      
      it "should calculate daily local  net    ALL adults/children/infants/singles + BIZ SUPP + TAXES" do
        
        adult_total     = @flight.cost_per_adult  * @flight.adults
        child_total     = @flight.cost_per_child  * @flight.children
        infant_total    = @flight.cost_per_infant * @flight.infants
        single_total    = @flight.cost_per_single * @flight.singles
        
        adult_biz_supp  = @flight.biz_supp_per_adult  * @flight.adults
        child_biz_supp  = @flight.biz_supp_per_child  * @flight.children
        infant_biz_supp = @flight.biz_supp_per_infant * @flight.infants
        single_biz_supp = 0.0                         
        
        adult_tax       = @flight.taxes * @flight.adults
        child_tax       = @flight.taxes * @flight.children
        infant_tax      = @flight.taxes * @flight.infants
        single_tax      = 0.0           
        
        @flight.calc( :daily, :local, :net, :all, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_total  + adult_biz_supp  + adult_tax 
        @flight.calc( :daily, :local, :net, :all, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_total  + child_biz_supp  + child_tax 
        @flight.calc( :daily, :local, :net, :all, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_total + infant_biz_supp + infant_tax
        @flight.calc( :daily, :local, :net, :all, :single, @with_biz_supp_and_taxes_options ).should match_currency single_total + single_biz_supp + single_tax
        
      end
      
      
      
      it "should calculate TOTAL actual net    ALL travellers WITH ALL EXTRAS" do
        
        # This is a trick question because the daily/total argument should not make any difference to biz supp:
        
        adult_total     = @flight.cost_per_adult  / @flight.exchange_rate * @flight.days
        child_total     = @flight.cost_per_child  / @flight.exchange_rate * @flight.days
        infant_total    = @flight.cost_per_infant / @flight.exchange_rate * @flight.days
        single_total    = @flight.cost_per_single / @flight.exchange_rate * @flight.days
        
        adult_biz_supp  = @flight.biz_supp_per_adult  / @flight.exchange_rate
        child_biz_supp  = @flight.biz_supp_per_child  / @flight.exchange_rate
        infant_biz_supp = @flight.biz_supp_per_infant / @flight.exchange_rate
        single_biz_supp = 0.0 
        
        adult_tax       = @flight.taxes / @flight.exchange_rate
        child_tax       = @flight.taxes / @flight.exchange_rate
        infant_tax      = @flight.taxes / @flight.exchange_rate
        single_tax      = 0.0
        
        adult_expected  = ( adult_total  + adult_biz_supp  + adult_tax  ) * @flight.adults
        child_expected  = ( child_total  + child_biz_supp  + child_tax  ) * @flight.children
        infant_expected = ( infant_total + infant_biz_supp + infant_tax ) * @flight.infants
        single_expected = ( single_total + single_biz_supp + single_tax ) * @flight.singles
        
        adult_test  = @flight.calc( :total, :actual, :net, :all, :adult,  @with_biz_supp_and_taxes_options )
        child_test  = @flight.calc( :total, :actual, :net, :all, :child,  @with_biz_supp_and_taxes_options )
        infant_test = @flight.calc( :total, :actual, :net, :all, :infant, @with_biz_supp_and_taxes_options )
        single_test = @flight.calc( :total, :actual, :net, :all, :single, @with_biz_supp_and_taxes_options )
        
        adult_test.should  match_currency adult_expected 
        child_test.should  match_currency child_expected 
        infant_test.should match_currency infant_expected
        single_test.should match_currency single_expected
        
        travellers_total = adult_test + child_test + infant_test + single_test
        
        @elem.calc_total_cost( :days => :total ).should match_currency travellers_total
        
      end
      
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL adults/children/infants/singles + BIZ SUPP + TAXES" do
        
        adult_total           = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total           = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total          = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total          = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = @flight.biz_supp_per_adult  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.adults  
        child_biz_supp_total  = @flight.biz_supp_per_child  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.children
        infant_biz_supp_total = @flight.biz_supp_per_infant / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.infants 
        single_biz_supp_total = 0
        
        adult_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.adults
        child_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.children
        infant_tax            = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.infants
        single_tax            = 0.0           
        
        # a fairly complex calc scenario:
        @flight.calc( :total, :actual, :gross, :all, :adults,   @with_biz_supp_and_taxes_options ).should match_currency adult_total  + adult_biz_supp_total  + adult_tax 
        @flight.calc( :total, :actual, :gross, :all, :children, @with_biz_supp_and_taxes_options ).should match_currency child_total  + child_biz_supp_total  + child_tax 
        @flight.calc( :total, :actual, :gross, :all, :infants,  @with_biz_supp_and_taxes_options ).should match_currency infant_total + infant_biz_supp_total + infant_tax
        @flight.calc( :total, :actual, :gross, :all, :singles,  @with_biz_supp_and_taxes_options ).should match_currency single_total + single_biz_supp_total + single_tax
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers + BIZ SUPP + TAXES" do
        
        adult_total           = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total           = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total          = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total          = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = @flight.biz_supp_per_adult  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.adults   
        child_biz_supp_total  = @flight.biz_supp_per_child  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.children 
        infant_biz_supp_total = @flight.biz_supp_per_infant / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.infants  
        single_biz_supp_total = 0
        
        adult_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.adults
        child_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.children
        infant_tax            = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.infants
        single_tax            = 0.0           
        
        travellers_total = ( adult_total  + adult_biz_supp_total  + adult_tax  ) +
        ( child_total  + child_biz_supp_total  + child_tax  ) +
        ( infant_total + infant_biz_supp_total + infant_tax ) +
        ( single_total + single_biz_supp_total + single_tax )
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @with_biz_supp_and_taxes_options ).should match_currency travellers_total
        @elem.calc( :total, :actual, :gross, :all, :travellers, @with_biz_supp_and_taxes_options.merge( :with_all_extras => true ) ).should match_currency travellers_total
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers WITH_ALL_EXTRAS" do
        
        # with_all_extras should be equivalent to PREVIOUS TEST!
        
        adult_total           = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total           = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total          = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total          = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = @flight.biz_supp_per_adult  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.adults   
        child_biz_supp_total  = @flight.biz_supp_per_child  / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.children 
        infant_biz_supp_total = @flight.biz_supp_per_infant / @flight.exchange_rate / @biz_supp_margin_multiplier * @flight.infants  
        single_biz_supp_total = 0
        
        adult_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.adults
        child_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.children
        infant_tax            = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.infants
        single_tax            = 0.0           
        
        travellers_total = \
        ( adult_total  + adult_biz_supp_total  + adult_tax  ) +
        ( child_total  + child_biz_supp_total  + child_tax  ) +
        ( infant_total + infant_biz_supp_total + infant_tax ) +
        ( single_total + single_biz_supp_total + single_tax )
        
        # a fairly complex calc scenario: (And the calc_total_price method should produce the same result too)
        @elem.calc( :total, :actual, :gross, :all, :travellers, @options.merge( :with_all_extras => true) ).should match_currency travellers_total
        @elem.calc_total_price( :days => :total ).should match_currency travellers_total
        
      end
      
      
      it "should calculate TOTAL ACTUAL GROSS  ALL travellers + BIZ SUPP + TAXES (but ignore biz_supp on non-flight elements))" do
        
        # Make test element a non-flight element:
        @elem.type_id = 4 # 4=Accommodation
        
        adult_total           = @gross_per_adult  / @flight.exchange_rate * @flight.adults   * @flight.days
        child_total           = @gross_per_child  / @flight.exchange_rate * @flight.children * @flight.days
        infant_total          = @gross_per_infant / @flight.exchange_rate * @flight.infants  * @flight.days
        single_total          = @gross_per_single / @flight.exchange_rate * @flight.singles  * @flight.days
        
        adult_biz_supp_total  = 0
        child_biz_supp_total  = 0
        infant_biz_supp_total = 0 
        single_biz_supp_total = 0
        
        adult_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.adults
        child_tax             = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.children
        infant_tax            = @flight.taxes / @flight.exchange_rate / @margin_multiplier * @flight.infants
        single_tax            = 0.0           
        
        travellers_total = ( adult_total  + adult_biz_supp_total  + adult_tax  ) +
        ( child_total  + child_biz_supp_total  + child_tax  ) +
        ( infant_total + infant_biz_supp_total + infant_tax ) +
        ( single_total + single_biz_supp_total + single_tax )
        
        # a fairly complex calc scenario:
        @elem.calc( :total, :actual, :gross, :all, :travellers, @with_biz_supp_and_taxes_options ).should match_currency travellers_total
        
      end
      
      
    end
    
    
    
  end
  
  
  
  
  describe ".total_cost" do    
    
    it "should be recalculated when element is saved" do
      
      orig_total_cost = @elem.total_cost
      
      @elem.cost_per_adult = 10000
      @elem.save
      @elem.reload
      
      @elem.total_cost.should_not == orig_total_cost
      @elem.total_cost.should     == @elem.calc_total_cost
      
    end
    
  end
  
  


  describe ".total_price" do    
    
    it "should be recalculated when element is saved" do
      
      orig_total_price = @elem.total_price
      
      @elem.cost_per_adult = 10000
      @elem.save
      @elem.reload
      
      @elem.total_price.should_not == orig_total_price
      @elem.total_price.should     match_currency @elem.calc_total_price
      
    end
    
    
    it "should NOT recalculate trip.total_price when element is updated" do
      
      options = { :with_all_extras => true, :as_decimal => true }
      elem_orig_total_price = @elem.total_price
      trip_orig_total_price = @trip.total_price
      trip_orig_total_net   = @trip.calc( :daily, :actual, :net, :for_all, :travellers, options )
      
      @elem.cost_per_adult  = 10000
      @elem.save.should be_true
      
      @elem.total_price.should_not  match_currency elem_orig_total_price
      @elem.total_price.should      match_currency @elem.calc_total_price
      @trip.total_price.should      match_currency trip_orig_total_price
      @trip.total_price.should      match_currency @trip.calc_total_price
      
      trip_total_cost = @trip.calc( :daily, :actual, :net, :for_all, :travellers, options )
      trip_total_cost.should_not    == trip_orig_total_net
      
    end
    
    
    it "should NOT recalculate trip.total_price when element is deleted" do
      
      options = { :with_all_extras => true, :as_decimal => true }
      elem_orig_total_price = @elem.total_price
      trip_orig_total_price = @trip.total_price
      trip_orig_total_net   = @trip.calc( :daily, :actual, :net, :for_all, :travellers, options )
      
      @elem.destroy.should be_true
      
      @elem.total_price.should      == 0
      @elem.total_price.should_not  == elem_orig_total_price
      @trip.total_price.should      == trip_orig_total_price
      @trip.total_price.should      == @trip.calc_total_price
      
      trip_total_cost = @trip.calc( :daily, :actual, :net, :for_all, :travellers, options )
      trip_total_cost.should_not    == trip_orig_total_net
      
    end
    
  end

end