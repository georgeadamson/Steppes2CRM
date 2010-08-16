require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_type exists" do
  TripType.all.destroy!
  request(resource(:trip_types), :method => "POST", 
    :params => { :trip_type => { :id => nil }})
end

describe "resource(:trip_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_type exists" do
    before(:each) do
      @response = request(resource(:trip_types))
    end
    
    it "has a list of trip_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripType.all.destroy!
      @response = request(resource(:trip_types), :method => "POST", 
        :params => { :trip_type => { :id => nil }})
    end
    
    it "redirects to resource(:trip_types)" do
      @response.should redirect_to(resource(TripType.first), :message => {:notice => "trip_type was successfully created"})
    end
    
  end
end

describe "resource(@trip_type)" do 
  describe "a successful DELETE", :given => "a trip_type exists" do
     before(:each) do
       @response = request(resource(TripType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_types))
     end

   end
end

describe "resource(:trip_types, :new)" do
  before(:each) do
    @response = request(resource(:trip_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_type, :edit)", :given => "a trip_type exists" do
  before(:each) do
    @response = request(resource(TripType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_type)", :given => "a trip_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_type = TripType.first
      @response = request(resource(@trip_type), :method => "PUT", 
        :params => { :trip_type => {:id => @trip_type.id} })
    end
  
    it "redirect to the trip_type show action" do
      @response.should redirect_to(resource(@trip_type))
    end
  end
  
end

