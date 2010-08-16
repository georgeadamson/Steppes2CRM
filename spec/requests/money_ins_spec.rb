require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a money_in exists" do
  MoneyIn.all.destroy!
  request(resource(:money_ins), :method => "POST", 
    :params => { :money_in => { :id => nil }})
end

describe "resource(:money_ins)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:money_ins))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of money_ins" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a money_in exists" do
    before(:each) do
      @response = request(resource(:money_ins))
    end
    
    it "has a list of money_ins" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      MoneyIn.all.destroy!
      @response = request(resource(:money_ins), :method => "POST", 
        :params => { :money_in => { :id => nil }})
    end
    
    it "redirects to resource(:money_ins)" do
      @response.should redirect_to(resource(MoneyIn.first), :message => {:notice => "money_in was successfully created"})
    end
    
  end
end

describe "resource(@money_in)" do 
  describe "a successful DELETE", :given => "a money_in exists" do
     before(:each) do
       @response = request(resource(MoneyIn.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:money_ins))
     end

   end
end

describe "resource(:money_ins, :new)" do
  before(:each) do
    @response = request(resource(:money_ins, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@money_in, :edit)", :given => "a money_in exists" do
  before(:each) do
    @response = request(resource(MoneyIn.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@money_in)", :given => "a money_in exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(MoneyIn.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @money_in = MoneyIn.first
      @response = request(resource(@money_in), :method => "PUT", 
        :params => { :money_in => {:id => @money_in.id} })
    end
  
    it "redirect to the money_in show action" do
      @response.should redirect_to(resource(@money_in))
    end
  end
  
end

