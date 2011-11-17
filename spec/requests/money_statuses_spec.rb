require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a money_status exists" do
  MoneyStatus.all.destroy!
  request(resource(:money_statuses), :method => "POST", 
    :params => { :money_status => { :id => nil }})
end

describe "resource(:money_statuses)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:money_statuses))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of money_statuses" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a money_status exists" do
    before(:each) do
      @response = request(resource(:money_statuses))
    end
    
    it "has a list of money_statuses" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      MoneyStatus.all.destroy!
      @response = request(resource(:money_statuses), :method => "POST", 
        :params => { :money_status => { :id => nil }})
    end
    
    it "redirects to resource(:money_statuses)" do
      @response.should redirect_to(resource(MoneyStatus.first), :message => {:notice => "money_status was successfully created"})
    end
    
  end
end

describe "resource(@money_status)" do 
  describe "a successful DELETE", :given => "a money_status exists" do
     before(:each) do
       @response = request(resource(MoneyStatus.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:money_statuses))
     end

   end
end

describe "resource(:money_statuses, :new)" do
  before(:each) do
    @response = request(resource(:money_statuses, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@money_status, :edit)", :given => "a money_status exists" do
  before(:each) do
    @response = request(resource(MoneyStatus.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@money_status)", :given => "a money_status exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(MoneyStatus.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @money_status = MoneyStatus.first
      @response = request(resource(@money_status), :method => "PUT", 
        :params => { :money_status => {:id => @money_status.id} })
    end
  
    it "redirect to the money_status show action" do
      @response.should redirect_to(resource(@money_status))
    end
  end
  
end

