require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a money_out exists" do
  MoneyOut.all.destroy!
  request(resource(:money_outs), :method => "POST", 
    :params => { :money_out => { :id => nil }})
end

describe "resource(:money_outs)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:money_outs))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of money_outs" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a money_out exists" do
    before(:each) do
      @response = request(resource(:money_outs))
    end
    
    it "has a list of money_outs" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      MoneyOut.all.destroy!
      @response = request(resource(:money_outs), :method => "POST", 
        :params => { :money_out => { :id => nil }})
    end
    
    it "redirects to resource(:money_outs)" do
      @response.should redirect_to(resource(MoneyOut.first), :message => {:notice => "money_out was successfully created"})
    end
    
  end
end

describe "resource(@money_out)" do 
  describe "a successful DELETE", :given => "a money_out exists" do
     before(:each) do
       @response = request(resource(MoneyOut.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:money_outs))
     end

   end
end

describe "resource(:money_outs, :new)" do
  before(:each) do
    @response = request(resource(:money_outs, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@money_out, :edit)", :given => "a money_out exists" do
  before(:each) do
    @response = request(resource(MoneyOut.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@money_out)", :given => "a money_out exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(MoneyOut.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @money_out = MoneyOut.first
      @response = request(resource(@money_out), :method => "PUT", 
        :params => { :money_out => {:id => @money_out.id} })
    end
  
    it "redirect to the money_out show action" do
      @response.should redirect_to(resource(@money_out))
    end
  end
  
end

