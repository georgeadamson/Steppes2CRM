require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_element_excursion exists" do
  TripElementExcursion.all.destroy!
  request(resource(:trip_element_excursions), :method => "POST", 
    :params => { :trip_element_excursion => { :id => nil }})
end

describe "resource(:trip_element_excursions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_element_excursions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_element_excursions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_element_excursion exists" do
    before(:each) do
      @response = request(resource(:trip_element_excursions))
    end
    
    it "has a list of trip_element_excursions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripElementExcursion.all.destroy!
      @response = request(resource(:trip_element_excursions), :method => "POST", 
        :params => { :trip_element_excursion => { :id => nil }})
    end
    
    it "redirects to resource(:trip_element_excursions)" do
      @response.should redirect_to(resource(TripElementExcursion.first), :message => {:notice => "trip_element_excursion was successfully created"})
    end
    
  end
end

describe "resource(@trip_element_excursion)" do 
  describe "a successful DELETE", :given => "a trip_element_excursion exists" do
     before(:each) do
       @response = request(resource(TripElementExcursion.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_element_excursions))
     end

   end
end

describe "resource(:trip_element_excursions, :new)" do
  before(:each) do
    @response = request(resource(:trip_element_excursions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_element_excursion, :edit)", :given => "a trip_element_excursion exists" do
  before(:each) do
    @response = request(resource(TripElementExcursion.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_element_excursion)", :given => "a trip_element_excursion exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripElementExcursion.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_element_excursion = TripElementExcursion.first
      @response = request(resource(@trip_element_excursion), :method => "PUT", 
        :params => { :trip_element_excursion => {:id => @trip_element_excursion.id} })
    end
  
    it "redirect to the trip_element_excursion show action" do
      @response.should redirect_to(resource(@trip_element_excursion))
    end
  end
  
end

