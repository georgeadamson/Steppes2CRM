require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a image_file exists" do
  ImageFile.all.destroy!
  request(resource(:image_files), :method => "POST", 
    :params => { :image_file => { :id => nil }})
end

describe "resource(:image_files)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:image_files))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of image_files" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a image_file exists" do
    before(:each) do
      @response = request(resource(:image_files))
    end
    
    it "has a list of image_files" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      ImageFile.all.destroy!
      @response = request(resource(:image_files), :method => "POST", 
        :params => { :image_file => { :id => nil }})
    end
    
    it "redirects to resource(:image_files)" do
      @response.should redirect_to(resource(ImageFile.first), :message => {:notice => "image_file was successfully created"})
    end
    
  end
end

describe "resource(@image_file)" do 
  describe "a successful DELETE", :given => "a image_file exists" do
     before(:each) do
       @response = request(resource(ImageFile.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:image_files))
     end

   end
end

describe "resource(:image_files, :new)" do
  before(:each) do
    @response = request(resource(:image_files, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@image_file, :edit)", :given => "a image_file exists" do
  before(:each) do
    @response = request(resource(ImageFile.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@image_file)", :given => "a image_file exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(ImageFile.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @image_file = ImageFile.first
      @response = request(resource(@image_file), :method => "PUT", 
        :params => { :image_file => {:id => @image_file.id} })
    end
  
    it "redirect to the image_file show action" do
      @response.should redirect_to(resource(@image_file))
    end
  end
  
end

