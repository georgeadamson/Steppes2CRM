require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a web_request_status exists" do
  WebRequestStatus.all.destroy!
  request(resource(:web_request_statuses), :method => "POST", 
    :params => { :web_request_status => { :id => nil }})
end

describe "resource(:web_request_statuses)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:web_request_statuses))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of web_request_statuses" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a web_request_status exists" do
    before(:each) do
      @response = request(resource(:web_request_statuses))
    end
    
    it "has a list of web_request_statuses" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      WebRequestStatus.all.destroy!
      @response = request(resource(:web_request_statuses), :method => "POST", 
        :params => { :web_request_status => { :id => nil }})
    end
    
    it "redirects to resource(:web_request_statuses)" do
      @response.should redirect_to(resource(WebRequestStatus.first), :message => {:notice => "web_request_status was successfully created"})
    end
    
  end
end

describe "resource(@web_request_status)" do 
  describe "a successful DELETE", :given => "a web_request_status exists" do
     before(:each) do
       @response = request(resource(WebRequestStatus.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:web_request_statuses))
     end

   end
end

describe "resource(:web_request_statuses, :new)" do
  before(:each) do
    @response = request(resource(:web_request_statuses, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@web_request_status, :edit)", :given => "a web_request_status exists" do
  before(:each) do
    @response = request(resource(WebRequestStatus.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@web_request_status)", :given => "a web_request_status exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(WebRequestStatus.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @web_request_status = WebRequestStatus.first
      @response = request(resource(@web_request_status), :method => "PUT", 
        :params => { :web_request_status => {:id => @web_request_status.id} })
    end
  
    it "redirect to the web_request_status show action" do
      @response.should redirect_to(resource(@web_request_status))
    end
  end
  
end

