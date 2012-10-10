require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -S rake spec SPEC=spec/models/web_request_spec.rb

describe WebRequest do

  before :all do
    seed_lookup_tables
    Client.first_or_create(valid_client_attributes)
  end
  
  before :each do
    
    @web_request = WebRequest.new(
      :xml_text => '<FormEntry>     <ID>6963</ID>     <Type>0</Type>     <Name>Steppes Contact Form</Name>     <Date>2012-09-12T15:26:19.987</Date>     <IP>86.188.130.162 </IP>     <FirstPage>http://www.steppestravel.co.uk/contact/form/</FirstPage>     <Referrer>http://www.steppestravel.co.uk/destinations/far+east/vietnam/journeyideas/vietnam+for+families/</Referrer>     <Keywords/>     <Paid>false</Paid>     <WhereFrom>http://www.steppestravel.co.uk/destinations/far+east/vietnam/journeyideas/vietnam+for+families/</WhereFrom>     <Fields>       <FormField>         <Field>accommodationType</Field>         <Value>Five star luxury</Value>       </FormField>       <FormField>         <Field>Address1</Field>         <Value>SONDIL HOUSE</Value>       </FormField>       <FormField>         <Field>Address2</Field>         <Value>1 COLEMAN DR</Value>       </FormField>       <FormField>         <Field>Brochure</Field>         <Value>Selected</Value>       </FormField>       <FormField>         <Field>Comments</Field>         <Value>2 nights in the capital, and the remaining 8 days in a beach front resort.</Value>       </FormField>       <FormField>         <Field>ConfirmEmail</Field>         <Value>nareshgamanlal@aol.com</Value>       </FormField>       <FormField>         <Field>Country</Field>         <Value>UK</Value>       </FormField>       <FormField>         <Field>CountryInterest</Field>         <Value>Vietnam</Value>       </FormField>       <FormField>         <Field>CountryInterestOther</Field>         <Value>Cambodia</Value>       </FormField>       <FormField>         <Field>CountyState</Field>         <Value>KENT</Value>       </FormField>       <FormField>         <Field>Email</Field>         <Value>nareshgamanlal@aol.com</Value>       </FormField>       <FormField>         <Field>FirstName</Field>         <Value>NARESH</Value>       </FormField>       <FormField>         <Field>HolidayDuration</Field>         <Value>10 DAYS</Value>       </FormField>       <FormField>         <Field>HowFindUs</Field>         <Value>Found you on Google</Value>       </FormField>       <FormField>         <Field>MonthTravelMonth</Field>         <Value>December</Value>       </FormField>       <FormField>         <Field>MonthTravelYear</Field>         <Value>2012</Value>       </FormField>       <FormField>         <Field>NameTitle</Field>         <Value>Mr</Value>       </FormField>       <FormField>         <Field>Newsletter</Field>         <Value>Selected</Value>       </FormField>       <FormField>         <Field>NumPeople</Field>         <Value>3</Value>       </FormField>       <FormField>         <Field>Postcode</Field>         <Value>ME10 2EA</Value>       </FormField>       <FormField>         <Field>Surname</Field>         <Value>GAMANLAL</Value>       </FormField>       <FormField>         <Field>Tel</Field>         <Value>07786025658</Value>       </FormField>       <FormField>         <Field>TownCity</Field>         <Value>SITTINGBOURNE</Value>       </FormField>       <FormField>         <Field>TypeAirTravel</Field>         <Value>Premium Economy</Value>       </FormField>     </Fields>   </FormEntry>',
      :user_id  => User.last.id,  # Validation fails if we set user model instead because web_request model has no fk to user table (deliberately to allow for deleted users)
      :company  => Company.last
    )
    
  end
  
  it "should be valid" do
    @web_request.should be_valid
  end
  
  it "should save if valid" do
    @web_request.save.should be_true
    @web_request.status_id.should == WebRequestStatus::PENDING
  end
  
  it "should automatically become Processed if Pending and saved for an existing client" do
    @web_request.save
    @web_request.client = Client.last
    #@web_request.status_id.should == WebRequestStatus::PROCESSED
  end
  
  it "should automatically become Allocated if Pending and saved for a new client" do
    @web_request.save
    @web_request.client = Client.new(valid_client_attributes)
    #@web_request.status_id.should == WebRequestStatus::ALLOCATED
  end
  
  it "should be able to generate a valid brochure_request" do
    
    @web_request.client = Client.last
    brochure = @web_request.generate_brochure_request
    brochure.should_not be_nil
    brochure.should be_valid
    
  end
  
  it "should not automatically create a brochure_request when created" do
    
    brochures_before = BrochureRequest.count
    @web_request.save
    brochures_after = BrochureRequest.count
    brochures_after.should == brochures_before
    @web_request.status_id.should == WebRequestStatus::PENDING
    
  end
    
  it "should automatically create a valid brochure_request when processed" do
    
    brochures_before = BrochureRequest.count
    @web_request.save
    @web_request.update :client => Client.last
    brochures_after = BrochureRequest.count
    brochures_after.should == brochures_before + 1
    
  end
  
  it "should make freshly generated brochure request available via a property:" do
    
    @web_request.save
    @web_request.update :client => Client.last
    @web_request.brochure_request.should be_an_instance_of BrochureRequest
    
  end
    
end