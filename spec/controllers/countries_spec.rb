#
# Command to run these tests: jruby -S spec spec\controllers\countries_spec.rb
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

print "\n Using '#{ Merb.environment }' database...\n"

describe Countries do
  
  describe "GET index" do
  
    def do_request
      dispatch_to(Countries, :index) do |controller|
        #controller.stub!(:ensure_authenticated)
        #controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
  
	end


	describe "GET show" do
	
		before :each do
			
			#	merb : worker (port 81) ~ Routed to: {"url_params"=>"{}", "country"=>{"name"=>"N
			#	ew country", "world_region_id"=>"1", "mailing_zone_id"=>"1", "companies_ids"=>["
			#	2", "1"], "inclusions"=>"", "exclusions"=>"", "notes"=>""}, "controller"=>"count
			#	ries", "action"=>"create", "format"=>nil}
			
			Country.create( :name => 'Test1', :code => 'T1', :world_region_id => 1, :mailing_zone_id => 1, :companies_ids => ['1'] ) unless Country.first( :code => 'T1' )
			
			@country_id = Country.first( :code => 'T1' ).id
			
		end
		
#		after :each do
#			
#			country = Country.get(@country_id)
#
#			country.destroy if country
#			
#		end
		
    def do_request
      dispatch_to(Countries, :show, :id => @country_id ) do |controller|
        #controller.stub!(:ensure_authenticated)
        #controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should be successful" do
      do_request.should be_successful
    end	

		#	it "should assign country for the view" do
		#		Country.should_receive(:get).with(@country_id).and_return(@country)
		#		do_request.assigns(:country).should == @country
		#	end
	
	end



	describe "Get new" do

		before do
			@country = mock(:country)
			Country.stub!(:new).and_return(@country)
		end
		
		def do_request
			dispatch_to(Countries, :new) do |controller|
				#controller.stub!(:ensure_authenticated)
				#controller.stub!(:ensure_admin)
				controller.stub!(:render)
			end
		end
		
		it "should assign country for view" do
			Country.should_receive(:new).and_return(@country)
			do_request.assigns(:country).should == @country
		end
		
		it "should be successful" do
			do_request.should be_successful
		end

	end



  describe "POST create (with valid country)" do
  
    before do
      @attrs = { :name => 'Test2', :code => 'T2', :world_region_id => 1, :mailing_zone_id => 1, :companies_ids => ['1'] }
      @country = mock(:country, :save => true)
      Country.stub!(:new).and_return(@country)
    end
    
    def do_request
      dispatch_to(Countries, :create, :country => @attrs) do |controller|
        #controller.stub!(:ensure_authenticated)
        #controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign new country" do
      Country.should_receive(:new).with(@attrs).and_return(@country)
      do_request.assigns(:country).should == @country
    end
    
    it "should save the country" do
      @country.should_receive(:save).and_return(true)
      do_request
    end
    
    it "should redirect" do
      do_request.should redirect_to(url(:countries))
    end
  end
	
	
	
  describe "POST create (with invalid country)" do
    before do
      @attrs = { :name => '', :code => 'T2', :world_region_id => 1, :mailing_zone_id => 1, :companies_ids => ['1'] }
      @country = mock(:country, :save => false)
      Country.stub!(:new).and_return(@country)
    end
    
    def do_request
      dispatch_to(Countries, :create, :country => @attrs) do |controller|
        #controller.stub!(:ensure_authenticated)
        #controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign new country" do
      Country.should_receive(:new).with(@attrs).and_return(@country)
      do_request.assigns(:country).should == @country
    end
    
    it "should attempt to save the country" do
			@country.should_receive(:save).and_return(false)
      do_request
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
 
  end
 
end