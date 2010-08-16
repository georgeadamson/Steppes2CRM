#
# Command to run these tests: jruby -S spec spec\controllers\trips_spec.rb
#

require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

print "\n Using '#{ Merb.environment }' database...\n"




describe Trips do
  
  
  
  describe "GET index" do
  
    def do_request
      dispatch_to(Trips, :index) do |controller|
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
			
			@trip = mock(:trip)
			
			Trip.stub!(:get).and_return(@trip)
			
		end

		
    def do_request
      dispatch_to(Trips, :show, :id => 1 ) do |controller|
        #controller.stub!(:ensure_authenticated)
        #controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should be successful" do
      do_request.should be_successful
    end	

		it "should assign trip for the view" do
			Trip.should_receive(:get).with('1').and_return(@trip)
			do_request.assigns(:trip).should == @trip
		end
	
	end



	#	describe "GET show (with missing trip)" do    
	#		def do_request
	#			dispatch_to(Trips, :show, :id => 1) do |controller|
	#				controller.stub!(:ensure_authenticated)
	#				controller.stub!(:ensure_admin)
	#				controller.stub!(:render)
	#			end
	#		end
	#		
	#		it_should_behave_like 'TripNotFound'
	#	end




  describe "Get new" do

    before do
      @trip   = mock(:trip)
      Trip.stub!(:new, :client_id => 1 ).and_return(@trip)
    end	
    
    def do_request
      dispatch_to(Trips, :new) do |controller|
        controller.stub!(:ensure_authenticated)
        #controller.stub!(:ensure_admin)
        controller.stub!(:render, :client_id => 1 )
      end
    end
    
    it "should assign trip for view" do
      Trip.should_receive(:new).and_return(@trip)
      do_request.assigns(:trip).should == @trip
    end
    
    it "should be successful" do
      do_request.should be_successful
    end

  end
  
#  describe "POST create (with valid trip)" do
#    before do
#      @attrs = {'login' => 'jnunemaker'}
#      @trip = mock(:trip, :save => true)
#      Trip.stub!(:new).and_return(@trip)
#    end
#    
#    def do_request
#      dispatch_to(Trips, :create, :trip => @attrs) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it "should assign new trip" do
#      Trip.should_receive(:new).with(@attrs).and_return(@trip)
#      do_request.assigns(:trip).should == @trip
#    end
#    
#    it "should save the trip" do
#      @trip.should_receive(:save).and_return(true)
#      do_request
#    end
#    
#    it "should redirect" do
#      do_request.should redirect_to(url(:trips))
#    end
#  end
#  
#  describe "POST create (with invalid trip)" do
#    before do
#      @attrs = {'login' => ''}
#      @trip = mock(:trip, :save => false)
#      Trip.stub!(:new).and_return(@trip)
#    end
#    
#    def do_request
#      dispatch_to(Trips, :create, :trip => @attrs) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it "should assign new trip" do
#      Trip.should_receive(:new).with(@attrs).and_return(@trip)
#      do_request.assigns(:trip).should == @trip
#    end
#    
#    it "should attempt to save the trip" do
#      @trip.should_receive(:save).and_return(false)
#      do_request
#    end
#    
#    it "should be successful" do
#      do_request.should be_successful
#    end
#  end
#  
#  describe "GET edit" do
#    before do
#      @trip = mock(:trip)
#      @mappings = [mock(:mapping)]
#      @trip.stub!(:mappings).and_return(@mappings)
#      Trip.stub!(:get).and_return(@trip)
#    end
#    
#    def do_request
#      dispatch_to(Trips, :edit, :id => 1) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it "should be successful" do
#      do_request.should be_successful
#    end
#    
#    it "should assign trip for the view" do
#      Trip.should_receive(:get).with('1').and_return(@trip)
#      do_request.assigns(:trip).should == @trip
#    end
#  end
#  
#  describe "GET edit (with missing trip)" do    
#    def do_request
#      dispatch_to(Trips, :edit, :id => 1) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it_should_behave_like 'TripNotFound'
#  end
#  
#  describe "PUT update (with valid trip)" do
#    before do
#      @attrs = {'login' => 'jnunemaker'}
#      @trip = mock(:trip, :update_attributes => true)
#      Trip.stub!(:get).and_return(@trip)
#    end
#    
#    def do_request
#      dispatch_to(Trips, :update, :id => 1, :trip => @attrs) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it "should assign trip" do
#      Trip.should_receive(:get).with('1').and_return(@trip)
#      do_request.assigns(:trip).should == @trip
#    end
#    
#    it "should update the trip's attributes" do
#      @trip.should_receive(:update_attributes).and_return(true)
#      do_request
#    end
#    
#    it "should redirect" do
#      do_request.should redirect_to(url(:trips))
#    end
#  end
#  
#  describe "PUT update (with invalid trip)" do
#    before do
#      @attrs = {'login' => ''}
#      @trip = mock(:trip, :update_attributes => false)
#      Trip.stub!(:get).and_return(@trip)
#    end
#    
#    def do_request
#      dispatch_to(Trips, :update, :id => 1, :trip => @attrs) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it "should assign new trip" do
#      Trip.should_receive(:get).with('1').and_return(@trip)
#      do_request.assigns(:trip).should == @trip
#    end
#    
#    it "should attempt to update the trip's attributes" do
#      @trip.should_receive(:update_attributes).and_return(false)
#      do_request
#    end
#    
#    it "should be successful" do
#      do_request.should be_successful
#    end
#  end
#	
#  describe "PUT update (with missing trip)" do    
#    def do_request
#      dispatch_to(Trips, :update, :id => 1) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#		
#    it_should_behave_like 'TripNotFound'
#  end
#  
#  describe "DELETE destroy" do
#    before do
#      @trip = mock(:trips, :destroy => true)
#      Trip.stub!(:get).and_return(@trip)
#    end
#    
#    def do_request
#      dispatch_to(Trips, :destroy, :id => 1) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#    
#    it "should find the trip" do
#      Trip.should_receive(:get).with('1').and_return(@trip)
#      do_request
#    end
#    
#    it "should destroy the trip" do
#      @trip.should_receive(:destroy).and_return(true)
#      do_request
#    end
#    
#    it "should redirect" do
#      do_request.should redirect_to(url(:trips))
#    end
#  end
#	
#  describe "DELETE destroy (with missing trip)" do    
#    def do_request
#      dispatch_to(Trips, :destroy, :id => 1) do |controller|
#        controller.stub!(:ensure_authenticated)
#        controller.stub!(:ensure_admin)
#        controller.stub!(:render)
#      end
#    end
#		
#    it_should_behave_like 'TripNotFound'
#  end
  
end