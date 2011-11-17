require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a postcode exists" do
  Postcode.all.destroy!
  request(resource(:postcodes), :method => "POST", 
    :params => { :postcode => { :id => nil }})
end

describe "resource(:postcodes)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:postcodes))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of postcodes" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a postcode exists" do
    before(:each) do
      @response = request(resource(:postcodes))
    end
    
    it "has a list of postcodes" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Postcode.all.destroy!
      @response = request(resource(:postcodes), :method => "POST", 
        :params => { :postcode => { :id => nil }})
    end
    
    it "redirects to resource(:postcodes)" do
      @response.should redirect_to(resource(Postcode.first), :message => {:notice => "postcode was successfully created"})
    end
    
  end
end

describe "resource(@postcode)" do 
  describe "a successful DELETE", :given => "a postcode exists" do
     before(:each) do
       @response = request(resource(Postcode.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:postcodes))
     end

   end
end

describe "resource(:postcodes, :new)" do
  before(:each) do
    @response = request(resource(:postcodes, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@postcode, :edit)", :given => "a postcode exists" do
  before(:each) do
    @response = request(resource(Postcode.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@postcode)", :given => "a postcode exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Postcode.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @postcode = Postcode.first
      @response = request(resource(@postcode), :method => "PUT", 
        :params => { :postcode => {:id => @postcode.id} })
    end
  
    it "redirect to the postcode show action" do
      @response.should redirect_to(resource(@postcode))
    end
  end
  
end

