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
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    
    raise NotFound unless @trip
    
    # Make this the active trip version if required:
    @trip.become_active_version! if params[:is_active_version] && !@trip.is_active_version
    
    # Important: Always assume we want to display the active version of the requested trip:
    #@trip = @trip.active_version
    
    # Belt and braces in case active_version is missing! Revert to the requested trip id:
    @trip ||= requested_version.become_active_version!
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
  
  # Trip elements-builder (timeline) page:
  def builder(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  # Itinerary preview page:
  def itinerary(id)
    @trip = Trip.get(id)
    raise NotFound unless @trip
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    display @trip
  end
  
  # GET the Copy-from-another-trip page:
  def copy(id)
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
    tour    = Tour.get( params[:tour_id] )
    client  = Client.get( params[:client_id] ) || session.user.most_recent_client
    @client_or_tour = tour || client

    original_version  = Trip.get( params[:version_of_trip_id] )
    is_new_version    = !original_version.nil?
    
    # New copy of a trip, ready to be saved: (Eg: Copy of a Tour Template trip)
    if params[:copy_trip_id]
      
      if master = Trip.get( params[:copy_trip_id] )
        
        @trip.copy_countries_from master
        @trip.copy_attributes_from master
        @trip.user = session.user
          
  		  # Ensure current client is on this new trip:
        @trip.trip_clients.new( :client_id => client.id ) if client.id && !@trip.trip_clients.first( :client_id => client.id )
        
        # Make the current client primary: (Eg: when creating a FIXED DEPARTURE from a tour template)
        # Beware! This saves the trip so it's not suitable for use here on a new trip!
        # @trip.set_primary_client!( client.id ) if client.id

        message[:notice]  = "Voila! A copy of #{ master.title } to do with as you please...\n(Don't forget to save it!)"
        
      end
      
    # New template-trip for a Tour:
    elsif params[:tour_id]
      
      @trip.type_id     = TripType::TOUR_TEMPLATE
      @trip.tour_id     = @client_or_tour.id
      @trip.company_id  = @client_or_tour.company_id
      @trip.user_id   ||= session.user.id
      
      message[:notice]  = "Don't forget to save this new fixed-departure for #{ @trip.tour.name }"

      # This functionality moved to trips#update
      #  # A new version of an existing trip:
      #  elsif is_new_version
      #    
      #    @trip.copy_attributes_from( original_version.active_version )
      #    #@trip.version_of_trip = original_version.active_version
      #    @trip.user_id   ||= session.user.id
      #
      #    if @trip.save && @trip.update( :version_of_trip_id => original_version.active_version.id )
      #      message[:notice] = "A new version of this trip has been created"
      #    else
      #      message[:error]  = error_messages_for( @trip, :header => 'Could not create a new version of this trip because:' )
      #    end
      
    # A whole new trip:
    else

		  # Ensure current client is on this new trip:
      @trip.trip_clients.new( :client_id => client.id )
      @trip.user    ||= session.user
      @trip.company ||= @trip.user && @trip.user.company
      
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
    
    @trip		        = Trip.new
    @client_or_tour = Tour.get(params[:tour_id]) || Client.get(params[:client_id]) || session.user.most_recent_client

		# Workaround for when no checkboxes are ticked: (Because posted params will not contain an array of ids)
		trip[:countries_ids] ||= []
    
		accept_valid_date_fields_for trip, [ :start_date, :end_date ]
    
		# Make assumptions for missing dates:
		trip[:start_date]         ||= Date.today
		trip[:end_date]           ||= trip[:start_date]
    trip[:version_of_trip_id] ||= 0
    
    # Skip any unwanted clients: (Those marked for delete)
    # This typically only occurs when creating a new fixed dep that is a duplicate of a tour template.
    trip[:trip_clients_attributes].delete_if{ |i,attrs| attrs[:_delete] } if trip[:trip_clients_attributes]

    # Remember whether we need to copy elements etc from another trip:
    do_copy_trip_id = trip.delete(:do_copy_trip_id)

    # Deprecated: This is now handled in trip#check_client_source_on_new_trip
    #if @client_or_tour.is_a? Client
    #  
    #  # This applies to new private trips only:
    #  # Hack: Don't know why trip[:clients_attributes][x][:source_id] is not being saved so we set it explicitly:
    #  #new_source_id = trip[:clients_attributes] \
    #  #  && trip[:clients_attributes][@client_or_tour.id.to_s] \
    #  #  && trip[:clients_attributes][@client_or_tour.id.to_s][:source_id]
    #  #@client_or_tour.source_id = new_source_id.to_i if new_source_id.to_i > 0
    #
    #  new_source_id = trip[:trip_clients_attributes] &&
    #    trip[:trip_clients_attributes]['0'] &&
    #    trip[:trip_clients_attributes]['0'][:source_id]
    #    #trip[:trip_clients_attributes]['0'].delete(:source_id)
    #
    #  @client_or_tour.source_id = new_source_id.to_i if new_source_id.to_i > 0
    #
    #end

    @trip.attributes = trip
    #@trip		        = Trip.new(trip)
    #@client_or_tour = Tour.get(params[:tour_id]) || Client.get(params[:client_id]) || session.user.most_recent_client
    
		@trip.updated_by					||= session.user.fullname
    @trip.clients							<<	@client_or_tour unless @trip.tour

		
		# Alas this does not seem to affect the row in the trip_clients table:
		@trip.trip_clients.each{ |relationship| relationship.created_by = @trip.created_by }

		if @trip.save
      
      message[:notice] = "Trip was created successfully"

      # COPY TRIP: Populate our new trip with elements etc from another trip if specified:
      if do_copy_trip_id

        @trip.do_copy_trip do_copy_trip_id

        clients_saved   = @trip.trip_clients.save!
        elements_saved  = @trip.trip_elements.save!
        countries_saved = @trip.trip_countries.save!
        
        unless clients_saved && countries_saved && elements_saved

          message[:error] = 'But...'
          message[:error] << '\n There was a problem copying elements!'  unless elements_saved
          message[:error] << '\n There was a problem copying clients!'   unless clients_saved
          message[:error] << '\n There was a problem copying countries!' unless countries_saved

        end

        # Make the current client primary: (Eg: when creating a FIXED DEPARTURE from a tour template)
        @trip.set_primary_client!( @client_or_tour.id ) if @client_or_tour.is_a?(Client) && @client_or_tour.id

      end

      display @trip, :show
      
    else

      collect_error_messages_for @trip, :clients      unless @trip.new?
      collect_error_messages_for @trip, :trip_clients unless @trip.new?
      collect_error_messages_for @trip, :countries

#      @trip.model.relationships.each do | name, association |
#        
#        if @trip.respond_to?(name) #&& name.to_sym != :version_of_trips
#          
#          #if ( rel = @trip.send(name) ) && ( association.is_a?(DataMapper::Associations::ManyToOne) || association.is_a?(DataMapper::Associations::OneToOne) )
#          if ( rel = @trip.method(name).call ) && rel.respond_to?(:each)
#            collect_error_messages_for @trip, name.to_sym
#          elsif rel
#            collect_child_error_messages_for @trip, rel
#          end
#          
#        end
#        
#      end

      message[:error] = "There was a problem saving the new trip. \n #{ error_messages_for @trip, :header => 'The trip could not be created because:' }"
      render :new

    end
    
  end
  
  

  def update(id, trip)

    @trip = Trip.get(id)
    raise NotFound unless @trip
    @trip_version = @trip
    
    @client_or_tour = Tour.get( params[:tour_id] ) || Client.get( params[:client_id] ) || session.user.most_recent_client
    
		# Workaround for when no checkboxes are ticked: (Because posted params will not contain an array of ids)
    # This also fixes bug where saving the costing sheet caused country selections to be lost! http://www.bugtails.com/projects/299/tickets/209.html
		trip[:countries_ids] ||= @trip.countries_ids
    
		# Convert from UK date formats and make assumptions for missing dates:
    # TODO: Do this in the model instead.
		accept_valid_date_fields_for trip, [ :start_date, :end_date ]
    trip[:start_date] ||= @trip.start_date || Date.today
    trip[:end_date]   ||= @trip.end_date   || trip[:start_date]
    
		# Make a note of the PNR numbers associated with the trip before it is updated:
		pnr_numbers_before  = @trip.pnr_numbers
    flight_count_before = @trip.flights.length
    
    next_page = params[:redirect_to] && params[:redirect_to].to_sym || nil
    
    # This attribute needs to be set before calling @trip.update: (because we cannot guarantee the order in which the params are processed)
    @trip.auto_update_elements_dates = trip[:auto_update_elements_dates] || false


    # Switch VERSION:
    if trip[:active_version_id] && trip[:active_version_id].to_i != @trip.id

      puts 'Switching version...'

      # Make NEW VERSION:
      if trip[:active_version_id] == 'new'
        
        Merb.logger.info "Creating new version of trip #{ @trip.version_of_trip_id } from version #{ @trip.id }"
        #@trip_version = Trip.new
        #@trip_version.copy_attributes_from @trip, { :is_active_version => true, :user => session.user }
        @trip_version = @trip.new_version( :is_active_version => true, :user => session.user )
        
        if @trip_version.save! && @trip_version.become_active_version!( :save, :save_versions )

          @trip = @trip_version
          message[:notice] = "A new version has been created and is now the active version of this trip."

          clients_saved   = @trip_version.trip_clients.save!
          elements_saved  = @trip_version.trip_elements.save!
          countries_saved = @trip_version.trip_countries.save!
          
          unless clients_saved && countries_saved && elements_saved

            message[:error] = 'But...'
            message[:error] << '\n There was a problem copying elements!'  unless elements_saved
            message[:error] << '\n There was a problem copying clients!'   unless clients_saved
            message[:error] << '\n There was a problem copying countries!' unless countries_saved

          end

        else
          collect_error_messages_for @trip_version
  			  message[:error] = "The version you are copying from seems to have a few issues so it cannot be copied\n(typical causes are elements without a supplier or handler). \n #{ error_messages_for( @trip_version, :header => 'The new version could not be saved because:' ) }"
        end
        
        return render :show


      # Change the ACTIVE VERSION:
      else

        @trip_version = @trip.versions.get( trip[:active_version_id] )

        if @trip_version && @trip_version.become_active_version!(:save)

          @trip = @trip_version
          message[:notice] = 'The active version has been changed successfully.'

        else

          if @trip_version
            collect_error_messages_for @trip_version
  			    message[:error] = "Oh dear. Unable to switch versions.\n(typical causes are elements without a supplier or handler). \n #{ error_messages_for( @trip_version, :header => 'The new version could not be saved because:' ) }"
          else
  			    message[:error] = "Oh dear. Unable to switch versions.\n(typical causes are elements without a supplier or handler)."
          end

        end

        render :show

      end


    # Set MARGIN on all elements:
    elsif params[:submit] =~ /margin/i || params[:form_submit] =~ /margin/i

      puts "Setting margins to #{ params[:new_margin].to_f }"

      if @trip.update_margins_to( params[:new_margin].to_f, :save )
      
        message[:notice] = "Successfully set the margin on every element and then recalculated trip prices."
        
        if request.ajax?
          next_page ? render(next_page) : render(:show)
        else
          redirect "#{ resource(@client_or_tour, @trip) }/#{ next_page }", :message => message
        end
      
      else

        collect_error_messages_for @trip
			  message[:error] = "Oh dear, there was some difficulty setting the margins. \n #{ error_messages_for( @trip, :header => 'The trip details could not be saved because:' ) }"
        render :show

      end


    # Update EXCHANGE RATES
    elsif params[:submit] =~ /exchange rate/i || params[:form_submit] =~ /exchange rate/i

      puts 'Updating exchange rates'

      if @trip.update_exchange_rates(:save)
      
        message[:notice] = "Successfully updated the exchange rate on every element and then recalculated trip prices."
        
        if request.ajax?
          next_page ? render(next_page) : render(:show)
        else
          redirect "#{ resource(@client_or_tour, @trip) }/#{ next_page }", :message => message
        end
      
      else

        collect_error_messages_for @trip
			  message[:error] = "Oh dear, there was some difficulty updating the exchange rates. \n #{ error_messages_for( @trip, :header => 'The trip details could not be saved because:' ) }"
        render :show

      end


    # Otherwise apply the changes in the normal way:
		elsif @trip.update(trip)

      puts "Updating trip #{@trip.id}"

			message[:notice]	  = 'Trip was updated successfully. '
      #message[:notice]   += 'The active version has been changed.' if @trip_version
      
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
      incomplete_elements = @trip.elements.all( :supplier_id => nil ) && @trip.elements.all( :supplier_id => 0 )
      unless incomplete_elements.empty?
        message[:notice] << "\n Warning: #{ incomplete_elements.length } elements have no supplier. I'm going to tell your mum"
      end
      
      # Warning about pax-count mismatch:
      if @trip.travellers != @trip.clients.length
			  message[:notice] << "\n Tip: Consider adjusting the numbers of adults, children &amp; infants to match clients on this trip."
      end
      
      
      if request.ajax?
        next_page ? render(next_page) : render(:show)
      else
        redirect "#{ resource(@client_or_tour, @trip) }/#{ next_page }", :message => message
      end
      
    else

      puts "Error during update trip #{@trip.id}"

      collect_error_messages_for @trip
      collect_error_messages_for @trip, :elements
			message[:error] = "Oops, something odd happened. In all the excitement I kinda got lost.\n(The usual suspects are elements without a supplier or handler). \n #{ error_messages_for( @trip, :header => 'The trip details could not be saved because:' ) }"
      print "\n /trips/#{ id }/update FAILED !!!\n #{ message[:error] } #{ @trip.errors.inspect }\n"
      @trip.elements.each{|e| e.valid?; puts e.errors.inspect }
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
      else
        message[:notice] = "The trip-version has been deleted"
        @trip = original_version
      end

      redirect resource(@client_or_tour), :message => message
      #display @client_or_tour
      
    else
      raise InternalServerError
    end
  end
  
end # Trips
