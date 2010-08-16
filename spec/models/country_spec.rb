require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Country do

  before(:each) do
		@country = Country.new( :name => 'test')
		@country.mailing_zone = MailingZone.get(1)
	end
	
	it "should have a name" do
		
		@country.name.should eql('test')
		
	end
	
	it "should have a Mailing Zone" do
		
		#@country.should respond_to :mailing_zone
		@country.mailing_zone.id.should eql(1)
		
	end
	
end