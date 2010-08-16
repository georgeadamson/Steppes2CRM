require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a document_job exists" do
  DocumentJob.all.destroy!
  request(resource(:document_jobs), :method => "POST", 
    :params => { :document_job => { :id => nil }})
end

describe "resource(:document_jobs)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:document_jobs))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of document_jobs" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a document_job exists" do
    before(:each) do
      @response = request(resource(:document_jobs))
    end
    
    it "has a list of document_jobs" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      DocumentJob.all.destroy!
      @response = request(resource(:document_jobs), :method => "POST", 
        :params => { :document_job => { :id => nil }})
    end
    
    it "redirects to resource(:document_jobs)" do
      @response.should redirect_to(resource(DocumentJob.first), :message => {:notice => "document_job was successfully created"})
    end
    
  end
end

describe "resource(@document_job)" do 
  describe "a successful DELETE", :given => "a document_job exists" do
     before(:each) do
       @response = request(resource(DocumentJob.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:document_jobs))
     end

   end
end

describe "resource(:document_jobs, :new)" do
  before(:each) do
    @response = request(resource(:document_jobs, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_job, :edit)", :given => "a document_job exists" do
  before(:each) do
    @response = request(resource(DocumentJob.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@document_job)", :given => "a document_job exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(DocumentJob.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @document_job = DocumentJob.first
      @response = request(resource(@document_job), :method => "PUT", 
        :params => { :document_job => {:id => @document_job.id} })
    end
  
    it "redirect to the document_job show action" do
      @response.should redirect_to(resource(@document_job))
    end
  end
  
end

