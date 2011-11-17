require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a supplier exists" do
  Supplier.all.destroy!
  request(resource(:suppliers), :method => "POST", 
    :params => { :supplier => { :id => nil }})
end

describe "resource(:suppliers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:suppliers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of suppliers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a supplier exists" do
    before(:each) do
      @response = request(resource(:suppliers))
    end
    
    it "has a list of suppliers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Supplier.all.destroy!
      @response = request(resource(:suppliers), :method => "POST", 
        :params => { :supplier => { :id => nil }})
    end
    
    it "redirects to resource(:suppliers)" do
      @response.should redirect_to(resource(Supplier.first), :message => {:notice => "supplier was successfully created"})
    end
    
  end
end

describe "resource(@supplier)" do 
  describe "a successful DELETE", :given => "a supplier exists" do
     before(:each) do
       @response = request(resource(Supplier.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:suppliers))
     end

   end
end

describe "resource(:suppliers, :new)" do
  before(:each) do
    @response = request(resource(:suppliers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@supplier, :edit)", :given => "a supplier exists" do
  before(:each) do
    @response = request(resource(Supplier.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@supplier)", :given => "a supplier exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Supplier.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @supplier = Supplier.first
      @response = request(resource(@supplier), :method => "PUT", 
        :params => { :supplier => {:id => @supplier.id} })
    end
  
    it "redirect to the supplier show action" do
      @response.should redirect_to(resource(@supplier))
    end
  end
  
end

