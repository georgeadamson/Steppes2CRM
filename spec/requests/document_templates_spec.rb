require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a document_template exists" do
  DocumentTemplate.all.destroy!
  request(resource(:document_templates), :method => "POST", 
    :params => { :document_template => { :id => nil }})
end

describe "resource(:document_templates)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:document_templates))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of document_templates" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a document_template exists" do
    before(:each) do
      @response = request(resource(:document_templates))
    end
    
    it "has a list of document_templates" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      DocumentTemplate.all.destroy!
      @response = request(resource(:document_templates), :method => "POST", 
        :params => { :document_template => { :id => nil }})
    end
    
    it "redirects to resource(:document_templates)" do
      @response.should redirect_to(resource(DocumentTemplate.first), :message => {:notice => "document_template was successfully created"})
    end
    
  end
end

describe "resource(@document_template)" do 
  describe "a successful DELETE", :given => "a document_template exists" do
     before(:each) do
       @response = request(resource(DocumentTemplate.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:document_templates))
     end

   end
end

describe "resource(:document_templates, :new)" do
  before(:each) do
    @response = request(resource(:document_templates, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_template, :edit)", :given => "a document_template exists" do
  before(:each) do
    @response = request(resource(DocumentTemplate.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_template)", :given => "a document_template exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(DocumentTemplate.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @document_template = DocumentTemplate.first
      @response = request(resource(@document_template), :method => "PUT", 
        :params => { :document_template => {:id => @document_template.id} })
    end
  
    it "redirect to the document_template show action" do
      @response.should redirect_to(resource(@document_template))
    end
  end
  
end

