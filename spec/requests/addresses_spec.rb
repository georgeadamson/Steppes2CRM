require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a address exists" do
  Address.all.destroy!
  request(resource(:addresses), :method => "POST", 
    :params => { :address => { :id => nil }})
end

describe "resource(:addresses)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:addresses))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of addresses" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a address exists" do
    before(:each) do
      @response = request(resource(:addresses))
    end
    
    it "has a list of addresses" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Address.all.destroy!
      @response = request(resource(:addresses), :method => "POST", 
        :params => { :address => { :id => nil }})
    end
    
    it "redirects to resource(:addresses)" do
      @response.should redirect_to(resource(Address.first), :message => {:notice => "address was successfully created"})
    end
    
  end
end

describe "resource(@address)" do 
  describe "a successful DELETE", :given => "a address exists" do
     before(:each) do
       @response = request(resource(Address.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:addresses))
     end

   end
end

describe "resource(:addresses, :new)" do
  before(:each) do
    @response = request(resource(:addresses, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@address, :edit)", :given => "a address exists" do
  before(:each) do
    @response = request(resource(Address.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@address)", :given => "a address exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Address.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @address = Address.first
      @response = request(resource(@address), :method => "PUT", 
        :params => { :address => {:id => @address.id} })
    end
  
    it "redirect to the address show action" do
      @response.should redirect_to(resource(@address))
    end
  end
  
end

