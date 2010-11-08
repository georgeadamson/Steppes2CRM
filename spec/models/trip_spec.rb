require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/trip_spec.rb

# Note: If the trip_element_spec does not succeed then this one does not have a chance!

describe Trip do

  before :all do

    @company      = Company.first_or_create()
    @world_region = WorldRegion.first_or_create( { :name => 'Dummy Region' }, { :name => 'Dummy Region' } )
    @mailing_zone = MailingZone.first_or_create( { :name => 'Dummy Zone'   }, { :name => 'Dummy Zone'   } )
    @country1     = Country.first_or_create( { :name => 'Country 1' }, { :code => 'C1', :name => 'Country 1', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @country2     = Country.first_or_create( { :name => 'Country 2' }, { :code => 'C2', :name => 'Country 2', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @country3     = Country.first_or_create( { :name => 'Country 3' }, { :code => 'C3', :name => 'Country 3', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @title        = Title.create( :name => 'Mr' )
    @client1      = Client.first_or_create(  { :name => 'Client 1'  }, { :title => @title, :name => 'Client 1', :forename => 'Test', :marketing_id => 1, :kind_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @client2      = Client.first_or_create(  { :name => 'Client 2'  }, { :title => @title, :name => 'Client 2', :forename => 'Test', :marketing_id => 1, :kind_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @client3      = Client.first_or_create(  { :name => 'Client 3'  }, { :title => @title, :name => 'Client 3', :forename => 'Test', :marketing_id => 1, :kind_id => 1, :original_source_id => 1, :address_client_id => 1 } )

    # Ensure user has a "most_recent_client" (Helps when confirmed trip tries to create_task (flight followups) automatically)
    user = User.first_or_create( { :id => valid_trip_attributes[:user_id] }, valid_user_attributes )
    if user.clients.empty?
      user.clients << @client1
      user.save
    end

    seed_lookup_tables()

  end


  before :each do

    number_of_travellers = {
      :adults    => valid_flight_attributes[:adults],    
      :children  => valid_flight_attributes[:children],    
      :infants   => valid_flight_attributes[:infants],
      :singles   => valid_flight_attributes[:singles]    
    }
    
    # Prepare trip and flight with same numbers of travellers:
    @trip     = Trip.create( valid_trip_attributes.merge(number_of_travellers) )
    @flight   = @trip.trip_elements.create(valid_flight_attributes)
    @flight2  = @trip.trip_elements.create(valid_flight_attributes)
    @elem     = @flight
    @elem2    = @flight2

    # Prepare options for use when calling the .calc method:
    @options                          = { :string_format => false }
    @taxes_options                    = @options.merge( :taxes            => true )
    @with_taxes_options               = @options.merge( :with_taxes       => true )
    @biz_supp_options                 = @options.merge( :biz_supp         => true )
    @with_biz_supp_options            = @options.merge( :with_biz_supp    => true )
    @with_biz_supp_and_taxes_options  = @options.merge( :with_biz_supp    => true, :with_taxes => true )
    @with_booking_fee_options         = @options.merge( :with_booking_fee => true )
    @with_all_extras_options          = @options.merge( :with_all_extras  => true )  # Equivalent to: { :with_biz_supp => true, :with_taxes => true, :with_booking_fee => true }
        
    @main_invoice = MoneyIn.new( :skip_doc_generation => true, :client => @client1, :deposit => 100, :amount => 0, :user_id => 1  )

    @booking_fee  = 1.0 * @trip.calc( :total, :actual, :gross, :per, :person, :booking_fee => true, :string_format => false )
    
  end
  

  after :each do
    TripClient.all.destroy
    TripCountry.all.destroy
    Trip.all.destroy
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
  

  # Helper to simplify the adding up of the same property from each element:
  def sum_of( attr, collection = :trip_elements )

    result = 0.0

    @trip.method(collection).call.each{ |elem| result += elem.method(attr).call }

    return result

  end






  describe ' validations' do

    it 'should be valid' do
      @trip.should be_valid
    end
  	  
    it "should confirm our test data is valid before start" do
		  @company.should be_valid
		  @world_region.should be_valid
		  @mailing_zone.should be_valid
		  @country1.should be_valid
		  @country2.should be_valid
		  @country3.should be_valid
		  @client1.should be_valid
		  @client2.should be_valid
		  @client3.should be_valid
    end

    it 'should have a default status of Unconfirmed' do
      @trip.status_id.should == Trip::UNCONFIRMED
    end

    it 'should have default version_of_trip equal to self' do
      @trip = Trip.new( valid_trip_attributes )
      @trip.version_of_trip_id = nil
      @trip.save.should be_true
      @trip.id.should be > 0
      @trip.version_of_trip_id.should == @trip.id
      @trip.reload
      @trip.version_of_trip_id.should == @trip.id
    end

    it 'should use booking fee of trip.company' do

      # booking_fee:
      @trip.booking_fee.should be > 0
      @trip.booking_fee.should == @booking_fee
      @trip.booking_fee.should == @trip.company.booking_fee

      # booking_fees:
      @trip.booking_fees.             should == @trip.company.booking_fee * @trip.travellers
      @trip.booking_fees(:all       ).should == @trip.company.booking_fee * @trip.travellers
      @trip.booking_fees(:people    ).should == @trip.company.booking_fee * @trip.travellers
      @trip.booking_fees(:persons   ).should == @trip.company.booking_fee * @trip.travellers
      @trip.booking_fees(:travellers).should == @trip.company.booking_fee * @trip.travellers
      @trip.booking_fees(:adult     ).should == @trip.company.booking_fee * @trip.adults
      @trip.booking_fees(:adults    ).should == @trip.company.booking_fee * @trip.adults
      @trip.booking_fees(:child     ).should == @trip.company.booking_fee * @trip.children
      @trip.booking_fees(:children  ).should == @trip.company.booking_fee * @trip.children
      @trip.booking_fees(:infant    ).should == @trip.company.booking_fee * @trip.infants
      @trip.booking_fees(:infants   ).should == @trip.company.booking_fee * @trip.infants
      @trip.booking_fees(:single    ).should == 0
      @trip.booking_fees(:singles   ).should == 0

    end

    it 'should recalculate total_price as zero when no travellers' do
      
      @trip.adults    = 0
      @trip.children  = 0
      @trip.infants   = 0
      @trip.save.should be_true
      @trip.total_price.should == 0
      
    end

    it 'should update total_price of trip when saving' do
      
      orig_price = @trip.total_price
      orig_price.should == @trip.calc_total_price

      @trip.adults += 1
      @trip.save.should be_true

      # Expect price increase for the extra adult:
      @trip.total_price.should be > orig_price
      @trip.total_price.should == @trip.calc_total_price
      
    end
    
    it 'should save price_per_person' do

      @trip.price_per_adult  = 111
      @trip.price_per_child  = 222
      @trip.price_per_infant = 333
      @trip.price_per_single = 444

      @trip.save.should be_true
      @trip.reload

      @trip.price_per_adult.should  == 111
      @trip.price_per_child.should  == 222
      @trip.price_per_infant.should == 333
      @trip.price_per_single.should == 444
      
    end
    
    it 'should save price_per_person_biz_supp' do

      @trip.price_per_adult_biz_supp  = 111
      @trip.price_per_child_biz_supp  = 222
      @trip.price_per_infant_biz_supp = 333
      @trip.price_per_single_biz_supp = 444

      @trip.save.should be_true
      @trip.reload

      @trip.price_per_adult_biz_supp.should  == 111
      @trip.price_per_child_biz_supp.should  == 222
      @trip.price_per_infant_biz_supp.should == 333
      @trip.price_per_single_biz_supp.should == 0   # Expect zero because biz supp does not apply to single!
      
    end


    it 'should update total_price using price_per_adult set by user' do
      
      @trip.total_price.should == @trip.calc_total_price
      @trip.adults    = 1
      @trip.children  = 0
      @trip.infants   = 0
      @trip.singles   = 0
      @trip.price_per_adult = 1000
      @trip.price_per_adult_biz_supp  = 100
      @trip.price_per_child_biz_supp  = 100 # This should not affect total_price because @trip.children  = 0
      @trip.price_per_infant_biz_supp = 100 # This should not affect total_price because @trip.infants  = 0

      @trip.save.should be_true
      @trip.total_price.should == @trip.price_per_adult + @trip.price_per_adult_biz_supp
      
    end
    
    
    it 'should update elements with number of adults/children/infants when saving' do

      elem = @trip.trip_elements.first
      
      # Attempt to save out-of-range traveller numbers on an element:
      elem.update( :adults => @trip.adults+1, :children => @trip.children+1, :infants => @trip.infants+1 )
      elem.adults.should   == @trip.adults
      elem.children.should == @trip.children
      elem.infants.should  == @trip.infants

      # Artificially rig the number of travellers on a trip element:
      # TODO: Can we prevent this type of naughtiness too?!
      elem.update!( :adults => 10, :children => 20, :infants => 30 )
      elem.adults.should   == 10
      elem.children.should == 20
      elem.infants.should  == 30

      # Now save the trip with new traveller numbers:
      @trip.update( :adults => 1, :children => 2, :infants => 3 )
      @trip.reload
      elem.reload
      elem.adults.should   == 1
      elem.children.should == 2
      elem.infants.should  == 3

    end


    it 'should increase total_price by price_per_adult when one adult added' do
      
      @trip.adults    = 1
      @trip.children  = 1
      @trip.infants   = 1
      @trip.singles   = 1

      @trip.trip_elements.should have(2).trip_elements
      @trip.trip_elements.first.cost_per_adult = 0
      @trip.trip_elements.last.cost_per_adult  = 0

      @trip.save.should be_true      
      orig_price = @trip.total_price
      
      @trip.adults += 1
      @trip.save.should be_true
      @trip.total_price.should == orig_price + @trip.price_per_adult + @trip.price_per_adult_biz_supp
      
    end


    it "should save and reload start/end_date properties without messing up timezones" do

      # This test is redundant because start/end_date are Date properties not DateTime.
      # This may only be a problem during BST!
      @trip.start_date = Date::civil( 2010, 5, 1 )
      @trip.start_date.to_s.should     == "2010-05-01" # No +01:00 timezone offset.
	    @trip.save.should be_true
      @trip.reload
      @trip.start_date.to_s.should     == "2010-05-01" # No +01:00 timezone offset.

    end


    it "should not cause element cost to change for no apparent reason" do

      # Test created from live data that was triggering a bug:
      trip = Trip.new(
        :name=>"test", 
        :version=>1, 
        :version_of_trip_id=>0, 
        :is_active_version=>true, 
        :is_version_snapshot=>false, 
        :start_date=>Date.today, 
        :end_date=>(Date.today.to_time + 10.days).to_date, 
        :adults=>2, 
        :children=>0, 
        :infants=>0, 
        :singles=>0, 
        :price_per_adult=>100, 
        :price_per_child=>0,
        :price_per_infant=>0,
        :price_per_adult_biz_supp=>0,
        :price_per_child_biz_supp=>0,
        :price_per_infant_biz_supp=>0,
        :price_per_single_supp=>0,
        :kind_id=>1, 
        :status_id=>1, 
        :deleted=>false, 
        :tour_id=>nil, 
        :total_price=>1000, 
        :created_at=>Time.now, 
        :created_by=>"", 
        :updated_at=>Time.now, 
        :updated_by=>"", 
        :company_id=>1, 
        :user_id=>1
      )

      elem = TripElement.new(
        :kind_id=>1, 
        :misc_type_id=>1, 
        :supplier_id=>1, 
        :handler_id=>1, 
        :name=>"flight", 
        :description=>"description", 
        :notes=>"notes", 
        :start_date=>trip.start_date, 
        :end_date=>(trip.start_date.to_time + 1.days).to_date, 
        :adults=>2, 
        :children=>0, 
        :infants=>0, 
        :singles=>0, 
        :margin_type=>"%", 
        :margin=>10, 
        :exchange_rate=>1, 
        :cost_per_adult=>100, 
        :cost_per_child=>0, 
        :cost_per_infant=>0,
        :cost_per_triple=>0,
        :cost_by_room=>0,
        :single_supp=>0,
        :total_cost=>0,
        :total_price=>0, 
        :meal_plan=>nil, 
        :room_type=>nil, 
        :single_rooms=>0, 
        :twin_rooms=>0, 
        :triple_rooms=>0, 
        :flight_code=>"BA123", 
        :flight_leg=>false, 
        :arrive_next_day=>true, 
        :touchdownDescription=>"", 
        :taxes=>0, 
        :biz_supp_per_adult=>0, 
        :biz_supp_per_child=>0,
        :biz_supp_per_infant=>0, 
        :biz_supp_margin=>10, 
        :biz_supp_margin_type=>"%", 
        :is_subgroup=>false, 
        :is_active=>true, 
        :booking_code=>"ABCD", 
        :booking_reminder=>nil, 
        :booking_expiry=>nil, 
        :booking_line_number=>nil, 
        :booking_line_revision=>nil, 
        :depart_airport_id=>1, 
        :arrive_airport_id=>1, 
        :depart_terminal=>nil, 
        :arrive_terminal=>nil, 
        :created_at=>Time.now, 
        :updated_at=>Time.now, 
        :created_by=>nil, 
        :updated_by=>"george"
      )

      elem.update_prices()
      
      orig_cost  = elem.total_cost
      orig_price = elem.total_price
      
      trip.save.should be_true
      trip.elements << elem
      trip.save.should be_true
      trip.should have(1).trip_elements

      @trip.update(:name => 'New name')
      elem = trip.trip_elements.first

      elem.total_cost.should  match_currency orig_cost 
      elem.total_price.should match_currency orig_price

    end



  end




  describe " standard attributes" do  	

    it "should save and retrieve valid trip with countries" do
		  @trip.countries_ids = [ @country1.id , @country2.id, @country3.id ]
      @trip.save.should be_true
      @trip.reload
      @trip.countries.should have(3).countries
      @trip.countries_ids.should have(3).items
    end

    it "should not forget countries when costs are being updated" do

		  @trip.countries_ids = [ @country1.id , @country2.id, @country3.id ]
      @trip.save.should be_true
      @trip.countries.should have(3).countries

      @trip.reload
      @trip.attributes = { :price_per_adult => 10000 }
      @trip.save.should be_true
      @trip.countries.should have(3).countries

    end
  	
    
    it "should save and retrieve valid trip with clients" do
		  @trip.clients << @client1 << @client2 << @client3
      @trip.save.should be_true
      @trip.reload
      @trip.clients.should have(3).clients
      @trip.clients_names.should have(3).items
    end
  	
    
    it "should add clients via nested-attributes" do

      @trip.save
      @trip.clients.should have(0).clients
      
		  @trip.attributes = {
        :trip_clients_attributes => {
          :"0" => {:client_id => @client1.id, :is_single => "0", :is_primary => "1", :is_invoicable => "1"},
          :"1" => {:client_id => @client2.id, :is_single => "0", :is_primary => "0", :is_invoicable => "0"}
        }
      }
      @trip.trip_clients.should have(2).trip_clients
      @trip.save.should be_true
      @trip.reload
      @trip.clients.should have(2).clients
      @trip.clients_names.should have(2).items

    end
  	
    
    it "should update clients via nested-attributes" do

      # First set up 2 clients, same as the previous test:
		  @trip.attributes = {
        :trip_clients_attributes => {
          :"0" => {:client_id => @client1.id, :is_single => "0", :is_primary => "1", :is_invoicable => "1"},
          :"1" => {:client_id => @client2.id, :is_single => "0", :is_primary => "0", :is_invoicable => "0"}
        }
      }
      @trip.trip_clients.should have(2).trip_clients
      @trip.save.should be_true
      @trip.reload

      id1 = @trip.trip_clients[0].id
      id2 = @trip.trip_clients[1].id

      # Now apply more nested attributes to delete one client and add another:
		  @trip.attributes = {
        :trip_clients_attributes => {
          :"0" => { :id => id1, :client_id => @client1.id, :_delete => true },
          :"1" => { :id => id2, :client_id => @client2.id, :is_single => "0", :is_primary => "0", :is_invoicable => "0"},
          :"2" => {             :client_id => @client3.id, :is_single => "0", :is_primary => "0", :is_invoicable => "0"}
        }
      }

      # One item should be removed and one added:
      @trip.trip_clients.should have(3).trip_clients  # Before save, one item will be flagged 'destroy'
      @trip.save.should be_true
      @trip.reload
      @trip.clients.should have(2).clients
      @trip.clients_names.should have(2).items
      @trip.clients[0].id.should == @client2.id
      @trip.clients[1].id.should == @client3.id

      # Bonus test: After removing the primary client, another should become primary:
      # @trip.trip_clients.all( :is_primary => true ).should have(1).item

    end
    	
      
    it "should save and retrieve valid trip with PNRs" do
      
      @pnr1 = Pnr.new(valid_pnr_attributes)

      @trip.pnrs << @pnr1
      @trip.save.should be_true
      @trip.reload
      @trip.pnrs.should have(1).pnrs
      @trip.pnr_numbers.should have(1).items

    end
      

    it "should save trip with more complex data" do
      
      @trip.attributes = {
        "version_of_trip_id"=>"84735",
        "name"=>"test trip 2", 
        "start_date"=>'2008-04-28', 
        "user_id"=>"53",
        "adults"=>"1", 
        "end_date"=>'2008-04-30', 
        "company_id"=>"1", 
        "children"=>"0", 
        "pnr_numbers"=>"5ICOAT, 5ISDWP", 
        "type_id"=>"1", 
        "infants"=>"0", 
        "countries_ids"=> ["563", "49", "555"]
      }

      @trip.save.should be_true

    end
    
  end



#=begin

  describe ' invoicing' do    
    
    it 'should remain unconfirmed when a deposit is created' do
      
      @main_invoice.is_deposit  = true
      @main_invoice.amount      = 100
      @main_invoice.trip        = @trip
      @main_invoice.skip_doc_generation = true
      
      # Before save:
      @main_invoice.trip.status_id.should == Trip::UNCONFIRMED
      
      # After save:
      @main_invoice.save.should be_true
      @main_invoice.trip.status_id.should == Trip::UNCONFIRMED
      
    end
    

    it 'should become confirmed when a main invoice is created' do
      
      # Create a company that probably has a document template ready for use, so invoice.document passes dummy-run validation:
      @trip.company = Company.first_or_create( { :initials => 'SE' }, { :initials => 'SE', :invoice_prefix => 'SE', :name => 'Just for testing', :short_name => 'Testing' } )
      @trip.save.should be_true

      @main_invoice.deposit = 100
      @main_invoice.amount  = 1000
      @main_invoice.trip    = @trip
      @main_invoice.skip_doc_generation = true
      
      # Before save:
      @main_invoice.trip.status_id.should == Trip::UNCONFIRMED
      
      # After save:
      @main_invoice.valid?
      @main_invoice.save.should be_true
      @main_invoice.trip.status_id.should == Trip::CONFIRMED
      
    end
    
    
  end






  describe '.calc' do    
    
    
    it "should calculate total TAXES per/for_all persons" do
      #puts @trip.adults
      #puts @trip.elements.all( :taxes.gt => 0 ).length
      #puts @trip.elements.all( :taxes.gt => 0 ).sum(:taxes)
      #puts sum_of( :taxes )

      # Per person:
      adult_total  = sum_of( :taxes )
      child_total  = sum_of( :taxes )
      infant_total = sum_of( :taxes )
      single_total = 0
      
      @trip.calc( :daily, :local, :cost, :per, :adult,  @taxes_options ).should match_currency adult_total 
      @trip.calc( :daily, :local, :cost, :per, :child,  @taxes_options ).should match_currency child_total 
      @trip.calc( :daily, :local, :cost, :per, :infant, @taxes_options ).should match_currency infant_total
      @trip.calc( :daily, :local, :cost, :per, :single, @taxes_options ).should match_currency single_total
      @trip.calc( :daily, :local, :cost, :per, :people, @taxes_options ).should match_currency adult_total + child_total + infant_total + single_total

      # All persons:
      adult_total  = sum_of( :taxes ) * @trip.adults
      child_total  = sum_of( :taxes ) * @trip.children
      infant_total = sum_of( :taxes ) * @trip.infants
      single_total = 0
      
      @trip.calc( :daily, :local, :cost, :all, :adult,  @taxes_options ).should match_currency adult_total 
      @trip.calc( :daily, :local, :cost, :all, :child,  @taxes_options ).should match_currency child_total 
      @trip.calc( :daily, :local, :cost, :all, :infant, @taxes_options ).should match_currency infant_total
      @trip.calc( :daily, :local, :cost, :all, :single, @taxes_options ).should match_currency single_total
      @trip.calc( :daily, :local, :cost, :all, :people, @taxes_options ).should match_currency adult_total + child_total + infant_total + single_total
      
    end
    

    it "should calculate daily local  cost per adult/child/infant/single for all_elements" do
      
      @trip.calc( :daily, :local, :cost, :per, :adult,  @options ).should match_currency sum_of( :cost_per_adult  )
      @trip.calc( :daily, :local, :cost, :per, :child,  @options ).should match_currency sum_of( :cost_per_child  )
      @trip.calc( :daily, :local, :cost, :per, :infant, @options ).should match_currency sum_of( :cost_per_infant )
      @trip.calc( :daily, :local, :cost, :per, :single, @options ).should match_currency sum_of( :cost_per_single )
      
    end
    

    it "should calculate daily local  cost for_all adults/children/infants/singles for all_elements" do
      
      # WARNING: This test is over-simplified! It only passes when all elements have the same numbers of travellers:
      @trip.calc( :daily, :local, :cost, :for_all, :adult,  @options ).should match_currency sum_of( :cost_per_adult  ) * @elem.adults
      @trip.calc( :daily, :local, :cost, :for_all, :child,  @options ).should match_currency sum_of( :cost_per_child  ) * @elem.children
      @trip.calc( :daily, :local, :cost, :for_all, :infant, @options ).should match_currency sum_of( :cost_per_infant ) * @elem.infants
      @trip.calc( :daily, :local, :cost, :for_all, :single, @options ).should match_currency sum_of( :cost_per_single ) * @elem.singles
      
    end
    
    it "should calculate daily local  cost per adult/child/infant/single for all_elements" do
      
      # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
      exchange_rate = @elem.exchange_rate
      @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }

      # WARNING: This test is over-simplified! It only passes when all elements have the same exchange rate:
      @trip.calc( :daily, :actual, :cost, :per, :adult,  @options ).should match_currency sum_of( :cost_per_adult  ) / exchange_rate
      @trip.calc( :daily, :actual, :cost, :per, :child,  @options ).should match_currency sum_of( :cost_per_child  ) / exchange_rate
      @trip.calc( :daily, :actual, :cost, :per, :infant, @options ).should match_currency sum_of( :cost_per_infant ) / exchange_rate
      @trip.calc( :daily, :actual, :cost, :per, :single, @options ).should match_currency sum_of( :cost_per_single ) / exchange_rate
      
    end
    
    
    it "should calculate daily local  cost per adult/child/infant/single for all_elements BIZ_SUPP ZERO" do
      
      # Zero the biz_supp on all elements before testing calculation:
      @trip.trip_elements.each do |elem|
        elem.biz_supp_per_adult  = 0
        elem.biz_supp_per_child  = 0
        elem.biz_supp_per_infant = 0
      end

      @trip.calc( :daily, :local, :cost, :per, :adult,  @biz_supp_options ).should match_currency 0
      @trip.calc( :daily, :local, :cost, :per, :child,  @biz_supp_options ).should match_currency 0
      @trip.calc( :daily, :local, :cost, :per, :infant, @biz_supp_options ).should match_currency 0
      @trip.calc( :daily, :local, :cost, :per, :single, @biz_supp_options ).should match_currency 0
      
    end
    
    
    it "should calculate daily local  cost per adult/child/infant/single for all_elements + BIZ SUPP" do
      
      adult_total  = sum_of( :cost_per_adult  ) + sum_of( :biz_supp_per_adult  )
      child_total  = sum_of( :cost_per_child  ) + sum_of( :biz_supp_per_child  )
      infant_total = sum_of( :cost_per_infant ) + sum_of( :biz_supp_per_infant )
      single_total = sum_of( :cost_per_single ) + 0                             

      @trip.calc( :daily, :local, :cost, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total 
      @trip.calc( :daily, :local, :cost, :per, :child,  @with_biz_supp_options ).should match_currency child_total 
      @trip.calc( :daily, :local, :cost, :per, :infant, @with_biz_supp_options ).should match_currency infant_total
      @trip.calc( :daily, :local, :cost, :per, :single, @with_biz_supp_options ).should match_currency single_total
      
    end
    
    
    it "should calculate daily local  cost per adult/child/infant/single for all_elements + BIZ SUPP ZERO" do
      
      # Zero the biz_supp on all elements before testing calculation:
      @trip.trip_elements.each do |elem|
        elem.biz_supp_per_adult  = 0
        elem.biz_supp_per_child  = 0
        elem.biz_supp_per_infant = 0
      end

      adult_total  = sum_of( :cost_per_adult  ) + 0
      child_total  = sum_of( :cost_per_child  ) + 0
      infant_total = sum_of( :cost_per_infant ) + 0
      single_total = sum_of( :cost_per_single ) + 0                             

      @trip.calc( :daily, :local, :cost, :per, :adult,  @with_biz_supp_options ).should match_currency adult_total 
      @trip.calc( :daily, :local, :cost, :per, :child,  @with_biz_supp_options ).should match_currency child_total 
      @trip.calc( :daily, :local, :cost, :per, :infant, @with_biz_supp_options ).should match_currency infant_total
      @trip.calc( :daily, :local, :cost, :per, :single, @with_biz_supp_options ).should match_currency single_total
      
    end
    
    
    it "should calculate daily local  cost per adult/child/infant/single for all_elements + TAXES" do

      adult_total  = sum_of( :cost_per_adult  ) + sum_of( :taxes )
      child_total  = sum_of( :cost_per_child  ) + sum_of( :taxes )
      infant_total = sum_of( :cost_per_infant ) + sum_of( :taxes )
      single_total = sum_of( :cost_per_single ) + 0

      @trip.calc( :daily, :local, :cost, :per, :adult,  @with_taxes_options ).should match_currency adult_total 
      @trip.calc( :daily, :local, :cost, :per, :child,  @with_taxes_options ).should match_currency child_total 
      @trip.calc( :daily, :local, :cost, :per, :infant, @with_taxes_options ).should match_currency infant_total
      @trip.calc( :daily, :local, :cost, :per, :single, @with_taxes_options ).should match_currency single_total
      
    end
    
    
    it "should calculate daily local  cost per adult/child/infant/single for all_elements + BIZ SUPP + TAXES" do
      
      adult_total  = sum_of( :cost_per_adult  ) + sum_of( :biz_supp_per_adult  ) + sum_of( :taxes )
      child_total  = sum_of( :cost_per_child  ) + sum_of( :biz_supp_per_child  ) + sum_of( :taxes )
      infant_total = sum_of( :cost_per_infant ) + sum_of( :biz_supp_per_infant ) + sum_of( :taxes )
      single_total = sum_of( :cost_per_single ) + 0                              + 0

      @trip.calc( :daily, :local, :cost, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_total 
      @trip.calc( :daily, :local, :cost, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_total 
      @trip.calc( :daily, :local, :cost, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_total
      @trip.calc( :daily, :local, :cost, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency single_total
      
    end

   
  end






  describe ".calc derive final prices" do    

    before :each do
      # Augment the original options to use trip.final_prices in calculations:
      @options.merge!( :final_prices => true )
      @taxes_options                    = @options.merge( :taxes         => true )
      @biz_supp_options                 = @options.merge( :biz_supp      => true )
      @with_taxes_options               = @options.merge( :with_taxes    => true )
      @with_biz_supp_options            = @options.merge( :with_biz_supp => true )
      @with_biz_supp_and_taxes_options  = @options.merge( :with_biz_supp => true, :with_taxes => true )
    end


    it "should not be affected by with_biz_supp & with_taxes options (trip.price_per_xxx)" do
      
      options                         = @options.merge( :final_prices => true )
      with_taxes_options              = @with_taxes_options.merge( :final_prices => true )
      with_biz_supp_options           = @with_biz_supp_options.merge( :final_prices => true )
      with_biz_supp_and_taxes_options = @with_biz_supp_and_taxes_options.merge( :final_prices => true )
      
      @trip.calc( :daily, :actual, :gross, :per, :adult,  options ).should match_currency @trip.price_per_adult  
      @trip.calc( :daily, :actual, :gross, :per, :child,  options ).should match_currency @trip.price_per_child  
      @trip.calc( :daily, :actual, :gross, :per, :infant, options ).should match_currency @trip.price_per_infant 
      @trip.calc( :daily, :actual, :gross, :per, :single, options ).should match_currency @trip.price_per_single 
      
      @trip.calc( :daily, :actual, :gross, :per, :adult,  with_taxes_options ).should match_currency @trip.price_per_adult  
      @trip.calc( :daily, :actual, :gross, :per, :child,  with_taxes_options ).should match_currency @trip.price_per_child  
      @trip.calc( :daily, :actual, :gross, :per, :infant, with_taxes_options ).should match_currency @trip.price_per_infant 
      @trip.calc( :daily, :actual, :gross, :per, :single, with_taxes_options ).should match_currency @trip.price_per_single 
      
      @trip.calc( :daily, :actual, :gross, :per, :adult,  with_biz_supp_options ).should match_currency @trip.price_per_adult  + @trip.price_per_adult_biz_supp
      @trip.calc( :daily, :actual, :gross, :per, :child,  with_biz_supp_options ).should match_currency @trip.price_per_child  + @trip.price_per_child_biz_supp 
      @trip.calc( :daily, :actual, :gross, :per, :infant, with_biz_supp_options ).should match_currency @trip.price_per_infant + @trip.price_per_infant_biz_supp
      @trip.calc( :daily, :actual, :gross, :per, :single, with_biz_supp_options ).should match_currency @trip.price_per_single + @trip.price_per_single_biz_supp

      @trip.calc( :daily, :actual, :gross, :per, :adult,  with_biz_supp_and_taxes_options ).should match_currency @trip.price_per_adult  + @trip.price_per_adult_biz_supp
      @trip.calc( :daily, :actual, :gross, :per, :child,  with_biz_supp_and_taxes_options ).should match_currency @trip.price_per_child  + @trip.price_per_child_biz_supp 
      @trip.calc( :daily, :actual, :gross, :per, :infant, with_biz_supp_and_taxes_options ).should match_currency @trip.price_per_infant + @trip.price_per_infant_biz_supp
      @trip.calc( :daily, :actual, :gross, :per, :single, with_biz_supp_and_taxes_options ).should match_currency @trip.price_per_single + @trip.price_per_single_biz_supp
      
    end




    it "should calculate daily LOCAL  cost  per adult/child/infant/single for all_elements" do
      
      adult_expected  = sum_of( :cost_per_adult  ) 
      child_expected  = sum_of( :cost_per_child  ) 
      infant_expected = sum_of( :cost_per_infant ) 
      single_expected = sum_of( :cost_per_single ) 
      
      @trip.calc( :daily, :local, :cost, :per, :adult,  @options ).should match_currency adult_expected 
      @trip.calc( :daily, :local, :cost, :per, :child,  @options ).should match_currency child_expected 
      @trip.calc( :daily, :local, :cost, :per, :infant, @options ).should match_currency infant_expected
      @trip.calc( :daily, :local, :cost, :per, :single, @options ).should match_currency single_expected
 
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :local, :cost, :per, :adult,  @options ) }
      child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :local, :cost, :per, :child,  @options ) }
      infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :local, :cost, :per, :infant, @options ) }
      single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :local, :cost, :per, :single, @options ) }

      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected

    end
    
    
    it "should calculate daily ACTUAL cost  per adult/child/infant/single for all_elements" do
      
      # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
      exchange_rate = @elem.exchange_rate
      @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
      
      adult_expected  = sum_of( :cost_per_adult  ) / exchange_rate
      child_expected  = sum_of( :cost_per_child  ) / exchange_rate
      infant_expected = sum_of( :cost_per_infant ) / exchange_rate
      single_expected = sum_of( :cost_per_single ) / exchange_rate

      @trip.calc( :daily, :actual, :cost, :per, :adult,  @options ).should match_currency adult_expected 
      @trip.calc( :daily, :actual, :cost, :per, :child,  @options ).should match_currency child_expected 
      @trip.calc( :daily, :actual, :cost, :per, :infant, @options ).should match_currency infant_expected
      @trip.calc( :daily, :actual, :cost, :per, :single, @options ).should match_currency single_expected
 
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :per, :adult,  @options ) }
      child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :per, :child,  @options ) }
      infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :per, :infant, @options ) }
      single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :per, :single, @options ) }

      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected
      
    end


    it "should calculate daily LOCAL  cost  per adult/child/infant/single for all_elements + BIZ SUPP + TAXES" do
      
      adult_expected  = sum_of( :cost_per_adult  ) + sum_of( :biz_supp_per_adult  ) + sum_of( :taxes )
      child_expected  = sum_of( :cost_per_child  ) + sum_of( :biz_supp_per_child  ) + sum_of( :taxes )
      infant_expected = sum_of( :cost_per_infant ) + sum_of( :biz_supp_per_infant ) + sum_of( :taxes )
      single_expected = sum_of( :cost_per_single ) + 0
      
      @trip.calc( :daily, :local, :cost, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_expected 
      @trip.calc( :daily, :local, :cost, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_expected 
      @trip.calc( :daily, :local, :cost, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_expected
      @trip.calc( :daily, :local, :cost, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency single_expected
 
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :local, :cost, :per, :adult,  @with_biz_supp_and_taxes_options ) }
      child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :local, :cost, :per, :child,  @with_biz_supp_and_taxes_options ) }
      infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :local, :cost, :per, :infant, @with_biz_supp_and_taxes_options ) }
      single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :local, :cost, :per, :single, @with_biz_supp_and_taxes_options ) }

      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected

    end


    it "should calculate daily ACTUAL cost  per adult/child/infant/single for all_elements + BIZ SUPP + TAXES" do
      
      # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
      exchange_rate = @elem.exchange_rate
      @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
    
      adult_expected  = ( sum_of(:cost_per_adult ) + sum_of(:biz_supp_per_adult ) + sum_of(:taxes) ) / exchange_rate
      child_expected  = ( sum_of(:cost_per_child ) + sum_of(:biz_supp_per_child ) + sum_of(:taxes) ) / exchange_rate
      infant_expected = ( sum_of(:cost_per_infant) + sum_of(:biz_supp_per_infant) + sum_of(:taxes) ) / exchange_rate
      single_expected = ( sum_of(:cost_per_single) + 0                                             ) / exchange_rate  

      @trip.calc( :daily, :actual, :cost, :per, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_expected 
      @trip.calc( :daily, :actual, :cost, :per, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_expected 
      @trip.calc( :daily, :actual, :cost, :per, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_expected
      @trip.calc( :daily, :actual, :cost, :per, :single, @with_biz_supp_and_taxes_options ).should match_currency single_expected
 
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :per, :adult,  @with_biz_supp_and_taxes_options ) }
      child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :per, :child,  @with_biz_supp_and_taxes_options ) }
      infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :per, :infant, @with_biz_supp_and_taxes_options ) }
      single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :per, :single, @with_biz_supp_and_taxes_options ) }

      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected
      
    end
    




      describe " TOTALS" do    
        

        it "should calculate total actual cost  for_all adult/child/infant/single for all_elements" do
          
          # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
          exchange_rate = @elem.exchange_rate
          @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }

          adult_expected  = ( sum_of( :cost_per_adult  ) / exchange_rate ) * @trip.adults
          child_expected  = ( sum_of( :cost_per_child  ) / exchange_rate ) * @trip.children
          infant_expected = ( sum_of( :cost_per_infant ) / exchange_rate ) * @trip.infants
          single_expected = ( sum_of( :cost_per_single ) / exchange_rate ) * @trip.singles
                
          # WARNING: This test is over-simplified! It only passes when all elements have the same costs & travellers!
          @trip.calc( :day, :actual, :cost, :for_all, :adult,  @options ).should match_currency adult_expected 
          @trip.calc( :day, :actual, :cost, :for_all, :child,  @options ).should match_currency child_expected 
          @trip.calc( :day, :actual, :cost, :for_all, :infant, @options ).should match_currency infant_expected
          @trip.calc( :day, :actual, :cost, :for_all, :single, @options ).should match_currency single_expected
 
          # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
          adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :for_all, :adult,  @options ) }
          child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :for_all, :child,  @options ) }
          infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :for_all, :infant, @options ) }
          single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :for_all, :single, @options ) }

          adult_net.should  match_currency adult_expected 
          child_net.should  match_currency child_expected 
          infant_net.should match_currency infant_expected
          single_net.should match_currency single_expected
 
        end


        it "should calculate total actual cost  for_all adult/child/infant/single for all_elements + BIZ SUPP + TAXES" do
          
          # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
          exchange_rate = @elem.exchange_rate
          @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
        
          adult_expected  = ( ( sum_of(:cost_per_adult ) + sum_of(:biz_supp_per_adult ) + sum_of(:taxes) ) / exchange_rate ) * @trip.adults  
          child_expected  = ( ( sum_of(:cost_per_child ) + sum_of(:biz_supp_per_child ) + sum_of(:taxes) ) / exchange_rate ) * @trip.children
          infant_expected = ( ( sum_of(:cost_per_infant) + sum_of(:biz_supp_per_infant) + sum_of(:taxes) ) / exchange_rate ) * @trip.infants 
          single_expected = ( ( sum_of(:cost_per_single) + 0                                             ) / exchange_rate ) * @trip.singles     
          
          # WARNING: This test is over-simplified! It only passes when all elements have the same costs & travellers!
          @trip.calc( :day, :actual, :cost, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should match_currency adult_expected 
          @trip.calc( :day, :actual, :cost, :for_all, :child,  @with_biz_supp_and_taxes_options ).should match_currency child_expected 
          @trip.calc( :day, :actual, :cost, :for_all, :infant, @with_biz_supp_and_taxes_options ).should match_currency infant_expected
          @trip.calc( :day, :actual, :cost, :for_all, :single, @with_biz_supp_and_taxes_options ).should match_currency single_expected
 
          # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
          adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :for_all, :adult,  @with_biz_supp_and_taxes_options ) }
          child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :for_all, :child,  @with_biz_supp_and_taxes_options ) }
          infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :for_all, :infant, @with_biz_supp_and_taxes_options ) }
          single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :for_all, :single, @with_biz_supp_and_taxes_options ) }

          adult_net.should  match_currency adult_expected 
          child_net.should  match_currency child_expected 
          infant_net.should match_currency infant_expected
          single_net.should match_currency single_expected
          
        end


        # Same as above plus booking_fee:
        it "should calculate total actual cost  for_all adult/child/infant/single for all_elements + WITH_ALL_EXTRAS" do
          
          # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
          exchange_rate = @elem.exchange_rate
          @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
          @trip.save
        
          adult_expected  = ( ( ( sum_of(:cost_per_adult ) + sum_of(:biz_supp_per_adult ) + sum_of(:taxes) ) / exchange_rate ) + @booking_fee ) * @trip.adults  
          child_expected  = ( ( ( sum_of(:cost_per_child ) + sum_of(:biz_supp_per_child ) + sum_of(:taxes) ) / exchange_rate ) + @booking_fee ) * @trip.children
          infant_expected = ( ( ( sum_of(:cost_per_infant) + sum_of(:biz_supp_per_infant) + sum_of(:taxes) ) / exchange_rate ) + @booking_fee ) * @trip.infants 
          single_expected = ( ( ( sum_of(:cost_per_single) + 0                                             ) / exchange_rate ) + 0            ) * @trip.singles     

          #sum_of(:total_cost).should match_currency adult_costs + child_costs + infant_costs + single_costs

          # WARNING: This test is over-simplified! It only passes when all elements have the same costs & travellers!
          @trip.calc( :day, :actual, :cost, :for_all, :adult,  @with_all_extras_options ).should match_currency adult_expected 
          @trip.calc( :day, :actual, :cost, :for_all, :child,  @with_all_extras_options ).should match_currency child_expected 
          @trip.calc( :day, :actual, :cost, :for_all, :infant, @with_all_extras_options ).should match_currency infant_expected
          @trip.calc( :day, :actual, :cost, :for_all, :single, @with_all_extras_options ).should match_currency single_expected
 
          # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
          adult_net   = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :for_all, :adult,  @with_all_extras_options ) }
          child_net   = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :for_all, :child,  @with_all_extras_options ) }
          infant_net  = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :for_all, :infant, @with_all_extras_options ) }
          single_net  = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :for_all, :single, @with_all_extras_options ) }

          adult_net  += @trip.booking_fees(:adults)
          child_net  += @trip.booking_fees(:children)
          infant_net += @trip.booking_fees(:infants)
          single_net += 0

          adult_net.should  match_currency adult_expected 
          child_net.should  match_currency child_expected 
          infant_net.should match_currency infant_expected
          single_net.should match_currency single_expected

        end


        # Same as above plus booking_fee on trop of everything:
        it "should calculate total actual GROSS for_all adult/child/infant/single for all_elements + WITH_ALL_EXTRAS" do
        
          adult_expected   = 0; @trip.elements.each{|elem| adult_expected  += elem.calc( :daily, :actual, :gross, :for_all, :adult,  @with_all_extras_options ) }
          child_expected   = 0; @trip.elements.each{|elem| child_expected  += elem.calc( :daily, :actual, :gross, :for_all, :child,  @with_all_extras_options ) }
          infant_expected  = 0; @trip.elements.each{|elem| infant_expected += elem.calc( :daily, :actual, :gross, :for_all, :infant, @with_all_extras_options ) }
          single_expected  = 0; @trip.elements.each{|elem| single_expected += elem.calc( :daily, :actual, :gross, :for_all, :single, @with_all_extras_options ) }
          
          adult_expected  += @trip.booking_fees(:adults)
          child_expected  += @trip.booking_fees(:children)
          infant_expected += @trip.booking_fees(:infants)
          single_expected += 0
          
          @trip.calc( :daily, :actual, :gross, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
          @trip.calc( :daily, :actual, :gross, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
          @trip.calc( :daily, :actual, :gross, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
          @trip.calc( :daily, :actual, :gross, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
          
          # daily/total argument should make no difference to trip.calc:
          @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
          @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
          @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
          @trip.calc( :total, :actual, :gross, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
          
        end

      end



      describe " MARGINS" do    


        it "should calculate total actual MARGIN for_all adult/child/infant/single for all_elements" do

          # These net calcs were tested earlier:
          adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @options )
          child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @options )
          infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @options )
          single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @options )
          all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @options )
          
          # These gross calcs were tested earlier:
          adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @options )
          child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @options )
          infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @options )
          single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @options )
          all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @options )
          
          # Just to be absolutely sure:
          all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
          all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
          
          adult_expected  = adult_gross  - adult_net 
          child_expected  = child_gross  - child_net 
          infant_expected = infant_gross - infant_net
          single_expected = single_gross - single_net
          all_expected    = all_gross    - all_net
          
          @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @options ).should  match_currency adult_expected  
          @trip.calc( :daily, :actual, :margin, :for_all, :child,  @options ).should  match_currency child_expected  
          @trip.calc( :daily, :actual, :margin, :for_all, :infant, @options ).should  match_currency infant_expected 
          @trip.calc( :daily, :actual, :margin, :for_all, :single, @options ).should  match_currency single_expected 
          
          # daily/total argument should make no difference to trip.calc:
          @trip.calc( :total, :actual, :margin, :for_all, :adult,  @options ).should  match_currency adult_expected  
          @trip.calc( :total, :actual, :margin, :for_all, :child,  @options ).should  match_currency child_expected  
          @trip.calc( :total, :actual, :margin, :for_all, :infant, @options ).should  match_currency infant_expected 
          @trip.calc( :total, :actual, :margin, :for_all, :single, @options ).should  match_currency single_expected 
          
    # This has been moved to it's own separate example:
    # @trip.calc( :total, :actual, :margin, :for_all, :people, @options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual MARGIN for_all adult/child/infant/single for all_elements + BIZ_SUPP" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @with_biz_supp_options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :margin, :for_all, :child,  @with_biz_supp_options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :margin, :for_all, :infant, @with_biz_supp_options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :margin, :for_all, :single, @with_biz_supp_options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :margin, :for_all, :adult,  @with_biz_supp_options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :margin, :for_all, :child,  @with_biz_supp_options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :margin, :for_all, :infant, @with_biz_supp_options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :margin, :for_all, :single, @with_biz_supp_options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example:
    # @trip.calc( :total, :actual, :margin, :for_all, :people, @with_biz_supp_options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual MARGIN for_all adult/child/infant/single for all_elements + BIZ_SUPP + TAXES" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_and_taxes_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_and_taxes_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :margin, :for_all, :child,  @with_biz_supp_and_taxes_options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :margin, :for_all, :infant, @with_biz_supp_and_taxes_options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :margin, :for_all, :single, @with_biz_supp_and_taxes_options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :margin, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :margin, :for_all, :child,  @with_biz_supp_and_taxes_options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :margin, :for_all, :infant, @with_biz_supp_and_taxes_options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :margin, :for_all, :single, @with_biz_supp_and_taxes_options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example:
    # @trip.calc( :total, :actual, :margin, :for_all, :people, @with_biz_supp_and_taxes_options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual MARGIN for_all adult/child/infant/single for all_elements + WITH_ALL_EXTRAS" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_all_extras_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_all_extras_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_all_extras_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_all_extras_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_all_extras_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_all_extras_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_all_extras_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_all_extras_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_all_extras_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_all_extras_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :margin, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :margin, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :margin, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :margin, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :margin, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :margin, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :margin, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example:
    # @trip.calc( :total, :actual, :margin, :for_all, :people, @with_all_extras_options ).should  match_currency all_expected 
    
  end
  
  
  # Same margin tests again, this time for :travellers instead of adult/child/infant/single:
  
  it "should calculate total actual MARGIN for_all travellers for all_elements" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    #  @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @options ).should  match_currency adult_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :child,  @options ).should  match_currency child_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :infant, @options ).should  match_currency infant_expected 
    #  @trip.calc( :daily, :actual, :margin, :for_all, :single, @options ).should  match_currency single_expected 
    #  
    #  # daily/total argument should make no difference to trip.calc:
    #  @trip.calc( :total, :actual, :margin, :for_all, :adult,  @options ).should  match_currency adult_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :child,  @options ).should  match_currency child_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :infant, @options ).should  match_currency infant_expected 
    #  @trip.calc( :total, :actual, :margin, :for_all, :single, @options ).should  match_currency single_expected 
    
    @trip.calc( :total, :actual, :margin, :for_all, :people, @options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual MARGIN for_all travellers for all_elements + BIZ_SUPP" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    #  @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @with_biz_supp_options ).should  match_currency adult_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :child,  @with_biz_supp_options ).should  match_currency child_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :infant, @with_biz_supp_options ).should  match_currency infant_expected 
    #  @trip.calc( :daily, :actual, :margin, :for_all, :single, @with_biz_supp_options ).should  match_currency single_expected 
    #  
    #  # daily/total argument should make no difference to trip.calc:
    #  @trip.calc( :total, :actual, :margin, :for_all, :adult,  @with_biz_supp_options ).should  match_currency adult_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :child,  @with_biz_supp_options ).should  match_currency child_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :infant, @with_biz_supp_options ).should  match_currency infant_expected 
    #  @trip.calc( :total, :actual, :margin, :for_all, :single, @with_biz_supp_options ).should  match_currency single_expected 
    
    @trip.calc( :total, :actual, :margin, :for_all, :people, @with_biz_supp_options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual MARGIN for_all travellers for all_elements + BIZ_SUPP + TAXES" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_and_taxes_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_and_taxes_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    #  @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should  match_currency adult_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :child,  @with_biz_supp_and_taxes_options ).should  match_currency child_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :infant, @with_biz_supp_and_taxes_options ).should  match_currency infant_expected 
    #  @trip.calc( :daily, :actual, :margin, :for_all, :single, @with_biz_supp_and_taxes_options ).should  match_currency single_expected 
    #  
    #  # daily/total argument should make no difference to trip.calc:
    #  @trip.calc( :total, :actual, :margin, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should  match_currency adult_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :child,  @with_biz_supp_and_taxes_options ).should  match_currency child_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :infant, @with_biz_supp_and_taxes_options ).should  match_currency infant_expected 
    #  @trip.calc( :total, :actual, :margin, :for_all, :single, @with_biz_supp_and_taxes_options ).should  match_currency single_expected 
    
    @trip.calc( :total, :actual, :margin, :for_all, :people, @with_biz_supp_and_taxes_options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual MARGIN for_all travellers for all_elements + WITH_ALL_EXTRAS" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_all_extras_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_all_extras_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_all_extras_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_all_extras_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_all_extras_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_all_extras_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_all_extras_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_all_extras_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_all_extras_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_all_extras_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = adult_gross  - adult_net 
    child_expected  = child_gross  - child_net 
    infant_expected = infant_gross - infant_net
    single_expected = single_gross - single_net
    all_expected    = all_gross    - all_net
    
    #  @trip.calc( :daily, :actual, :margin, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
    #  @trip.calc( :daily, :actual, :margin, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
    #  @trip.calc( :daily, :actual, :margin, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
    #
    #  # daily/total argument should make no difference to trip.calc:
    #  @trip.calc( :total, :actual, :margin, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
    #  @trip.calc( :total, :actual, :margin, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
    #  @trip.calc( :total, :actual, :margin, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
    
    @trip.calc( :total, :actual, :margin, :for_all, :people, @with_all_extras_options ).should  match_currency all_expected 
    
  end
  
end




describe " PERCENT MARGINS" do    
  
  
  it "should calculate total actual PERCENT_MARGIN for_all adult/child/infant/single for all_elements" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :adult,  @options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :child,  @options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :infant, @options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :single, @options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :percent_margin, :for_all, :adult,  @options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :child,  @options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :infant, @options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :percent_margin, :for_all, :single, @options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example:
    # @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual PERCENT_MARGIN for_all adult/child/infant/single for all_elements + BIZ_SUPP" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :adult,  @with_biz_supp_options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :child,  @with_biz_supp_options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :infant, @with_biz_supp_options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :single, @with_biz_supp_options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :percent_margin, :for_all, :adult,  @with_biz_supp_options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :child,  @with_biz_supp_options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :infant, @with_biz_supp_options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :percent_margin, :for_all, :single, @with_biz_supp_options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example
    # @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @with_biz_supp_options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual PERCENT_MARGIN for_all adult/child/infant/single for all_elements + BIZ_SUPP + TAXES" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_and_taxes_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_and_taxes_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :child,  @with_biz_supp_and_taxes_options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :infant, @with_biz_supp_and_taxes_options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :single, @with_biz_supp_and_taxes_options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :percent_margin, :for_all, :adult,  @with_biz_supp_and_taxes_options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :child,  @with_biz_supp_and_taxes_options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :infant, @with_biz_supp_and_taxes_options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :percent_margin, :for_all, :single, @with_biz_supp_and_taxes_options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example
    # @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @with_biz_supp_and_taxes_options ).should  match_currency all_expected
    
  end
  
  
  it "should calculate total actual PERCENT_MARGIN for_all adult/child/infant/single for all_elements + WITH_ALL_EXTRAS" do
    
    # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
    exchange_rate = @elem.exchange_rate
    @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }.save
    @trip.save
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_all_extras_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_all_extras_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_all_extras_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_all_extras_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_all_extras_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_all_extras_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_all_extras_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_all_extras_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_all_extras_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_all_extras_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
    @trip.calc( :daily, :actual, :percent_margin, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
    
    # daily/total argument should make no difference to trip.calc:
    @trip.calc( :total, :actual, :percent_margin, :for_all, :adult,  @with_all_extras_options ).should  match_currency adult_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :child,  @with_all_extras_options ).should  match_currency child_expected  
    @trip.calc( :total, :actual, :percent_margin, :for_all, :infant, @with_all_extras_options ).should  match_currency infant_expected 
    @trip.calc( :total, :actual, :percent_margin, :for_all, :single, @with_all_extras_options ).should  match_currency single_expected 
    
    # This has been moved to it's own separate example
    # @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @with_all_extras_options ).should  match_currency all_expected
    
  end
  
  
  
  # Same margin tests again, this time for :travellers instead of adult/child/infant/single:
  
  it "should calculate total actual PERCENT_MARGIN for_all travellers for all_elements" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual PERCENT_MARGIN for_all travellers for all_elements + BIZ_SUPP" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @with_biz_supp_options ).should  match_currency all_expected 
    
  end
  
  
  it "should calculate total actual PERCENT_MARGIN for_all travellers for all_elements + BIZ_SUPP + TAXES" do
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_biz_supp_and_taxes_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_biz_supp_and_taxes_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_biz_supp_and_taxes_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_biz_supp_and_taxes_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_biz_supp_and_taxes_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_biz_supp_and_taxes_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    
    @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @with_biz_supp_and_taxes_options ).should  match_currency all_expected
    
  end
  
  
  it "should calculate total actual PERCENT_MARGIN for_all travellers for all_elements + WITH_ALL_EXTRAS" do
    
    # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
    exchange_rate = @elem.exchange_rate
    @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }.save
    @trip.save
    
    # These net calcs were tested earlier:
    adult_net       = @trip.calc( :total, :actual, :net,   :for_all, :adult,  @with_all_extras_options )
    child_net       = @trip.calc( :total, :actual, :net,   :for_all, :child,  @with_all_extras_options )
    infant_net      = @trip.calc( :total, :actual, :net,   :for_all, :infant, @with_all_extras_options )
    single_net      = @trip.calc( :total, :actual, :net,   :for_all, :single, @with_all_extras_options )
    all_net         = @trip.calc( :total, :actual, :net,   :for_all, :people, @with_all_extras_options )
    
    # These gross calcs were tested earlier:
    adult_gross     = @trip.calc( :total, :actual, :gross, :for_all, :adult,  @with_all_extras_options )
    child_gross     = @trip.calc( :total, :actual, :gross, :for_all, :child,  @with_all_extras_options )
    infant_gross    = @trip.calc( :total, :actual, :gross, :for_all, :infant, @with_all_extras_options )
    single_gross    = @trip.calc( :total, :actual, :gross, :for_all, :single, @with_all_extras_options )
    all_gross       = @trip.calc( :total, :actual, :gross, :for_all, :people, @with_all_extras_options )
    
    # Just to be absolutely sure:
    all_net.should   match_currency adult_net   + child_net   + infant_net   + single_net   
    all_gross.should match_currency adult_gross + child_gross + infant_gross + single_gross
    
    adult_expected  = 100 * ( adult_gross  - adult_net  ) / adult_gross 
    child_expected  = 100 * ( child_gross  - child_net  ) / child_gross 
    infant_expected = 100 * ( infant_gross - infant_net ) / infant_gross
    single_expected = 100 * ( single_gross - single_net ) / single_gross
    all_expected    = 100 * ( all_gross - all_net ) / all_gross
    
    # Avoid Division by zero -> Infinity!
    adult_expected  = 0 if adult_gross  == 0
    child_expected  = 0 if child_gross  == 0
    infant_expected = 0 if infant_gross == 0
    single_expected = 0 if single_gross == 0
    all_expected    = 0 if all_gross    == 0
    
    @trip.calc( :total, :actual, :percent_margin, :for_all, :people, @with_all_extras_options ).should  match_currency all_expected
    
  end
  
