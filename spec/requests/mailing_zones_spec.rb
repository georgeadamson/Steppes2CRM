require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a mailing_zone exists" do
  MailingZone.all.destroy!
  request(resource(:mailing_zones), :method => "POST", 
    :params => { :mailing_zone => { :id => nil }})
end

describe "resource(:mailing_zones)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:mailing_zones))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of mailing_zones" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a mailing_zone exists" do
    before(:each) do
      @response = request(resource(:mailing_zones))
    end
    
    it "has a list of mailing_zones" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      MailingZone.all.destroy!
      @response = request(resource(:mailing_zones), :method => "POST", 
        :params => { :mailing_zone => { :id => nil }})
    end
    
    it "redirects to resource(:mailing_zones)" do
      @response.should redirect_to(resource(MailingZone.first), :message => {:notice => "mailing_zone was successfully created"})
    end
    
  end
end

describe "resource(@mailing_zone)" do 
  describe "a successful DELETE", :given => "a mailing_zone exists" do
     before(:each) do
       @response = request(resource(MailingZone.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:mailing_zones))
     end

   end
end

describe "resource(:mailing_zones, :new)" do
  before(:each) do
    @response = request(resource(:mailing_zones, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@mailing_zone, :edit)", :given => "a mailing_zone exists" do
  before(:each) do
    @response = request(resource(MailingZone.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@mailing_zone)", :given => "a mailing_zone exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(MailingZone.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @mailing_zone = MailingZone.first
      @response = request(resource(@mailing_zone), :method => "PUT", 
        :params => { :mailing_zone => {:id => @mailing_zone.id} })
    end
  
    it "redirect to the mailing_zone show action" do
      @response.should redirect_to(resource(@mailing_zone))
    end
  end
  
end

