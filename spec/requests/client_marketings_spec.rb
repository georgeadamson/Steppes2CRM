require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a client_marketing exists" do
  ClientMarketing.all.destroy!
  request(resource(:client_marketings), :method => "POST", 
    :params => { :client_marketing => { :id => nil }})
end

describe "resource(:client_marketings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:client_marketings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of client_marketings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a client_marketing exists" do
    before(:each) do
      @response = request(resource(:client_marketings))
    end
    
    it "has a list of client_marketings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ClientMarketing.all.destroy!
      @response = request(resource(:client_marketings), :method => "POST", 
        :params => { :client_marketing => { :id => nil }})
    end
    
    it "redirects to resource(:client_marketings)" do
      @response.should redirect_to(resource(ClientMarketing.first), :message => {:notice => "client_marketing was successfully created"})
    end
    
  end
end

describe "resource(@client_marketing)" do 
  describe "a successful DELETE", :given => "a client_marketing exists" do
     before(:each) do
       @response = request(resource(ClientMarketing.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:client_marketings))
     end

   end
end

describe "resource(:client_marketings, :new)" do
  before(:each) do
    @response = request(resource(:client_marketings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_marketing, :edit)", :given => "a client_marketing exists" do
  before(:each) do
    @response = request(resource(ClientMarketing.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_marketing)", :given => "a client_marketing exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ClientMarketing.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @client_marketing = ClientMarketing.first
      @response = request(resource(@client_marketing), :method => "PUT", 
        :params => { :client_marketing => {:id => @client_marketing.id} })
    end
  
    it "redirect to the client_marketing show action" do
      @response.should redirect_to(resource(@client_marketing))
    end
  end
  
end

