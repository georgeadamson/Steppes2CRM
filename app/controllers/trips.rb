class Trips < Application
  # provides :xml, :yaml, :js
  
	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    
    tour   = Tour.get( params[:tour_id] )
    client = Client.get( params[:client_id] )
    @client_or_tour = tour || client || session.user.most_recent_client

    if params[:tour_id] && tour
			@trips  = tour.trips
		elsif params[:client_id] && client
			@trips  = client.trips
		else
			@trips  = Trip.all
		end
    
		@trips = @trips.all( :is_active_version => true )
    display @trips
    
  end
  
  def show(id)
    
    @trip   = requested_version = Trip.get(id)
    #@tour   = Tour.get( params[:tour_id] )
    #@client = Client.get( params[:client_id] ) || session.user.most_recent_client
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    
    raise NotFound unless @trip
    
    # Make this the active trip version if required:
    @trip.become_active_version if params[:is_active_version] && !@trip.is_active_version
    
    # Important: Always assume we want to display the active version of the requested trip:
    #@trip = @trip.active_version
    
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
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def itinerary(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def documents(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def costings(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  # Depricated?
  def accounting(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  def invoice(id)
    only_provides :html
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  
  def new
    
    @trip   = Trip.new
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    
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
      
      @trip.type_id     = TripType::TOUR_TEMPLATE
      @trip.tour_id     = @client_or_tour.id
      @trip.company_id  = @client_or_tour.company_id
      @trip.user_id   ||= session.user.id
      
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
    
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
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
    
    # Skip any unwanted clients: (Those marked for delete)
    # This typically only occurs when creating a new fixed dep that is a duplicate of a tour template.
    trip[:trip_clients_attributes].delete_if{ |i,attributes| attributes[:_delete] } if trip[:trip_clients_attributes]

    @trip		= Trip.new(trip)
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
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
      collect_error_messages_for @trip, :clients
      collect_error_messages_for @trip, :trip_clients
      collect_error_messages_for @trip, :countries

      @trip.model.relationships.each do | name, association |
        
        if @trip.respond_to?(name) #&& name.to_sym != :version_of_trips
          
          #if ( rel = @trip.send(name) ) && ( association.is_a?(DataMapper::Associations::ManyToOne) || association.is_a?(DataMapper::Associations::OneToOne) )
          if ( rel = @trip.method(name).call ) && rel.respond_to?(:each)
            collect_error_messages_for @trip, name.to_sym
          elsif rel
            collect_child_error_messages_for @trip, rel
          end
          
        end
        
      end

message[:error] = error_messages_for( @trip, :header => 'The trip details could not be created because:' )
			message[:notice] = 'aarrh'
      render :new
    end
    
  end
  
  
  def update(id, trip)
    
    @trip = Trip.get(id)
    raise NotFound unless @trip
    
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    
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
#      collect_error_messages_for @trip, :pnrs
#      collect_error_messages_for @trip, :trip_pnrs
#      collect_error_messages_for @trip, :countries
#      collect_error_messages_for @trip, :trip_countries
#      collect_error_messages_for @trip, :trip_elements
#      collect_error_messages_for @trip, :trip_clients
#      collect_error_messages_for @trip, :clients
#      collect_error_messages_for @trip, :money_ins
#      collect_error_messages_for @trip, :money_outs

      @trip.model.relationships.each do | name, association |

        if @trip.respond_to?(name) #&& name.to_sym != :version_of_trips

          #if ( rel = @trip.send(name) ) && ( association.is_a?(DataMapper::Associations::ManyToOne) || association.is_a?(DataMapper::Associations::OneToOne) )
          if ( rel = @trip.method(name).call ) && rel.respond_to?(:each)
            collect_error_messages_for @trip, name.to_sym
          elsif rel
            collect_child_error_messages_for @trip, rel
          end

        end

      end

			message[:error] = "Oops, something odd happened. In all the excitement I kinda got lost. \n #{ error_messages_for( @trip, :header => 'The trip details could not be saved because:' ) }"
      print "\n /trips/#{ id }/update FAILED !!!\n #{ message[:error] } #{ @trip.errors.inspect }\n"
      #display next_page.to_sym
      #display @trip
      render :show
    end
    
  end
  
  
  def destroy(id)
    
    @trip = Trip.get(id)
    raise NotFound unless @trip
    
    original_version = @trip.version_of_trip
    
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    next_page = params[:redirect_to] || resource( @client_or_tour, :trips )
    
    if @trip.destroy

      if @trip == original_version
        message[:notice] = "The trip has been deleted"
        #display @client_or_tour.trips, :index
        #redirect resource(@client_or_tour, :trips)
      else
        message[:notice] = "The trip-version has been deleted"
        @trip = original_version
        @trip.become_active_version
        #display @trip
        #render :show
      end

      redirect resource(@client_or_tour), :message => message
      #display @client_or_tour
      
    else
      raise InternalServerError
    end
  end
  
end # Trips
