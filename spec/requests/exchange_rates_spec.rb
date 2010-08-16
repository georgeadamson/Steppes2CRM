require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a exchange_rate exists" do
  exchange_rate.all.destroy!
  request(resource(:exchange_rates), :method => "POST", 
    :params => { :exchange_rate => { :id => nil }})
end

describe "resource(:exchange_rates)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:exchange_rates))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of exchange_rates" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a exchange_rate exists" do
    before(:each) do
      @response = request(resource(:exchange_rates))
    end
    
    it "has a list of exchange_rates" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      exchange_rate.all.destroy!
      @response = request(resource(:exchange_rates), :method => "POST", 
        :params => { :exchange_rate => { :id => nil }})
    end
    
    it "redirects to resource(:exchange_rates)" do
      @response.should redirect_to(resource(exchange_rate.first), :message => {:notice => "exchange_rate was successfully created"})
    end
    
  end
end

describe "resource(@exchange_rate)" do 
  describe "a successful DELETE", :given => "a exchange_rate exists" do
     before(:each) do
       @response = request(resource(exchange_rate.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:exchange_rates))
     end

   end
end

describe "resource(:exchange_rates, :new)" do
  before(:each) do
    @response = request(resource(:exchange_rates, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@exchange_rate, :edit)", :given => "a exchange_rate exists" do
  before(:each) do
    @response = request(resource(exchange_rate.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@exchange_rate)", :given => "a exchange_rate exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(exchange_rate.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @exchange_rate = exchange_rate.first
      @response = request(resource(@exchange_rate), :method => "PUT", 
        :params => { :exchange_rate => {:id => @exchange_rate.id} })
    end
  
    it "redirect to the exchange_rate show action" do
      @response.should redirect_to(resource(@exchange_rate))
    end
  end
  
end

