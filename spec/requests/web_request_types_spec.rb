require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a web_request_type exists" do
  WebRequestType.all.destroy!
  request(resource(:web_request_types), :method => "POST", 
    :params => { :web_request_type => { :id => nil }})
end

describe "resource(:web_request_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:web_request_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of web_request_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a web_request_type exists" do
    before(:each) do
      @response = request(resource(:web_request_types))
    end
    
    it "has a list of web_request_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      WebRequestType.all.destroy!
      @response = request(resource(:web_request_types), :method => "POST", 
        :params => { :web_request_type => { :id => nil }})
    end
    
    it "redirects to resource(:web_request_types)" do
      @response.should redirect_to(resource(WebRequestType.first), :message => {:notice => "web_request_type was successfully created"})
    end
    
  end
end

describe "resource(@web_request_type)" do 
  describe "a successful DELETE", :given => "a web_request_type exists" do
     before(:each) do
       @response = request(resource(WebRequestType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:web_request_types))
     end

   end
end

describe "resource(:web_request_types, :new)" do
  before(:each) do
    @response = request(resource(:web_request_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@web_request_type, :edit)", :given => "a web_request_type exists" do
  before(:each) do
    @response = request(resource(WebRequestType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@web_request_type)", :given => "a web_request_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(WebRequestType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @web_request_type = WebRequestType.first
      @response = request(resource(@web_request_type), :method => "PUT", 
        :params => { :web_request_type => {:id => @web_request_type.id} })
    end
  
    it "redirect to the web_request_type show action" do
      @response.should redirect_to(resource(@web_request_type))
    end
  end
  
end

