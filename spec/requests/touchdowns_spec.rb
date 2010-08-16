require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a touchdown exists" do
  Touchdown.all.destroy!
  request(resource(:touchdowns), :method => "POST", 
    :params => { :touchdown => { :id => nil }})
end

describe "resource(:touchdowns)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:touchdowns))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of touchdowns" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a touchdown exists" do
    before(:each) do
      @response = request(resource(:touchdowns))
    end
    
    it "has a list of touchdowns" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Touchdown.all.destroy!
      @response = request(resource(:touchdowns), :method => "POST", 
        :params => { :touchdown => { :id => nil }})
    end
    
    it "redirects to resource(:touchdowns)" do
      @response.should redirect_to(resource(Touchdown.first), :message => {:notice => "touchdown was successfully created"})
    end
    
  end
end

describe "resource(@touchdown)" do 
  describe "a successful DELETE", :given => "a touchdown exists" do
     before(:each) do
       @response = request(resource(Touchdown.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:touchdowns))
     end

   end
end

describe "resource(:touchdowns, :new)" do
  before(:each) do
    @response = request(resource(:touchdowns, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@touchdown, :edit)", :given => "a touchdown exists" do
  before(:each) do
    @response = request(resource(Touchdown.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@touchdown)", :given => "a touchdown exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Touchdown.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @touchdown = Touchdown.first
      @response = request(resource(@touchdown), :method => "PUT", 
        :params => { :touchdown => {:id => @touchdown.id} })
    end
  
    it "redirect to the touchdown show action" do
      @response.should redirect_to(resource(@touchdown))
    end
  end
  
end

