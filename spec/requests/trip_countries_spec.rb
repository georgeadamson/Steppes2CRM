require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_country exists" do
  TripCountry.all.destroy!
  request(resource(:trip_countries), :method => "POST", 
    :params => { :trip_country => { :id => nil }})
end

describe "resource(:trip_countries)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_countries))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_countries" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_country exists" do
    before(:each) do
      @response = request(resource(:trip_countries))
    end
    
    it "has a list of trip_countries" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripCountry.all.destroy!
      @response = request(resource(:trip_countries), :method => "POST", 
        :params => { :trip_country => { :id => nil }})
    end
    
    it "redirects to resource(:trip_countries)" do
      @response.should redirect_to(resource(TripCountry.first), :message => {:notice => "trip_country was successfully created"})
    end
    
  end
end

describe "resource(@trip_country)" do 
  describe "a successful DELETE", :given => "a trip_country exists" do
     before(:each) do
       @response = request(resource(TripCountry.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_countries))
     end

   end
end

describe "resource(:trip_countries, :new)" do
  before(:each) do
    @response = request(resource(:trip_countries, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_country, :edit)", :given => "a trip_country exists" do
  before(:each) do
    @response = request(resource(TripCountry.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_country)", :given => "a trip_country exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripCountry.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_country = TripCountry.first
      @response = request(resource(@trip_country), :method => "PUT", 
        :params => { :trip_country => {:id => @trip_country.id} })
    end
  
    it "redirect to the trip_country show action" do
      @response.should redirect_to(resource(@trip_country))
    end
  end
  
end

