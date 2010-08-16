require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a trip_package exists" do
  TripPackage.all.destroy!
  request(resource(:trip_packages), :method => "POST", 
    :params => { :trip_package => { :id => nil }})
end

describe "resource(:trip_packages)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:trip_packages))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of trip_packages" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a trip_package exists" do
    before(:each) do
      @response = request(resource(:trip_packages))
    end
    
    it "has a list of trip_packages" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TripPackage.all.destroy!
      @response = request(resource(:trip_packages), :method => "POST", 
        :params => { :trip_package => { :id => nil }})
    end
    
    it "redirects to resource(:trip_packages)" do
      @response.should redirect_to(resource(TripPackage.first), :message => {:notice => "trip_package was successfully created"})
    end
    
  end
end

describe "resource(@trip_package)" do 
  describe "a successful DELETE", :given => "a trip_package exists" do
     before(:each) do
       @response = request(resource(TripPackage.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:trip_packages))
     end

   end
end

describe "resource(:trip_packages, :new)" do
  before(:each) do
    @response = request(resource(:trip_packages, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_package, :edit)", :given => "a trip_package exists" do
  before(:each) do
    @response = request(resource(TripPackage.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@trip_package)", :given => "a trip_package exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TripPackage.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @trip_package = TripPackage.first
      @response = request(resource(@trip_package), :method => "PUT", 
        :params => { :trip_package => {:id => @trip_package.id} })
    end
  
    it "redirect to the trip_package show action" do
      @response.should redirect_to(resource(@trip_package))
    end
  end
  
end

