require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/trip_update_exchange_rates_spec.rb

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
    @flight   = @trip.trip_elements.create( valid_flight_attributes.merge :supplier_id => Supplier.first.id )
    @flight2  = @trip.trip_elements.create( valid_flight_attributes.merge :supplier_id => Supplier.last.id )
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

    it 'should calculate total_cost' do
      @trip.total_cost.should be > 0
    end

  end


  describe ' update rates' do

    it 'should update exchange rates of all elements' do

        old_rate1 = @trip.elements.first.exchange_rate
        old_rate2 = @trip.elements.last.exchange_rate

        currency1 = @trip.elements.first.supplier.currency
        currency2 = @trip.elements.last.supplier.currency
        currency1.update( :new_rate => 10, :new_rate_on_date => Date.today )
        currency2.update( :new_rate => 20, :new_rate_on_date => Date.today )
        puts "Changed currency #{ currency1.name } to #{ currency1.rate }"
        puts "Changed currency #{ currency2.name } to #{ currency2.rate }"

        @trip.update_exchange_rates

        new_rate1 = @trip.elements.first.exchange_rate
        new_rate1.should_not == old_rate1
        new_rate2 = @trip.elements.last.exchange_rate
        new_rate2.should_not == old_rate2

    end

  end

end