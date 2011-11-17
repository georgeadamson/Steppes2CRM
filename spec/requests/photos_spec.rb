require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a photo exists" do
  Photo.all.destroy!
  request(resource(:photos), :method => "POST", 
    :params => { :photo => { :id => nil }})
end

describe "resource(:photos)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:photos))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of photos" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a photo exists" do
    before(:each) do
      @response = request(resource(:photos))
    end
    
    it "has a list of photos" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Photo.all.destroy!
      @response = request(resource(:photos), :method => "POST", 
        :params => { :photo => { :id => nil }})
    end
    
    it "redirects to resource(:photos)" do
      @response.should redirect_to(resource(Photo.first), :message => {:notice => "photo was successfully created"})
    end
    
  end
end

describe "resource(@photo)" do 
  describe "a successful DELETE", :given => "a photo exists" do
     before(:each) do
       @response = request(resource(Photo.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:photos))
     end

   end
end

describe "resource(:photos, :new)" do
  before(:each) do
    @response = request(resource(:photos, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@photo, :edit)", :given => "a photo exists" do
  before(:each) do
    @response = request(resource(Photo.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@photo)", :given => "a photo exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Photo.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @photo = Photo.first
      @response = request(resource(@photo), :method => "PUT", 
        :params => { :photo => {:id => @photo.id} })
    end
  
    it "redirect to the photo show action" do
      @response.should redirect_to(resource(@photo))
    end
  end
  
end

