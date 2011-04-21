require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S spec spec/models/tour_spec.rb


# Helper method to add 3 clients to a trip: (The first one will be "primary")
def add_3_clients_to_trip!( trip )

  trip.clients << Client.first_or_create( valid_client_attributes.merge :name => 'ClientA' )
  trip.clients << Client.first_or_create( valid_client_attributes.merge :name => 'ClientB' )
  trip.clients << Client.first_or_create( valid_client_attributes.merge :name => 'ClientC' )
  trip.save.should be_true
  trip.clients.should have(3).clients
  trip.trip_clients.should have(3).trip_clients

  trip.trip_clients.first( TripClient.client.name => 'ClientA' ).update( :is_primary => true )
  trip.trip_clients.reload
  trip.trip_clients.all( :is_primary => true ).should have(1).trip_clients

end


describe Tour do

  before :each do

    @tour = Tour.new( valid_tour_attributes )
    @trip = Trip.new( valid_trip_attributes )

  end

  after :each do

    @trip.destroy
    @tour.destroy
    TripClient.all.destroy
    Trip.all.destroy
    Tour.all.destroy

  end



  it "should be valid" do
    @tour.should be_valid
  end


  it "should be using valid test data" do
    @trip.should be_valid
  end


  it "should save trips with a tour_id" do

    @tour.save.should be_true
    @tour.trips.should have(0).trips

    # Add a trip to the tour:
    trip = @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true
    @tour.trips.should have(1).trip
    trip.tour_id.should == @tour.id

  end


  it "should save trips with a default trip type of Fixed Departure" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    @tour.trips.first.type_id.should == TripType::TOUR_TEMPLATE
    
  end


  it "should save trips with no default client" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    @tour.trips.first.clients.should have(0).clients

    @tour.trips.first.reload
    @tour.trips.first.clients.should have(0).clients
    
  end


  it "should clone trip template for a client to create a fixed departure" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    template_trip = @tour.trips.first
    template_trip.type_id.should == TripType::TOUR_TEMPLATE
    template_trip.tour_template?.should be_true

    new_trip = @tour.create_trip_from_template( template_trip )

    new_trip.tour_id.should == @tour.id
    new_trip.type_id.should == TripType::FIXED_DEP
    new_trip.fixed_dep?.should be_true
    new_trip.save.should be_true
    
  end


  it "should copy clients when creating a fixed departure" do
    
    @tour.save
    @tour.trips.create( valid_trip_attributes )
    
    template_trip = @tour.trips.first
    template_trip.clients.should have(0).clients
    add_3_clients_to_trip!( template_trip )
    
    new_trip = @tour.create_trip_from_template( template_trip )
    new_trip.save.should be_true
    
    template_trip.clients.should have(3).clients

  end


  it "should make current client primary when creating a fixed departure" do
    
    @tour.save
    @tour.trips.create( valid_trip_attributes )
    
    template_trip = @tour.trips.first
    template_trip.clients.should have(0).clients
    add_3_clients_to_trip! template_trip

    clientA_id = template_trip.clients.first( :name => 'ClientA' ).id
    clientB_id = template_trip.clients.first( :name => 'ClientB' ).id
    clientC_id = template_trip.clients.first( :name => 'ClientC' ).id
    
    new_trip = @tour.create_trip_from_template( template_trip )
    new_trip.save.should be_true
    
    # Just verify our test data before proceeding:
    new_trip.primaries.should have(1).client
    new_trip.primaries.first.name.should == 'ClientA'

    # Verify that we can switch primary client:
    new_trip.set_primary_client! clientC_id
    new_trip.primaries.should have(1).client
    new_trip.primaries.first.name.should == 'ClientC'

    # Verify that we can switch primary client again:
    new_trip.set_primary_client! clientB_id
    new_trip.primaries.should have(1).client
    new_trip.primaries.first.name.should == 'ClientB'

    # Verify that we can add a second primary client:
    new_trip.set_primary_client! clientA_id, :allow_fellow_primaries
    new_trip.primaries.should have(2).clients
    new_trip.primaries.first( :name => 'ClientA' ).id.should == clientA_id
    new_trip.primaries.first( :name => 'ClientB' ).id.should == clientB_id

  end


  it "should copy elements too when creating a fixed departure" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    elem = @tour.trips.first.elements.new(valid_flight_attributes)
    puts elem.errors.inspect unless elem.valid?
    elem.save.should be_true

    template_trip = @tour.trips.first
    template_trip.type_id.should == TripType::TOUR_TEMPLATE
    template_trip.tour_template?.should be_true

    new_trip = @tour.create_trip_from_template( template_trip )

    new_trip.tour_id.should == @tour.id
    new_trip.type_id.should == TripType::FIXED_DEP
    new_trip.fixed_dep?.should be_true
    new_trip.save.should be_true
    
  end

  it "should not count client's copy of fixed departure trips among its trips" do

    @tour.save.should be_true
    @tour.trips.should have(0).trips  # Something odd going on: Without this line the subsequent have(1) finds 2 trips!
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true
    @tour.trips.should have(1).trip

    template_trip = @tour.trips.first
    new_trip      = @tour.create_trip_from_template( template_trip )
    new_trip.save.should be_true
    
    @tour.trips.should have(1).trip

    # Just to be absolutely sure:
    Trip.all( :tour_id => @tour.id ).should have(2).trips
    Trip.all( :tour_id => @tour.id, :type_id => TripType::TOUR_TEMPLATE ).should have(1).trip
    Trip.all( :tour_id => @tour.id, :type_id => TripType::FIXED_DEP     ).should have(1).trip
    
  end

end


