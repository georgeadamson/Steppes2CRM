require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/airport_spec.rb


describe Airport do

  before :each do
    @airport = Airport.new( valid_airport_attributes )
  end

  after :each do
    @airport.destroy
  end

  it "should be valid" do
    @airport.should be_valid
  end

  it "should set and get fields with foreign language characters" do
    @airport = Airport.new( valid_airport_attributes )
    @airport.save.should be_true
    @airport.reload
    @airport.name.should == valid_airport_attributes[:name]  # This line fails
  end

end