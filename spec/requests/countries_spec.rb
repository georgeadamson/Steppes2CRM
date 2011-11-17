require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a country exists" do
  Country.all.destroy!
  request(resource(:countries), :method => "POST", 
    :params => { :country => { :id => nil }})
end

describe "resource(:countries)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:countries))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of countries" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a country exists" do
    before(:each) do
      @response = request(resource(:countries))
    end
    
    it "has a list of countries" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Country.all.destroy!
      @response = request(resource(:countries), :method => "POST", 
        :params => { :country => { :id => nil }})
    end
    
    it "redirects to resource(:countries)" do
      @response.should redirect_to(resource(Country.first), :message => {:notice => "country was successfully created"})
    end
    
  end
end

describe "resource(@country)" do 
  describe "a successful DELETE", :given => "a country exists" do
     before(:each) do
       @response = request(resource(Country.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:countries))
     end

   end
end

describe "resource(:countries, :new)" do
  before(:each) do
    @response = request(resource(:countries, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@country, :edit)", :given => "a country exists" do
  before(:each) do
    @response = request(resource(Country.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@country)", :given => "a country exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Country.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @country = Country.first
      @response = request(resource(@country), :method => "PUT", 
        :params => { :country => {:id => @country.id} })
    end
  
    it "redirect to the country show action" do
      @response.should redirect_to(resource(@country))
    end
  end
  
end

