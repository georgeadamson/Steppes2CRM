require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a app_setting exists" do
  AppSetting.all.destroy!
  request(resource(:app_settings), :method => "POST", 
    :params => { :app_setting => { :id => nil }})
end

describe "resource(:app_settings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:app_settings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of app_settings" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a app_setting exists" do
    before(:each) do
      @response = request(resource(:app_settings))
    end
    
    it "has a list of app_settings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      AppSetting.all.destroy!
      @response = request(resource(:app_settings), :method => "POST", 
        :params => { :app_setting => { :id => nil }})
    end
    
    it "redirects to resource(:app_settings)" do
      @response.should redirect_to(resource(AppSetting.first), :message => {:notice => "app_setting was successfully created"})
    end
    
  end
end

describe "resource(@app_setting)" do 
  describe "a successful DELETE", :given => "a app_setting exists" do
     before(:each) do
       @response = request(resource(AppSetting.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:app_settings))
     end

   end
end

describe "resource(:app_settings, :new)" do
  before(:each) do
    @response = request(resource(:app_settings, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@app_setting, :edit)", :given => "a app_setting exists" do
  before(:each) do
    @response = request(resource(AppSetting.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@app_setting)", :given => "a app_setting exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(AppSetting.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @app_setting = AppSetting.first
      @response = request(resource(@app_setting), :method => "PUT", 
        :params => { :app_setting => {:id => @app_setting.id} })
    end
  
    it "redirect to the app_setting show action" do
      @response.should redirect_to(resource(@app_setting))
    end
  end
  
end

