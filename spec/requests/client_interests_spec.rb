require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a client_interest exists" do
  ClientInterest.all.destroy!
  request(resource(:client_interests), :method => "POST", 
    :params => { :client_interest => { :id => nil }})
end

describe "resource(:client_interests)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:client_interests))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of client_interests" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a client_interest exists" do
    before(:each) do
      @response = request(resource(:client_interests))
    end
    
    it "has a list of client_interests" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ClientInterest.all.destroy!
      @response = request(resource(:client_interests), :method => "POST", 
        :params => { :client_interest => { :id => nil }})
    end
    
    it "redirects to resource(:client_interests)" do
      @response.should redirect_to(resource(ClientInterest.first), :message => {:notice => "client_interest was successfully created"})
    end
    
  end
end

describe "resource(@client_interest)" do 
  describe "a successful DELETE", :given => "a client_interest exists" do
     before(:each) do
       @response = request(resource(ClientInterest.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:client_interests))
     end

   end
end

describe "resource(:client_interests, :new)" do
  before(:each) do
    @response = request(resource(:client_interests, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_interest, :edit)", :given => "a client_interest exists" do
  before(:each) do
    @response = request(resource(ClientInterest.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_interest)", :given => "a client_interest exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ClientInterest.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @client_interest = ClientInterest.first
      @response = request(resource(@client_interest), :method => "PUT", 
        :params => { :client_interest => {:id => @client_interest.id} })
    end
  
    it "redirect to the client_interest show action" do
      @response.should redirect_to(resource(@client_interest))
    end
  end
  
end

