require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_client exists" do
  TripClient.all.destroy!
  request(resource(:trip_clients), :method => "POST", 
    :params => { :trip_client => { :id => nil }})
end

describe "resource(:trip_clients)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_clients))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_clients" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_client exists" do
    before(:each) do
      @response = request(resource(:trip_clients))
    end
    
    it "has a list of trip_clients" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripClient.all.destroy!
      @response = request(resource(:trip_clients), :method => "POST", 
        :params => { :trip_client => { :id => nil }})
    end
    
    it "redirects to resource(:trip_clients)" do
      @response.should redirect_to(resource(TripClient.first), :message => {:notice => "trip_client was successfully created"})
    end
    
  end
end

describe "resource(@trip_client)" do 
  describe "a successful DELETE", :given => "a trip_client exists" do
     before(:each) do
       @response = request(resource(TripClient.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_clients))
     end

   end
end

describe "resource(:trip_clients, :new)" do
  before(:each) do
    @response = request(resource(:trip_clients, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_client, :edit)", :given => "a trip_client exists" do
  before(:each) do
    @response = request(resource(TripClient.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_client)", :given => "a trip_client exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripClient.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_client = TripClient.first
      @response = request(resource(@trip_client), :method => "PUT", 
        :params => { :trip_client => {:id => @trip_client.id} })
    end
  
    it "redirect to the trip_client show action" do
      @response.should redirect_to(resource(@trip_client))
    end
  end
  
end

