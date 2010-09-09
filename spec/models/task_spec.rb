require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/task_spec.rb

def valid_task_attributes
  {
    :due_date   => '2010-02-01',
    :user_id    => 1,
    :client_id  => 1,
    :type_id    => 1
  }
end

describe Task do

  before :all do
 
    @user       = User.create(valid_user_attributes)
    @client     = Client.create(valid_client_attributes)
    @task_type  = TaskType.create( :name => 'Followup' )

  end

  before :each do

    @task = Task.create(valid_task_attributes)

  end

  it "should be valid" do
    @task.should be_valid
  end

  it "should default to status of Open" do
    @task.status_id.should == TaskStatus::OPEN
  end

  it "should use today's date as default closed_date when being actioned or abandoned " do
    @task.status_id = TaskStatus::COMPLETED
    @task.save.should be_true
    @task.closed_date.should == Date.today
  end

end