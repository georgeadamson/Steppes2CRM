require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a client_source exists" do
  ClientSource.all.destroy!
  request(resource(:client_sources), :method => "POST", 
    :params => { :client_source => { :id => nil }})
end

describe "resource(:client_sources)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:client_sources))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of client_sources" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a client_source exists" do
    before(:each) do
      @response = request(resource(:client_sources))
    end
    
    it "has a list of client_sources" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ClientSource.all.destroy!
      @response = request(resource(:client_sources), :method => "POST", 
        :params => { :client_source => { :id => nil }})
    end
    
    it "redirects to resource(:client_sources)" do
      @response.should redirect_to(resource(ClientSource.first), :message => {:notice => "client_source was successfully created"})
    end
    
  end
end

describe "resource(@client_source)" do 
  describe "a successful DELETE", :given => "a client_source exists" do
     before(:each) do
       @response = request(resource(ClientSource.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:client_sources))
     end

   end
end

describe "resource(:client_sources, :new)" do
  before(:each) do
    @response = request(resource(:client_sources, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_source, :edit)", :given => "a client_source exists" do
  before(:each) do
    @response = request(resource(ClientSource.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@client_source)", :given => "a client_source exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ClientSource.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @client_source = ClientSource.first
      @response = request(resource(@client_source), :method => "PUT", 
        :params => { :client_source => {:id => @client_source.id} })
    end
  
    it "redirect to the client_source show action" do
      @response.should redirect_to(resource(@client_source))
    end
  end
  
end

