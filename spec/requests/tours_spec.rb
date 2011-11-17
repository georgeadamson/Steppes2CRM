require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a tour exists" do
  Tour.all.destroy!
  request(resource(:tours), :method => "POST", 
    :params => { :tour => { :id => nil }})
end

describe "resource(:tours)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:tours))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of tours" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a tour exists" do
    before(:each) do
      @response = request(resource(:tours))
    end
    
    it "has a list of tours" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Tour.all.destroy!
      @response = request(resource(:tours), :method => "POST", 
        :params => { :tour => { :id => nil }})
    end
    
    it "redirects to resource(:tours)" do
      @response.should redirect_to(resource(Tour.first), :message => {:notice => "tour was successfully created"})
    end
    
  end
end

describe "resource(@tour)" do 
  describe "a successful DELETE", :given => "a tour exists" do
     before(:each) do
       @response = request(resource(Tour.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:tours))
     end

   end
end

describe "resource(:tours, :new)" do
  before(:each) do
    @response = request(resource(:tours, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@tour, :edit)", :given => "a tour exists" do
  before(:each) do
    @response = request(resource(Tour.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@tour)", :given => "a tour exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Tour.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @tour = Tour.first
      @response = request(resource(@tour), :method => "PUT", 
        :params => { :tour => {:id => @tour.id} })
    end
  
    it "redirect to the tour show action" do
      @response.should redirect_to(resource(@tour))
    end
  end
  
end

