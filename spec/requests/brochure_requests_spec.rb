require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a brochure_request exists" do
  BrochureRequest.all.destroy!
  request(resource(:brochure_requests), :method => "POST", 
    :params => { :brochure_request => { :id => nil }})
end

describe "resource(:brochure_requests)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:brochure_requests))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of brochure_requests" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a brochure_request exists" do
    before(:each) do
      @response = request(resource(:brochure_requests))
    end
    
    it "has a list of brochure_requests" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      BrochureRequest.all.destroy!
      @response = request(resource(:brochure_requests), :method => "POST", 
        :params => { :brochure_request => { :id => nil }})
    end
    
    it "redirects to resource(:brochure_requests)" do
      @response.should redirect_to(resource(BrochureRequest.first), :message => {:notice => "brochure_request was successfully created"})
    end
    
  end
end

describe "resource(@brochure_request)" do 
  describe "a successful DELETE", :given => "a brochure_request exists" do
     before(:each) do
       @response = request(resource(BrochureRequest.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:brochure_requests))
     end

   end
end

describe "resource(:brochure_requests, :new)" do
  before(:each) do
    @response = request(resource(:brochure_requests, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@brochure_request, :edit)", :given => "a brochure_request exists" do
  before(:each) do
    @response = request(resource(BrochureRequest.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@brochure_request)", :given => "a brochure_request exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(BrochureRequest.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @brochure_request = BrochureRequest.first
      @response = request(resource(@brochure_request), :method => "PUT", 
        :params => { :brochure_request => {:id => @brochure_request.id} })
    end
  
    it "redirect to the brochure_request show action" do
      @response.should redirect_to(resource(@brochure_request))
    end
  end
  
end