end

end





  describe " use final prices TOTALS" do    
    
    
    it "should calculate total actual cost  for_all travellers/adult/child/infant/single for all_elements" do
      
      options = @options.merge( :final_prices => true )
      
      # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
      exchange_rate = @elem.exchange_rate
      @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
      
      adult_expected  = ( sum_of( :cost_per_adult  ) / exchange_rate ) * @trip.adults
      child_expected  = ( sum_of( :cost_per_child  ) / exchange_rate ) * @trip.children
      infant_expected = ( sum_of( :cost_per_infant ) / exchange_rate ) * @trip.infants
      single_expected = ( sum_of( :cost_per_single ) / exchange_rate ) * @trip.singles
      all_expected    = adult_expected + child_expected + infant_expected + single_expected
      
      # WARNING: This test is over-simplified! It only passes when all elements have the same costs & travellers!
      @trip.calc( :day, :actual, :cost, :for_all, :adult,  options ).should match_currency adult_expected 
      @trip.calc( :day, :actual, :cost, :for_all, :child,  options ).should match_currency child_expected 
      @trip.calc( :day, :actual, :cost, :for_all, :infant, options ).should match_currency infant_expected
      @trip.calc( :day, :actual, :cost, :for_all, :single, options ).should match_currency single_expected
      @trip.calc( :day, :actual, :cost, :for_all, :people, options ).should match_currency all_expected
      
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :for_all, :adult,  options ) }
      child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :for_all, :child,  options ) }
      infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :for_all, :infant, options ) }
      single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :for_all, :single, options ) }
      all_net    = 0; @trip.elements.each{|elem| all_net    += elem.calc( :daily, :actual, :cost, :for_all, :people, options ) }
      
      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected
      all_net.should    match_currency all_expected
      
    end
    
    
    it "should calculate total actual cost  for_all adult/child/infant/single for all_elements + BIZ SUPP + TAXES" do
      
      with_biz_supp_and_taxes_options = @with_biz_supp_and_taxes_options.merge( :final_prices => true )
      
      # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
      exchange_rate = @elem.exchange_rate
      @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
      
      adult_expected  = ( ( sum_of(:cost_per_adult ) + sum_of(:biz_supp_per_adult ) + sum_of(:taxes) ) / exchange_rate ) * @trip.adults  
      child_expected  = ( ( sum_of(:cost_per_child ) + sum_of(:biz_supp_per_child ) + sum_of(:taxes) ) / exchange_rate ) * @trip.children
      infant_expected = ( ( sum_of(:cost_per_infant) + sum_of(:biz_supp_per_infant) + sum_of(:taxes) ) / exchange_rate ) * @trip.infants 
      single_expected = ( ( sum_of(:cost_per_single) + 0                                             ) / exchange_rate ) * @trip.singles     
      all_expected    = adult_expected + child_expected + infant_expected + single_expected
      
      # WARNING: This test is over-simplified! It only passes when all elements have the same costs & travellers!
      @trip.calc( :day, :actual, :cost, :for_all, :adult,  with_biz_supp_and_taxes_options ).should match_currency adult_expected 
      @trip.calc( :day, :actual, :cost, :for_all, :child,  with_biz_supp_and_taxes_options ).should match_currency child_expected 
      @trip.calc( :day, :actual, :cost, :for_all, :infant, with_biz_supp_and_taxes_options ).should match_currency infant_expected
      @trip.calc( :day, :actual, :cost, :for_all, :single, with_biz_supp_and_taxes_options ).should match_currency single_expected
      @trip.calc( :day, :actual, :cost, :for_all, :people, with_biz_supp_and_taxes_options ).should match_currency all_expected
      
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net  = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :for_all, :adult,  with_biz_supp_and_taxes_options ) }
      child_net  = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :for_all, :child,  with_biz_supp_and_taxes_options ) }
      infant_net = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :for_all, :infant, with_biz_supp_and_taxes_options ) }
      single_net = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :for_all, :single, with_biz_supp_and_taxes_options ) }
      all_net    = 0; @trip.elements.each{|elem| all_net    += elem.calc( :daily, :actual, :cost, :for_all, :people, with_biz_supp_and_taxes_options ) }
      
      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected
      all_net.should    match_currency all_expected
      
    end
    
    
    # Same as above plus booking_fee:
    it "should calculate total actual cost  for_all adult/child/infant/single for all_elements + WITH_ALL_EXTRAS" do
      
      # Ensure we're using the all important final_prices flag:
      with_all_extras_options = @with_all_extras_options.merge( :final_prices => true )
      
      # To simplify calculation of expected results, ensure all the elements have the same exchange_rate
      exchange_rate = @elem.exchange_rate
      @trip.trip_elements.each{ |elem| elem.exchange_rate = exchange_rate }
      @trip.save
      
      adult_expected  = ( ( ( sum_of(:cost_per_adult ) + sum_of(:biz_supp_per_adult ) + sum_of(:taxes) ) / exchange_rate ) + @booking_fee ) * @trip.adults  
      child_expected  = ( ( ( sum_of(:cost_per_child ) + sum_of(:biz_supp_per_child ) + sum_of(:taxes) ) / exchange_rate ) + @booking_fee ) * @trip.children
      infant_expected = ( ( ( sum_of(:cost_per_infant) + sum_of(:biz_supp_per_infant) + sum_of(:taxes) ) / exchange_rate ) + @booking_fee ) * @trip.infants 
      single_expected = ( ( ( sum_of(:cost_per_single) + 0                                             ) / exchange_rate ) + 0            ) * @trip.singles     
      all_expected    = adult_expected + child_expected + infant_expected + single_expected
      
      #sum_of(:total_cost).should match_currency adult_costs + child_costs + infant_costs + single_costs
      
      # WARNING: This test is over-simplified! It only passes when all elements have the same costs & travellers!
      @trip.calc( :total, :actual, :cost, :for_all, :adult,  with_all_extras_options ).should match_currency adult_expected 
      @trip.calc( :total, :actual, :cost, :for_all, :child,  with_all_extras_options ).should match_currency child_expected 
      @trip.calc( :total, :actual, :cost, :for_all, :infant, with_all_extras_options ).should match_currency infant_expected
      @trip.calc( :total, :actual, :cost, :for_all, :single, with_all_extras_options ).should match_currency single_expected
      @trip.calc( :total, :actual, :cost, :for_all, :people, with_all_extras_options ).should match_currency all_expected
      
      # And an alternative way of getting to the same result: (We test this too because we use this technique later for preparing expected results!)
      adult_net   = 0; @trip.elements.each{|elem| adult_net  += elem.calc( :daily, :actual, :cost, :for_all, :adult,  with_all_extras_options ) }
      child_net   = 0; @trip.elements.each{|elem| child_net  += elem.calc( :daily, :actual, :cost, :for_all, :child,  with_all_extras_options ) }
      infant_net  = 0; @trip.elements.each{|elem| infant_net += elem.calc( :daily, :actual, :cost, :for_all, :infant, with_all_extras_options ) }
      single_net  = 0; @trip.elements.each{|elem| single_net += elem.calc( :daily, :actual, :cost, :for_all, :single, with_all_extras_options ) }
      all_net     = 0; @trip.elements.each{|elem| all_net    += elem.calc( :daily, :actual, :cost, :for_all, :people, with_all_extras_options ) }
      
      adult_net  += @trip.booking_fees(:adults)
      child_net  += @trip.booking_fees(:children)
      infant_net += @trip.booking_fees(:infants)
      single_net += 0
      all_net    += @trip.booking_fees(:all)
      
      adult_net.should  match_currency adult_expected 
      child_net.should  match_currency child_expected 
      infant_net.should match_currency infant_expected
      single_net.should match_currency single_expected
      all_net.should    match_currency all_expected
      
      @trip.total_cost.should match_currency all_expected
      
      # See if adjusting the biz_supp causes the expected change in trip.total_cost:
      @trip.elements.first.biz_supp_per_adult = @trip.elements.first.biz_supp_per_adult + 100
      @trip.save
      @trip.total_cost.should match_currency all_expected + ( 100 / exchange_rate * @trip.adults )
      
      # No point in testing @trip.price_per_adult/biz_supp etc here because they do not affect net cost.
      
    end
    
    
    # Same as above plus booking_fee on trop of everything:
    it "should calculate total actual GROSS for_all adult/child/infant/single for all_elements + WITH_ALL_EXTRAS" do
      
      with_all_extras_options = @with_all_extras_options.merge( :final_prices => true )
      
      # These calculations already been tested earlier:
      adult_expected   = ( @trip.price_per_adult  + @trip.price_per_adult_biz_supp  ) * @trip.adults
      child_expected   = ( @trip.price_per_child  + @trip.price_per_child_biz_supp  ) * @trip.children
      infant_expected  = ( @trip.price_per_infant + @trip.price_per_infant_biz_supp ) * @trip.infants
      single_expected  = ( @trip.price_per_single + @trip.price_per_single_biz_supp ) * @trip.singles
      all_expected     = adult_expected + child_expected + infant_expected + single_expected
      
      # daily/total argument should make no difference to trip.calc:
      @trip.calc( :total, :actual, :gross, :for_all, :adult,  with_all_extras_options ).should  match_currency adult_expected  
      @trip.calc( :total, :actual, :gross, :for_all, :child,  with_all_extras_options ).should  match_currency child_expected  
      @trip.calc( :total, :actual, :gross, :for_all, :infant, with_all_extras_options ).should  match_currency infant_expected 
      @trip.calc( :total, :actual, :gross, :for_all, :single, with_all_extras_options ).should  match_currency single_expected 
      @trip.calc( :total, :actual, :gross, :for_all, :people, with_all_extras_options ).should  match_currency all_expected 
      
      @trip.total_price.should match_currency all_expected
      
      # See if adjusting the biz_supp causes the expected change in trip.total_price:
      @trip.price_per_adult_biz_supp = @trip.price_per_adult_biz_supp + 100
      @trip.save
      @trip.total_price.should match_currency all_expected + ( 100 * @trip.adults )
      
    end
    
  end


#=end



end