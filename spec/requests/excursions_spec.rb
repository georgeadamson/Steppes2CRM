require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a excursion exists" do
  Excursion.all.destroy!
  request(resource(:excursions), :method => "POST", 
    :params => { :excursion => { :id => nil }})
end

describe "resource(:excursions)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:excursions))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of excursions" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a excursion exists" do
    before(:each) do
      @response = request(resource(:excursions))
    end
    
    it "has a list of excursions" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Excursion.all.destroy!
      @response = request(resource(:excursions), :method => "POST", 
        :params => { :excursion => { :id => nil }})
    end
    
    it "redirects to resource(:excursions)" do
      @response.should redirect_to(resource(Excursion.first), :message => {:notice => "excursion was successfully created"})
    end
    
  end
end

describe "resource(@excursion)" do 
  describe "a successful DELETE", :given => "a excursion exists" do
     before(:each) do
       @response = request(resource(Excursion.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:excursions))
     end

   end
end

describe "resource(:excursions, :new)" do
  before(:each) do
    @response = request(resource(:excursions, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@excursion, :edit)", :given => "a excursion exists" do
  before(:each) do
    @response = request(resource(Excursion.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@excursion)", :given => "a excursion exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Excursion.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @excursion = Excursion.first
      @response = request(resource(@excursion), :method => "PUT", 
        :params => { :excursion => {:id => @excursion.id} })
    end
  
    it "redirect to the excursion show action" do
      @response.should redirect_to(resource(@excursion))
    end
  end
  
end

