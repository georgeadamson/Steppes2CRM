require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a division exists" do
  Division.all.destroy!
  request(resource(:divisions), :method => "POST", 
    :params => { :division => { :id => nil }})
end

describe "resource(:divisions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:divisions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of divisions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a division exists" do
    before(:each) do
      @response = request(resource(:divisions))
    end
    
    it "has a list of divisions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Division.all.destroy!
      @response = request(resource(:divisions), :method => "POST", 
        :params => { :division => { :id => nil }})
    end
    
    it "redirects to resource(:divisions)" do
      @response.should redirect_to(resource(Division.first), :message => {:notice => "division was successfully created"})
    end
    
  end
end

describe "resource(@division)" do 
  describe "a successful DELETE", :given => "a division exists" do
     before(:each) do
       @response = request(resource(Division.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:divisions))
     end

   end
end

describe "resource(:divisions, :new)" do
  before(:each) do
    @response = request(resource(:divisions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@division, :edit)", :given => "a division exists" do
  before(:each) do
    @response = request(resource(Division.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@division)", :given => "a division exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Division.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @division = Division.first
      @response = request(resource(@division), :method => "PUT", 
        :params => { :division => {:id => @division.id} })
    end
  
    it "redirect to the division show action" do
      @response.should redirect_to(resource(@division))
    end
  end
  
end

