require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a company_country exists" do
  CompanyCountry.all.destroy!
  request(resource(:company_countries), :method => "POST", 
    :params => { :company_country => { :id => nil }})
end

describe "resource(:company_countries)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:company_countries))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of company_countries" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a company_country exists" do
    before(:each) do
      @response = request(resource(:company_countries))
    end
    
    it "has a list of company_countries" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      CompanyCountry.all.destroy!
      @response = request(resource(:company_countries), :method => "POST", 
        :params => { :company_country => { :id => nil }})
    end
    
    it "redirects to resource(:company_countries)" do
      @response.should redirect_to(resource(CompanyCountry.first), :message => {:notice => "company_country was successfully created"})
    end
    
  end
end

describe "resource(@company_country)" do 
  describe "a successful DELETE", :given => "a company_country exists" do
     before(:each) do
       @response = request(resource(CompanyCountry.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:company_countries))
     end

   end
end

describe "resource(:company_countries, :new)" do
  before(:each) do
    @response = request(resource(:company_countries, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@company_country, :edit)", :given => "a company_country exists" do
  before(:each) do
    @response = request(resource(CompanyCountry.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@company_country)", :given => "a company_country exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(CompanyCountry.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @company_country = CompanyCountry.first
      @response = request(resource(@company_country), :method => "PUT", 
        :params => { :company_country => {:id => @company_country.id} })
    end
  
    it "redirect to the company_country show action" do
      @response.should redirect_to(resource(@company_country))
    end
  end
  
end

