require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a company_supplier exists" do
  CompanySupplier.all.destroy!
  request(resource(:company_suppliers), :method => "POST", 
    :params => { :company_supplier => { :id => nil }})
end

describe "resource(:company_suppliers)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:company_suppliers))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of company_suppliers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a company_supplier exists" do
    before(:each) do
      @response = request(resource(:company_suppliers))
    end
    
    it "has a list of company_suppliers" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      CompanySupplier.all.destroy!
      @response = request(resource(:company_suppliers), :method => "POST", 
        :params => { :company_supplier => { :id => nil }})
    end
    
    it "redirects to resource(:company_suppliers)" do
      @response.should redirect_to(resource(CompanySupplier.first), :message => {:notice => "company_supplier was successfully created"})
    end
    
  end
end

describe "resource(@company_supplier)" do 
  describe "a successful DELETE", :given => "a company_supplier exists" do
     before(:each) do
       @response = request(resource(CompanySupplier.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:company_suppliers))
     end

   end
end

describe "resource(:company_suppliers, :new)" do
  before(:each) do
    @response = request(resource(:company_suppliers, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@company_supplier, :edit)", :given => "a company_supplier exists" do
  before(:each) do
    @response = request(resource(CompanySupplier.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@company_supplier)", :given => "a company_supplier exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(CompanySupplier.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @company_supplier = CompanySupplier.first
      @response = request(resource(@company_supplier), :method => "PUT", 
        :params => { :company_supplier => {:id => @company_supplier.id} })
    end
  
    it "redirect to the company_supplier show action" do
      @response.should redirect_to(resource(@company_supplier))
    end
  end
  
end

