require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a task exists" do
  Task.all.destroy!
  request(resource(:tasks), :method => "POST", 
    :params => { :task => { :id => nil }})
end

describe "resource(:tasks)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:tasks))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of tasks" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a task exists" do
    before(:each) do
      @response = request(resource(:tasks))
    end
    
    it "has a list of tasks" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      Task.all.destroy!
      @response = request(resource(:tasks), :method => "POST", 
        :params => { :task => { :id => nil }})
    end
    
    it "redirects to resource(:tasks)" do
      @response.should redirect_to(resource(Task.first), :message => {:notice => "task was successfully created"})
    end
    
  end
end

describe "resource(@task)" do 
  describe "a successful DELETE", :given => "a task exists" do
     before(:each) do
       @response = request(resource(Task.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:tasks))
     end

   end
end

describe "resource(:tasks, :new)" do
  before(:each) do
    @response = request(resource(:tasks, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@task, :edit)", :given => "a task exists" do
  before(:each) do
    @response = request(resource(Task.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@task)", :given => "a task exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(Task.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @task = Task.first
      @response = request(resource(@task), :method => "PUT", 
        :params => { :task => {:id => @task.id} })
    end
  
    it "redirect to the task show action" do
      @response.should redirect_to(resource(@task))
    end
  end
  
end

