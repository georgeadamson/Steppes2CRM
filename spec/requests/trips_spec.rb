require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip exists" do
  Trip.all.destroy!
  request(resource(:trips), :method => "POST", 
    :params => { :trip => { :id => nil }})
end

describe "resource(:trips)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trips))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trips" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip exists" do
    before(:each) do
      @response = request(resource(:trips))
    end
    
    it "has a list of trips" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Trip.all.destroy!
      @response = request(resource(:trips), :method => "POST", 
        :params => { :trip => { :id => nil }})
    end
    
    it "redirects to resource(:trips)" do
      @response.should redirect_to(resource(Trip.first), :message => {:notice => "trip was successfully created"})
    end
    
  end
end

describe "resource(@trip)" do 
  describe "a successful DELETE", :given => "a trip exists" do
     before(:each) do
       @response = request(resource(Trip.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trips))
     end

   end
end

describe "resource(:trips, :new)" do
  before(:each) do
    @response = request(resource(:trips, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip, :edit)", :given => "a trip exists" do
  before(:each) do
    @response = request(resource(Trip.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip)", :given => "a trip exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Trip.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip = Trip.first
      @response = request(resource(@trip), :method => "PUT", 
        :params => { :trip => {:id => @trip.id} })
    end
  
    it "redirect to the trip show action" do
      @response.should redirect_to(resource(@trip))
    end
  end
  
end

