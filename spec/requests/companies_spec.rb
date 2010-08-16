require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a company exists" do
  Company.all.destroy!
  request(resource(:companies), :method => "POST", 
    :params => { :company => { :id => nil }})
end

describe "resource(:companies)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:companies))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of companies" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a company exists" do
    before(:each) do
      @response = request(resource(:companies))
    end
    
    it "has a list of companies" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Company.all.destroy!
      @response = request(resource(:companies), :method => "POST", 
        :params => { :company => { :id => nil }})
    end
    
    it "redirects to resource(:companies)" do
      @response.should redirect_to(resource(Company.first), :message => {:notice => "company was successfully created"})
    end
    
  end
end

describe "resource(@company)" do 
  describe "a successful DELETE", :given => "a company exists" do
     before(:each) do
       @response = request(resource(Company.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:companies))
     end

   end
end

describe "resource(:companies, :new)" do
  before(:each) do
    @response = request(resource(:companies, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@company, :edit)", :given => "a company exists" do
  before(:each) do
    @response = request(resource(Company.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@company)", :given => "a company exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Company.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @company = Company.first
      @response = request(resource(@company), :method => "PUT", 
        :params => { :company => {:id => @company.id} })
    end
  
    it "redirect to the company show action" do
      @response.should redirect_to(resource(@company))
    end
  end
  
end

