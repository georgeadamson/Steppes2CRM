require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a task_type exists" do
  TaskType.all.destroy!
  request(resource(:task_types), :method => "POST", 
    :params => { :task_type => { :id => nil }})
end

describe "resource(:task_types)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:task_types))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of task_types" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a task_type exists" do
    before(:each) do
      @response = request(resource(:task_types))
    end
    
    it "has a list of task_types" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      TaskType.all.destroy!
      @response = request(resource(:task_types), :method => "POST", 
        :params => { :task_type => { :id => nil }})
    end
    
    it "redirects to resource(:task_types)" do
      @response.should redirect_to(resource(TaskType.first), :message => {:notice => "task_type was successfully created"})
    end
    
  end
end

describe "resource(@task_type)" do 
  describe "a successful DELETE", :given => "a task_type exists" do
     before(:each) do
       @response = request(resource(TaskType.first), :method => "DELETE")
     end

     it "should redirect to the index action" do
       @response.should redirect_to(resource(:task_types))
     end

   end
end

describe "resource(:task_types, :new)" do
  before(:each) do
    @response = request(resource(:task_types, :new))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@task_type, :edit)", :given => "a task_type exists" do
  before(:each) do
    @response = request(resource(TaskType.first, :edit))
  end
  
  it "responds successfully" do
    @response.should be_successful
  end
end

describe "resource(@task_type)", :given => "a task_type exists" do
  
  describe "GET" do
    before(:each) do
      @response = request(resource(TaskType.first))
    end
  
    it "responds successfully" do
      @response.should be_successful
    end
  end
  
  describe "PUT" do
    before(:each) do
      @task_type = TaskType.first
      @response = request(resource(@task_type), :method => "PUT", 
        :params => { :task_type => {:id => @task_type.id} })
    end
  
    it "redirect to the task_type show action" do
      @response.should redirect_to(resource(@task_type))
    end
  end
  
end

