require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a country_user exists" do
  CountryUser.all.destroy!
  request(resource(:country_users), :method => "POST", 
    :params => { :country_user => { :id => nil }})
end

describe "resource(:country_users)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:country_users))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of country_users" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a country_user exists" do
    before(:each) do
      @response = request(resource(:country_users))
    end
    
    it "has a list of country_users" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      CountryUser.all.destroy!
      @response = request(resource(:country_users), :method => "POST", 
        :params => { :country_user => { :id => nil }})
    end
    
    it "redirects to resource(:country_users)" do
      @response.should redirect_to(resource(CountryUser.first), :message => {:notice => "country_user was successfully created"})
    end
    
  end
end

describe "resource(@country_user)" do 
  describe "a successful DELETE", :given => "a country_user exists" do
     before(:each) do
       @response = request(resource(CountryUser.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:country_users))
     end

   end
end

describe "resource(:country_users, :new)" do
  before(:each) do
    @response = request(resource(:country_users, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@country_user, :edit)", :given => "a country_user exists" do
  before(:each) do
    @response = request(resource(CountryUser.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@country_user)", :given => "a country_user exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(CountryUser.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @country_user = CountryUser.first
      @response = request(resource(@country_user), :method => "PUT", 
        :params => { :country_user => {:id => @country_user.id} })
    end
  
    it "redirect to the country_user show action" do
      @response.should redirect_to(resource(@country_user))
    end
  end
  
end

