class Trips < Application
  # provides :xml, :yaml, :js
  
	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    
    @client = Client.get( params[:client_id] ) if params[:client_id]
    
    if params[:client_id] && @client
			@trips  = @client.trips
		else
			@trips  = Trip.all
			@client = session.user.most_recent_client
		end
    
		@trips = @trips.all( :is_active_version => true )
    display @trips
    
  end
  
  def show(id)
    
    @trip = requested_version = Trip.get(id)
    @trips = Trip.all(:limit => 10)
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    
    raise NotFound unless @trip
    
    # Make this the active trip version if required:
    @trip.become_active_version if params[:is_active_version] && !@trip.is_active_version
    
    # Important: Always assume we want to display the active version of the requested trip:
    @trip = @trip.active_version
    
    # Belt and braces in case active_version is missing! Revert to the requested trip id:
    @trip = requested_version.become_active_version unless @trip
    #@trip = requested_version  # What was this line for?
    
    display @trip
    
  end
  
  def summary(id)
    # Depricated. Use edit() action instead.
    #@trip = Trip.get(id)
    #raise NotFound unless @trip
    #@client = @trip.context = Client.get( params[:client_id] ) || session.user.most_recent_client
    #display @trip, request.ajax? ? { :layout=>false } : nil
    render :edit
  end
  
  def builder(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def itinerary(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def documents(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def costings(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  # Depricated?
  def accounting(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def invoice(id)
    only_provides :html
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  
  def new
    
    @trip   = Trip.new
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    
    original_version  = Trip.get( params[:version_of_trip_id] )
    is_new_version    = !original_version.nil?
    
    # New copy of a trip:
    if params[:copy_trip_id]
      
      if master = Trip.get( params[:copy_trip_id] )
        
        @trip.copy_attributes_from master
        
  		  # Ensure current client is on this new trip:
        @trip.trip_clients.new( :client_id => @client.id ) if @client.id && @trip.trip_clients.all( :client_id => @client.id ).empty?
        @trip.user_id ||= session.user.id
        
        message[:notice]  = "Voila! A copy of #{ master.title } to do with as you please...\n(Don't forget to save it!)"
        
      end
      
      # New template-trip for a Tour:
    elsif params[:tour_id]
      
      @trip.tour_id   = params[:tour_id]
      @trip.type_id   = TripType::TOUR_TEMPLATE
      @trip.user_id ||= session.user.id
      
      message[:notice]  = "Don't forget to save this new fixed-departure for #{ @trip.tour.name }"
      
      # A new version of an existing trip:
    elsif is_new_version
      
      @trip.copy_attributes_from( original_version.active_version )
      @trip.user_id   ||= session.user.id
      @trip.save
      
      message[:notice]  = "A new version of this trip has been created"
      
      # A whole new trip:
    else
      
		  # Ensure current client is on this new trip:
      @trip.trip_clients.new( :client_id => @client.id )
      @trip.user_id   ||= session.user.id
      
      message[:notice]  = "This new trip will be added to the database when you save it"
      
    end
    
		# When client is the only one on the trip, make sure it is the primary contact etc:
    unless @trip.trip_clients.empty?
		  @trip.trip_clients[0].is_primary		= true if @trip.trip_clients.length > 0 && @trip.primaries.empty?
		  @trip.trip_clients[0].is_invoicable	= true if @trip.trip_clients.length > 0 && @trip.invoicables.empty?
    end
		
    if is_new_version
      render :show
    else
      display @trip
    end
    
  end
  
  
  def edit(id)
    
    @trip = Trip.get(id)
    raise NotFound unless @trip
    
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    @trip.user_id ||= session.user.id
    
		# When client is the only one on the trip, make sure it is the primary contact etc:
    unless @trip.clients.empty?
		  @trip.trip_clients.first.is_primary			= true if @trip.primaries.empty?
		  @trip.trip_clients.first.is_invoicable	= true if @trip.invoicables.empty?
    end
    
    display @trip
  end
  
  
  def create(trip)
    
		# Workaround for when no checkboxes are ticked: (Because posted params will not contain an array of ids)
		trip[:countries_ids] ||= []
    
		accept_valid_date_fields_for trip, [ :start_date, :end_date ]
    
		# Make assumptions for missing dates:
		trip[:start_date]         ||= Date.today
		trip[:end_date]           ||= trip[:start_date]
    trip[:version_of_trip_id] ||= 0
    
    @trip		= Trip.new(trip)
    @client = Client.get( params[:client_id] ) || Client.first
    puts @trip.inspect
    # Workaround: For some reason these are not set by "Trip.new(trip)":
    #@trip.user_id						||= ( trip[:user_id]		|| 1 ).to_i
    #@trip.company_id					||= ( trip[:company_id] || 1 ).to_i
    
		@trip.updated_by					||= session.user.fullname
    @trip.clients							<<	@client unless @trip.tour
		
		# Alas this does not seem to affect the row in the trip_clients table:
		@trip.trip_clients.each{ |relationship| relationship.created_by = @trip.created_by }
    
		if @trip.save
      
      message[:notice] = "Trip was created successfully"
      
      if request.ajax?
        display @trip, :show
        #redirect resource( @client, :show ), :message => message, :layout => :ajax
      else
        redirect nested_resource( @trip, :edit ), :message => message
      end
      
    else
      collect_error_messages_for @trip, :countries
			message[:error] = error_messages_for( @trip, :header => 'The trip details could not be created because:' )
      render :new
    end
    
  end
  
  
  def update(id, trip)
    
    @trip = Trip.get(id)
    raise NotFound unless @trip
    
    @client = Client.get( params[:client_id] ) || session.user.most_recent_client
    
		# Workaround for when no checkboxes are ticked: (Because posted params will not contain an array of ids)
    # This also fixes bug where saving the costing sheet caused country selections to be lost! http://www.bugtails.com/projects/299/tickets/209.html
		trip[:countries_ids] ||= @trip.countries_ids
    
		# Convert from UK date formats and
    # Make assumptions for missing dates:
		accept_valid_date_fields_for trip, [ :start_date, :end_date ]
    trip[:start_date] ||= @trip.start_date || Date.today
    trip[:end_date]   ||= @trip.end_date   || trip[:start_date]
    
		# Make a note of the PNR numbers associated with the trip before it is updated:
		pnr_numbers_before  = @trip.pnr_numbers
    flight_count_before = @trip.flights.length
    
    next_page = params[:redirect_to] && params[:redirect_to].to_sym || nil
    
    
		if @trip.update(trip)
			
			message[:notice]	  = 'Trip was updated successfully.'
      
      # Prepare to apply specified PNR numbers:
			pnr_errors				  = []
		  pnr_numbers_after   = @trip.pnr_numbers
      flight_count_after  = @trip.flights.length
      old_pnrs            = ( pnr_numbers_before - pnr_numbers_after  )
      new_pnrs            = ( pnr_numbers_after  - pnr_numbers_before )
      
      # Friendly messages about PNRs removed:
      old_pnrs.each do |pnr_number|
        message[:notice] << "\n All flights from PNR #{ pnr_number } have been removed from this trip"
      end
      
      # Friendly messages about PNRs added:
      new_pnrs.each do |pnr_number|
        number_of_flights = @trip.flights.all( :booking_code => pnr_number ).length
        message[:notice] << "\n #{ number_of_flights } flights have been added to this trip from PNR #{ pnr_number }"
      end
      
      # Report failures if any:
      collect_error_messages_for @trip, :pnrs
      unless @trip.errors.empty?
        message[:error] << "#{ error_messages_for( @trip, :header => 'The trip details could not be saved because:' ) }"
      end
      
      
			#     associated_pnrs		  = @trip.pnr_numbers
			#     dissociated_pnrs	  = []
      #
      #			# Search flight elements for PNR numbers that are not in the trip's list of pnr_numbers:
      #			@trip.flights.all.each do |flight| 
      #				unless flight.booking_code.strip.blank? || associated_pnrs.include?(flight.booking_code)
      #					dissociated_pnrs << flight.booking_code
      #				end
      #			end
      #			
      #			# Delete any of the trip's flight elements that are tagged with dissociated_pnrs:	
      #			if !dissociated_pnrs.empty? && @trip.flights.all( :booking_code => dissociated_pnrs.uniq ).destroy!
      #				message[:notice] << "\n All flights in PNR #{ dissociated_pnrs.uniq.join(', ') } have been deleted from this trip"
      #			end
      
      #			# Add flights from new PNRs:
      #			@trip.pnrs.each do |pnr|
      #				
      #				if pnr.flights.empty?
      #				
      #					message[:notice] << "\n PNR #{ pnr.number } does not contain any flights"
      #				
      #				else
      #					
      #					# Import flights from PNR and add/update them on the trip:
      #					how_many = pnr.refresh_flight_elements_for(@trip)
      #					
      #					# Report the number of successful/failed PNR imports:
      #					message[:notice] << "\n The trip has been updated with #{ how_many[:succeeded] } flights from PNR #{ pnr.number }."	unless how_many[:succeeded].zero?
      #					pnr_errors     << " #{ how_many[:failed] } flights could not be added from PNR #{ pnr.number } because:"					unless how_many[:failed].zero?
      #
      #					# Copy errors to the trip's validation errors collection: (So the trip's View can display them)
      #					how_many[:errors].each_pair do |line_nos,err|
      #						@trip.errors.add "PNR#{ pnr.number }-#{ line_nos }".to_sym, "PNR #{ pnr.number } line #{ line_nos }: #{ err }"
      #					end
      #
      #					# Report details of failed PNR flight imports:
      #					@trip.errors.each_value{ |err| pnr_errors << " - #{ err }" }
      #					
      #				end
      #				
      #			end
      #
			# message[:error] = pnr_errors.join(" \n ")
      
      
      # Warn about missing flight handlers:
      unless ( incomplete_elements = @trip.flights.all( :handler => nil ) ).empty?
        message[:notice] << "\n Warning: #{ incomplete_elements.count } flights have no handler. You'd better go and fix them"
      end
      
      # Warn about missing suppliers: (This should not be possible!)
      unless ( incomplete_elements = @trip.elements.all( :supplier => nil ) ).empty?
        message[:notice] << "\n Warning: #{ incomplete_elements.count } elements have no supplier. Rather a crucial omission"
      end
      
      # Warning about pax-count mismatch:
      if @trip.travellers != @trip.clients.length
			  message[:notice] << "\n Tip: Consider adjusting the numbers of adults, children &amp; infants to match clients on this trip."
      end
      
      
      if request.ajax?
        next_page ? render(next_page) : render(:show)
      else
        redirect "#{ nested_resource(@trip) }/#{ next_page }", :message => message
      end
      
    else
      collect_error_messages_for @trip, :pnrs
      collect_error_messages_for @trip, :countries
      collect_error_messages_for @trip, :trip_elements
			message[:error] = "Oops, something odd happened. In all the excitement I kinda got lost. \n #{ error_messages_for( @trip, :header => 'The trip details could not be saved because:' ) }"
      print "\n /trips/#{ id }/update FAILED !!!\n #{ message[:error] } #{ @trip.errors.inspect }\n"
      #display next_page.to_sym
      #display @trip
      render(:show)
    end
    
  end
  
  
  def destroy(id)
    
    @trip = Trip.get(id)
    raise NotFound unless @trip
    
    original_trip = @trip.version_of_trip
    
    next_page = params[:redirect_to] || resource( @client, :trips )
    
    if @trip.destroy
      
      @trip = original_trip
      @trip.become_active_version
      render :show
      #redirect next_page
      
    else
      raise InternalServerError
    end
  end
  
end # Trips
