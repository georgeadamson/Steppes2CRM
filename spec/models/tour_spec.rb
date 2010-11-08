require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S spec spec/models/tour_spec.rb

describe Tour do

  before :each do

    @tour = Tour.new( valid_tour_attributes )
    @trip = Trip.new( valid_trip_attributes )

  end

  after :each do

    @trip.destroy
    @tour.destroy
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

    @tour.trips.first.kind_id.should == TripType::TOUR_TEMPLATE
    
  end

  it "should save trips with no default client" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    @tour.trips.first.clients.should have(0).clients

    @tour.trips.first.reload
    @tour.trips.first.clients.should have(0).clients
    
  end

  it "should clone trip template for a client trip" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    template_trip = @tour.trips.first
    template_trip.kind_id.should == TripType::TOUR_TEMPLATE
    template_trip.tour_template?.should be_true
    new_trip      = @tour.create_trip_from_template( template_trip )

    new_trip.tour_id.should == @tour.id
    new_trip.kind_id.should == TripType::FIXED_DEP
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


