require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a airport exists" do
  Airport.all.destroy!
  request(resource(:airports), :method => "POST", 
    :params => { :airport => { :id => nil }})
end

describe "resource(:airports)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:airports))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of airports" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a airport exists" do
    before(:each) do
      @response = request(resource(:airports))
    end
    
    it "has a list of airports" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Airport.all.destroy!
      @response = request(resource(:airports), :method => "POST", 
        :params => { :airport => { :id => nil }})
    end
    
    it "redirects to resource(:airports)" do
      @response.should redirect_to(resource(Airport.first), :message => {:notice => "airport was successfully created"})
    end
    
  end
end

describe "resource(@airport)" do 
  describe "a successful DELETE", :given => "a airport exists" do
     before(:each) do
       @response = request(resource(Airport.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:airports))
     end

   end
end

describe "resource(:airports, :new)" do
  before(:each) do
    @response = request(resource(:airports, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@airport, :edit)", :given => "a airport exists" do
  before(:each) do
    @response = request(resource(Airport.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@airport)", :given => "a airport exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Airport.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @airport = Airport.first
      @response = request(resource(@airport), :method => "PUT", 
        :params => { :airport => {:id => @airport.id} })
    end
  
    it "redirect to the airport show action" do
      @response.should redirect_to(resource(@airport))
    end
  end
  
end

