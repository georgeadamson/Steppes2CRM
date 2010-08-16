require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a world_region exists" do
  WorldRegion.all.destroy!
  request(resource(:world_regions), :method => "POST", 
    :params => { :world_region => { :id => nil }})
end

describe "resource(:world_regions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:world_regions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of world_regions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a world_region exists" do
    before(:each) do
      @response = request(resource(:world_regions))
    end
    
    it "has a list of world_regions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      WorldRegion.all.destroy!
      @response = request(resource(:world_regions), :method => "POST", 
        :params => { :world_region => { :id => nil }})
    end
    
    it "redirects to resource(:world_regions)" do
      @response.should redirect_to(resource(WorldRegion.first), :message => {:notice => "world_region was successfully created"})
    end
    
  end
end

describe "resource(@worldRegion)" do 
  describe "a successful DELETE", :given => "a world_region exists" do
     before(:each) do
       @response = request(resource(WorldRegion.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:world_regions))
     end

   end
end

describe "resource(:world_regions, :new)" do
  before(:each) do
    @response = request(resource(:world_regions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@worldRegion, :edit)", :given => "a world_region exists" do
  before(:each) do
    @response = request(resource(WorldRegion.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@worldRegion)", :given => "a world_region exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(WorldRegion.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @worldRegion = WorldRegion.first
      @response = request(resource(@worldRegion), :method => "PUT", 
        :params => { :world_region => {:id => @worldRegion.id} })
    end
  
    it "redirect to the world_region show action" do
      @response.should redirect_to(resource(@worldRegion))
    end
  end
  
end

