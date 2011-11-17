require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a pnr exists" do
  Pnr.all.destroy!
  request(resource(:pnrs), :method => "POST", 
    :params => { :pnr => { :id => nil }})
end

describe "resource(:pnrs)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:pnrs))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of pnrs" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a pnr exists" do
    before(:each) do
      @response = request(resource(:pnrs))
    end
    
    it "has a list of pnrs" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Pnr.all.destroy!
      @response = request(resource(:pnrs), :method => "POST", 
        :params => { :pnr => { :id => nil }})
    end
    
    it "redirects to resource(:pnrs)" do
      @response.should redirect_to(resource(Pnr.first), :message => {:notice => "pnr was successfully created"})
    end
    
  end
end

describe "resource(@pnr)" do 
  describe "a successful DELETE", :given => "a pnr exists" do
     before(:each) do
       @response = request(resource(Pnr.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:pnrs))
     end

   end
end

describe "resource(:pnrs, :new)" do
  before(:each) do
    @response = request(resource(:pnrs, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@pnr, :edit)", :given => "a pnr exists" do
  before(:each) do
    @response = request(resource(Pnr.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@pnr)", :given => "a pnr exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Pnr.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @pnr = Pnr.first
      @response = request(resource(@pnr), :method => "PUT", 
        :params => { :pnr => {:id => @pnr.id} })
    end
  
    it "redirect to the pnr show action" do
      @response.should redirect_to(resource(@pnr))
    end
  end
  
end

