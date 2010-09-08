require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_client_status exists" do
  TripClientStatus.all.destroy!
  request(resource(:trip_client_statuses), :method => "POST", 
    :params => { :trip_client_status => { :id => nil }})
end

describe "resource(:trip_client_statuses)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_client_statuses))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_client_statuses" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_client_status exists" do
    before(:each) do
      @response = request(resource(:trip_client_statuses))
    end
    
    it "has a list of trip_client_statuses" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripClientStatus.all.destroy!
      @response = request(resource(:trip_client_statuses), :method => "POST", 
        :params => { :trip_client_status => { :id => nil }})
    end
    
    it "redirects to resource(:trip_client_statuses)" do
      @response.should redirect_to(resource(TripClientStatus.first), :message => {:notice => "trip_client_status was successfully created"})
    end
    
  end
end

describe "resource(@trip_client_status)" do 
  describe "a successful DELETE", :given => "a trip_client_status exists" do
     before(:each) do
       @response = request(resource(TripClientStatus.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_client_statuses))
     end

   end
end

describe "resource(:trip_client_statuses, :new)" do
  before(:each) do
    @response = request(resource(:trip_client_statuses, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_client_status, :edit)", :given => "a trip_client_status exists" do
  before(:each) do
    @response = request(resource(TripClientStatus.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_client_status)", :given => "a trip_client_status exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripClientStatus.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_client_status = TripClientStatus.first
      @response = request(resource(@trip_client_status), :method => "PUT", 
        :params => { :trip_client_status => {:id => @trip_client_status.id} })
    end
  
    it "redirect to the trip_client_status show action" do
      @response.should redirect_to(resource(@trip_client_status))
    end
  end
  
end

