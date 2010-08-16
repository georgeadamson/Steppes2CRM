require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_element_type exists" do
  TripElementType.all.destroy!
  request(resource(:trip_element_types), :method => "POST", 
    :params => { :trip_element_type => { :id => nil }})
end

describe "resource(:trip_element_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_element_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_element_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_element_type exists" do
    before(:each) do
      @response = request(resource(:trip_element_types))
    end
    
    it "has a list of trip_element_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripElementType.all.destroy!
      @response = request(resource(:trip_element_types), :method => "POST", 
        :params => { :trip_element_type => { :id => nil }})
    end
    
    it "redirects to resource(:trip_element_types)" do
      @response.should redirect_to(resource(TripElementType.first), :message => {:notice => "trip_element_type was successfully created"})
    end
    
  end
end

describe "resource(@trip_element_type)" do 
  describe "a successful DELETE", :given => "a trip_element_type exists" do
     before(:each) do
       @response = request(resource(TripElementType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_element_types))
     end

   end
end

describe "resource(:trip_element_types, :new)" do
  before(:each) do
    @response = request(resource(:trip_element_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_element_type, :edit)", :given => "a trip_element_type exists" do
  before(:each) do
    @response = request(resource(TripElementType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_element_type)", :given => "a trip_element_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripElementType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_element_type = TripElementType.first
      @response = request(resource(@trip_element_type), :method => "PUT", 
        :params => { :trip_element_type => {:id => @trip_element_type.id} })
    end
  
    it "redirect to the trip_element_type show action" do
      @response.should redirect_to(resource(@trip_element_type))
    end
  end
  
end

