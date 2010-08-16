require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_element exists" do
  TripElement.all.destroy!
  request(resource(:trip_elements), :method => "POST", 
    :params => { :trip_element => { :id => nil }})
end

describe "resource(:trip_elements)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_elements))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_elements" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_element exists" do
    before(:each) do
      @response = request(resource(:trip_elements))
    end
    
    it "has a list of trip_elements" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripElement.all.destroy!
      @response = request(resource(:trip_elements), :method => "POST", 
        :params => { :trip_element => { :id => nil }})
    end
    
    it "redirects to resource(:trip_elements)" do
      @response.should redirect_to(resource(TripElement.first), :message => {:notice => "trip_element was successfully created"})
    end
    
  end
end

describe "resource(@trip_element)" do 
  describe "a successful DELETE", :given => "a trip_element exists" do
     before(:each) do
       @response = request(resource(TripElement.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_elements))
     end

   end
end

describe "resource(:trip_elements, :new)" do
  before(:each) do
    @response = request(resource(:trip_elements, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_element, :edit)", :given => "a trip_element exists" do
  before(:each) do
    @response = request(resource(TripElement.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_element)", :given => "a trip_element exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripElement.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_element = TripElement.first
      @response = request(resource(@trip_element), :method => "PUT", 
        :params => { :trip_element => {:id => @trip_element.id} })
    end
  
    it "redirect to the trip_element show action" do
      @response.should redirect_to(resource(@trip_element))
    end
  end
  
end

