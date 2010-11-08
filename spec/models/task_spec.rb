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

    @company      = Company.first_or_create()
    @world_region = WorldRegion.first_or_create( { :name => 'Dummy Region' }, { :name => 'Dummy Region' } )
    @mailing_zone = MailingZone.first_or_create( { :name => 'Dummy Zone'   }, { :name => 'Dummy Zone'   } )
    @title        = Title.create( :name => 'Mr' )
    @client       = Client.first_or_create(  { :name => 'Client 1'  }, { :title => @title, :name => 'Client 1', :forename => 'Test', :marketing_id => 1, :type_id => 1, :original_source_id => 1, :address_client_id => 1 } )
    
    seed_lookup_tables()

  end

  before :each do
    @task     = Task.new(valid_task_attributes)
		@brochure = BrochureRequest.new(valid_brochure_request_attributes)		
    
  end

  after :each do
    BrochureRequest.all.destroy
    TripElement.all.destroy
    Task.all.destroy
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

  it "should be created automatically when a trip with flights is confirmed" do

      # Create a company that probably has a document template ready for use, so invoice.document passes dummy-run validation:
      trip = Trip.new(valid_trip_attributes)
      trip.clients << @client
      trip.company = Company.first_or_create( { :initials => 'SE' }, { :initials => 'SE', :invoice_prefix => 'SE', :name => 'Just for testing', :short_name => 'Testing' } )
      trip.save.should be_true
      TripElement.create( valid_flight_attributes.merge(:trip_id=>trip.id) )
      TripElement.create( valid_flight_attributes.merge(:trip_id=>trip.id) )
      trip.reload
      trip.should have(2).trip_elements

      main_invoice      = MoneyIn.new( :skip_doc_generation => true, :client_id => 1, :deposit => 100, :amount => 1000, :user_id => 1  )
      main_invoice.trip = trip
      main_invoice.skip_doc_generation = true
      
      # Before main invoice:
      Task.all.should have(0).tasks
      main_invoice.trip.status_id.should == Trip::UNCONFIRMED
      
      # After main invoice:
      main_invoice.valid?; puts main_invoice.errors.inspect unless main_invoice.errors.empty?
      main_invoice.save.should be_true
      main_invoice.trip.status_id.should == Trip::CONFIRMED
      Task.all.should have(2).tasks
      Task.all[0].kind_id.should == TaskType::FLIGHT_REMINDER
      Task.all[1].kind_id.should == TaskType::FLIGHT_REMINDER
      
  end

  it "should be deleted automatically when an associated flight is deleted" do
    
    flight = TripElement.new( valid_flight_attributes.merge(:trip_id=>1) )
    flight.save.should be_true
    flight.create_task(:force)
    flight.tasks.should have(1).trip_element

    Task.all.should have(1).tasks
    flight.destroy
    Task.all.should have(0).tasks

  end

  it "should be deleted automatically when an associated trip is deleted" do
    
    flight = TripElement.new( valid_flight_attributes.merge(:trip_id=>1) )
    flight.save.should be_true
    flight.create_task(:force)
    flight.tasks.should have(1).trip_element

    Task.all.should have(1).tasks
    flight.trip.destroy
    Task.all.should have(0).tasks

  end

  it "should be created automatically when a brochure_request is cleared" do

    brochure1 = BrochureRequest.create( valid_brochure_request_attributes.merge( :notes => 'Brochure 1', :skip_doc_generation => true ) )
    brochure2 = BrochureRequest.create( valid_brochure_request_attributes.merge( :notes => 'Brochure 2', :skip_doc_generation => true ) )
    puts brochure1.errors.inspect unless brochure1.errors.empty?
    puts brochure2.errors.inspect unless brochure2.errors.empty?
    brochures = BrochureRequest.all
    brochures.should have(2).brochure_requests

    Task.all.should have(0).tasks

    BrochureRequest.clear_merge_for( brochures ).should be_true
    brochure1.reload
    brochure2.reload
    brochure1.status_id.should == BrochureRequest::CLEARED
    brochure2.status_id.should == BrochureRequest::CLEARED
   
    Task.all.should have(2).tasks

  end

end