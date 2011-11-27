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


  # Helper to ensure flight has overnight dates and times: (Starting on Day 2 of the Trip)
  def make_it_an_overnight(flight)

    flight.start_date = flight.trip.start_date + 1  # Start on day 2
    flight.end_date   = flight.trip.start_date + 2  # End on day 3
    flight.set_time :start_date, '10:15'
    flight.set_time :end_date,   '09:15'
    
  end





  it "should be valid" do

	  @elem.should be_valid

  end
  
  it "should be an overnight (2-day) flight when end_date is next day" do

    make_it_an_overnight @flight

    @flight.save.should be_true
    @flight.day.should  == 2  # Start on day 2
    @flight.days.should == 2  # Span 2 days (arrive_next_day)
    @flight.arrive_next_day.should be_true

  end

  it "should auto_update_elements_dates when trip dates change" do

    make_it_an_overnight @flight
    @flight.save.should be_true

    orig_day        = @flight.day
    orig_days       = @flight.days
    orig_start_date = @flight.start_date
    
    # Move trip forward 10 days:
    @flight.trip.auto_update_elements_dates = true
    @flight.trip.start_date += 10
    @flight.trip.save.should be_true
    @flight.reload

    @flight.day.should == orig_day
    @flight.start_date.to_date.to_s.should == ( orig_start_date.to_date + 10 ).to_s
    @flight.start_date.to_date.to_s.should == ( @flight.trip.start_date + (orig_day-1) ).to_s # We minus 1 because day is 1-based and the calculation is zero-based
    
  end
  
  it "should remain an overnight flight when trip dates change" do
    
    make_it_an_overnight @flight
    @flight.save.should be_true
    
    orig_day        = @flight.day
    orig_days       = @flight.days
    orig_start_date = @flight.start_date
    orig_end_date   = @flight.end_date
    orig_start_time = @flight.start_time
    orig_end_time   = @flight.end_time
    
    # Move trip forward 10 days:
    @flight.trip.auto_update_elements_dates = true
    @flight.trip.start_date += 10
    @flight.trip.save.should be_true
    @flight.reload
    
    # start_date should have changed relative to trip start_date:
    @flight.days.should == orig_days
    @flight.end_date.to_date.to_s.should == ( orig_end_date.to_date + 10 ).to_s

    # Depart/Arrival times should be unchanged:
    @flight.start_time.should == orig_start_time
    @flight.end_time.should   == orig_end_time
    

  end
  
end