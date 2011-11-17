require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a web_request exists" do
  WebRequest.all.destroy!
  request(resource(:web_requests), :method => "POST", 
    :params => { :web_request => { :id => nil }})
end

describe "resource(:web_requests)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:web_requests))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of web_requests" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a web_request exists" do
    before(:each) do
      @response = request(resource(:web_requests))
    end
    
    it "has a list of web_requests" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      WebRequest.all.destroy!
      @response = request(resource(:web_requests), :method => "POST", 
        :params => { :web_request => { :id => nil }})
    end
    
    it "redirects to resource(:web_requests)" do
      @response.should redirect_to(resource(WebRequest.first), :message => {:notice => "web_request was successfully created"})
    end
    
  end
end

describe "resource(@web_request)" do 
  describe "a successful DELETE", :given => "a web_request exists" do
     before(:each) do
       @response = request(resource(WebRequest.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:web_requests))
     end

   end
end

describe "resource(:web_requests, :new)" do
  before(:each) do
    @response = request(resource(:web_requests, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@web_request, :edit)", :given => "a web_request exists" do
  before(:each) do
    @response = request(resource(WebRequest.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@web_request)", :given => "a web_request exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(WebRequest.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @web_request = WebRequest.first
      @response = request(resource(@web_request), :method => "PUT", 
        :params => { :web_request => {:id => @web_request.id} })
    end
  
    it "redirect to the web_request show action" do
      @response.should redirect_to(resource(@web_request))
    end
  end
  
end

