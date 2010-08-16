require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S spec spec/models/tour_spec.rb

describe Tour do

  before :each do

    @tour = Tour.new( valid_tour_attributes )
    @trip = Trip.new( valid_trip_attributes )

  end

  after :each do

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

    @tour.trips.first.type_id.should == TripType::FIXED_DEP
    
  end

  it "should save trips with no default client" do

    @tour.save.should be_true
    @tour.trips.new( valid_trip_attributes )
    @tour.save.should be_true

    @tour.trips.first.clients.should have(0).clients

    @tour.trips.first.reload
    @tour.trips.first.clients.should have(0).clients
    
  end

end


