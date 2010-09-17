require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# This tests the copy-trip functionalty.
# To run this: jruby -X-C -S rake spec SPEC=spec/models/trip_clone_spec.rb

describe Trip do

  before :all do

    @company      = Company.first_or_create()
    @world_region = WorldRegion.first_or_create( { :name => 'Dummy Region' }, { :name => 'Dummy Region' } )
    @mailing_zone = MailingZone.first_or_create( { :name => 'Dummy Zone'   }, { :name => 'Dummy Zone'   } )
    @country1     = Country.first_or_create( { :name => 'Country 1' }, { :code => 'C1', :name => 'Country 1', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @country2     = Country.first_or_create( { :name => 'Country 2' }, { :code => 'C2', :name => 'Country 2', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @country3     = Country.first_or_create( { :name => 'Country 3' }, { :code => 'C3', :name => 'Country 3', :companies_ids => [@company.id], :world_region_id => @world_region.id, :mailing_zone_id => @mailing_zone.id } )
    @title        = Title.create( :name => 'Mr' )
    @client1      = Client.first_or_create(  { :name => 'Client 1'  }, { :title => @title, :name => 'Client 1', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @client2      = Client.first_or_create(  { :name => 'Client 2'  }, { :title => @title, :name => 'Client 2', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    @client3      = Client.first_or_create(  { :name => 'Client 3'  }, { :title => @title, :name => 'Client 3', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )

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
    @tripA    = Trip.create( valid_trip_attributes.merge(number_of_travellers) )
    @tripB    = Trip.create( valid_trip_attributes.merge(number_of_travellers) )
    @elemA    = @tripA.trip_elements.create(valid_flight_attributes)
    @elemB    = @tripB.trip_elements.create(valid_flight_attributes)
    
  end
  

  after :each do
    TripClient.all.destroy
    TripCountry.all.destroy
    TripElement.all.destroy
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
  







  it 'should be valid' do
    @tripA.should be_valid
    @tripB.should be_valid
    @tripA.trip_elements.should have(1).item
    @tripB.trip_elements.should have(1).item
  end
 

  it 'should not copy elements from another trip when not specified' do

    countA = @tripA.trip_elements.length
    countB = @tripB.trip_elements.length

    @tripA.update( :name => 'New name' ).should be_true
    
    @tripA.trip_elements.should have(countA).item
    @tripB.trip_elements.should have(countB).item

    @tripA.update( :do_copy_trip_id => @tripB.id ).should be_true
    
    @tripA.trip_elements.should have(countA).item
    @tripB.trip_elements.should have(countB).item
    
  end

  it 'should not copy countries from another trip when not specified' do

    countA = @tripA.countries.length
    countB = @tripB.countries.length

    @tripA.update( :name => 'New name' ).should be_true
    
    @tripA.countries.should have(countA).item
    @tripB.countries.should have(countB).item

    @tripA.update( :do_copy_trip_id => @tripB.id ).should be_true
    
    @tripA.countries.should have(countA).item
    @tripB.countries.should have(countB).item
    
  end

  it 'should not copy clients from another trip when not specified' do

    countA = @tripA.clients.length
    countB = @tripB.clients.length

    @tripA.update( :name => 'New name' ).should be_true
    
    @tripA.clients.should have(countA).item
    @tripB.clients.should have(countB).item

    @tripA.update( :do_copy_trip_id => @tripB.id ).should be_true
    
    @tripA.clients.should have(countA).item
    @tripB.clients.should have(countB).item
    
  end
 

  it 'should copy elements from another trip' do

    countA = @tripA.trip_elements.length
    countB = @tripB.trip_elements.length

    @tripA.update( :do_copy_trip_id => @tripB.id, :do_copy_trip_elements => true ).should be_true
    
    @tripA.trip_elements.should have(countA+countB).items
    @tripB.trip_elements.should have(countB).item           # TripB should be unaffected.
    
  end

  	  
  it 'should copy elements from another trip and adjust their dates to fit' do

    countA = @tripA.trip_elements.length
    countB = @tripB.trip_elements.length
    @elemA = @tripA.trip_elements.last
    @elemB = @tripB.trip_elements.last

    @elemA.start_date = ( @tripA.start_date.to_time + 0.days ).to_datetime  # Day 1
    @elemA.end_date   = ( @tripA.start_date.to_time + 2.days ).to_datetime  # duration 2 days
    @elemB.start_date = ( @tripB.start_date.to_time + 2.days ).to_datetime  # Day 3
    @elemB.end_date   = ( @tripB.start_date.to_time + 6.days ).to_datetime  # duration 4 days
    @tripA.save.should be_true
    @tripB.save.should be_true

    @elemA.day.should == 1
    @elemB.day.should == 3
    (@elemA.end_date - @elemA.start_date).should == 2
    (@elemB.end_date - @elemB.start_date).should == 4

    @tripA.update( :do_copy_trip_id => @tripB.id, :do_copy_trip_elements => true ).should be_true
    
    @tripA.trip_elements.should have( countA + countB ).items
    
    # The last element in tripA should be a clone of the last element in tripB...
    elemC  = @tripA.trip_elements.last
    @elemB = @tripB.trip_elements.last
    
    elemC.day.should == 3                             # Same as elemB
    (elemC.end_date - elemC.start_date).should == 4   # Same as elemB
    
  end
  
  
  it 'should copy countries from another trip' do

    # Set up tripB with an extra country:
    new_country = Country.create( valid_country_attributes.merge( :name => 'New', :code => 'NN' ) )
    @tripB.countries << new_country
    puts @tripB.errors.inspect      unless @tripB.valid?
    puts new_country.errors.inspect unless new_country.valid?
    @tripB.save.should be_true

    countA = @tripA.countries.length
    countB = @tripB.countries.length
    @tripB.countries.should have(countA+1).countries
    
    @tripA.update( :do_copy_trip_id => @tripB.id, :do_copy_trip_countries => true ).should be_true
    
    @tripA.countries.should have(countA + 1).countries
    @tripB.countries.should have(countB).countries           # TripB should be unaffected.
    
  end
  
  
  
  it 'should copy clients from another trip' do

    # Set up tripB with an extra country:
    new_client = Client.create( valid_client_attributes.merge( :name => 'New' ) )
    @tripB.clients << new_client
    puts @tripB.errors.inspect     unless @tripB.valid?
    puts new_client.errors.inspect unless new_client.valid?
    @tripB.save.should be_true

    countA = @tripA.clients.length
    countB = @tripB.clients.length
    @tripB.clients.should have(countA + 1).clients
    
    @tripA.update( :do_copy_trip_id => @tripB.id, :do_copy_trip_clients => true ).should be_true
    
    @tripA.clients.should have(countA+1).clients
    @tripB.clients.should have(countB).clients           # TripB should be unaffected.
    
  end


end