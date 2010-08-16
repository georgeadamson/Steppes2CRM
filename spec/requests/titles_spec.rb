require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a title exists" do
  Title.all.destroy!
  request(resource(:titles), :method => "POST", 
    :params => { :title => { :id => nil }})
end

describe "resource(:titles)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:titles))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of titles" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a title exists" do
    before(:each) do
      @response = request(resource(:titles))
    end
    
    it "has a list of titles" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Title.all.destroy!
      @response = request(resource(:titles), :method => "POST", 
        :params => { :title => { :id => nil }})
    end
    
    it "redirects to resource(:titles)" do
      @response.should redirect_to(resource(Title.first), :message => {:notice => "title was successfully created"})
    end
    
  end
end

describe "resource(@title)" do 
  describe "a successful DELETE", :given => "a title exists" do
     before(:each) do
       @response = request(resource(Title.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:titles))
     end

   end
end

describe "resource(:titles, :new)" do
  before(:each) do
    @response = request(resource(:titles, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@title, :edit)", :given => "a title exists" do
  before(:each) do
    @response = request(resource(Title.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@title)", :given => "a title exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Title.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @title = Title.first
      @response = request(resource(@title), :method => "PUT", 
        :params => { :title => {:id => @title.id} })
    end
  
    it "redirect to the title show action" do
      @response.should redirect_to(resource(@title))
    end
  end
  
end

