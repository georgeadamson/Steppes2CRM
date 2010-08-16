require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a document_template_type exists" do
  DocumentTemplateType.all.destroy!
  request(resource(:document_template_types), :method => "POST", 
    :params => { :document_template_type => { :id => nil }})
end

describe "resource(:document_template_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:document_template_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of document_template_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a document_template_type exists" do
    before(:each) do
      @response = request(resource(:document_template_types))
    end
    
    it "has a list of document_template_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      DocumentTemplateType.all.destroy!
      @response = request(resource(:document_template_types), :method => "POST", 
        :params => { :document_template_type => { :id => nil }})
    end
    
    it "redirects to resource(:document_template_types)" do
      @response.should redirect_to(resource(DocumentTemplateType.first), :message => {:notice => "document_template_type was successfully created"})
    end
    
  end
end

describe "resource(@document_template_type)" do 
  describe "a successful DELETE", :given => "a document_template_type exists" do
     before(:each) do
       @response = request(resource(DocumentTemplateType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:document_template_types))
     end

   end
end

describe "resource(:document_template_types, :new)" do
  before(:each) do
    @response = request(resource(:document_template_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_template_type, :edit)", :given => "a document_template_type exists" do
  before(:each) do
    @response = request(resource(DocumentTemplateType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_template_type)", :given => "a document_template_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(DocumentTemplateType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @document_template_type = DocumentTemplateType.first
      @response = request(resource(@document_template_type), :method => "PUT", 
        :params => { :document_template_type => {:id => @document_template_type.id} })
    end
  
    it "redirect to the document_template_type show action" do
      @response.should redirect_to(resource(@document_template_type))
    end
  end
  
end

