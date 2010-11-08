require 'parsedate'

class TripElements < Application
  # provides :xml, :yaml, :js

	# Apply simpler layout template to ajax requests:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index

    # The index is the timeline on on the Trip builder tab.

    @trip = Trip.get( params[:trip_id] )

    @elements ||= @trip.trip_elements

#    if @trip
#      @trip.context ||= Client.get( params[:client_id] )
#      @elements = @trip ? @trip.trip_elements : TripElement.all
#    else
#      @elements = TripElement.all
#    end

    display @elements

  end

  def show(id)
    @element = TripElement.get(id)
    raise NotFound unless @element
    display @element
  end


  def new
    only_provides :html
  
    @trip = Trip.get( params[:trip_id] )
    raise NotFound unless @trip

    # Derive tripElementType from params if possible: (Eg: ?type=accomm would be typical we allow for other param names too!)
    element_type = TripElementType.first( :code => params[:kind] || params[:kind_code] ) ||
                   TripElementType.get( params[:kind_id] || params[:element_type_id] || params[:trip_element_type_id] )

    # Initialise new element's attributes:
    @element = @trip.trip_elements.new

    @element.element_type	= element_type if element_type
    @element.name					= "New #{ @element.element_type.name }"
    @element.start_date		= @trip.start_date
    @element.end_date			= @element.start_date + 1		# Default to 1 day duration.
    @element.adults				= @trip.adults
    @element.children			= @trip.children
    @element.infants			= @trip.infants
    @element.singles			= @trip.singles

    display @element

  end


  def edit(id)
    only_provides :html
    @element = TripElement.get(id)
    raise NotFound unless @element

    @element.trip.context ||= Client.get( params[:client_id] ) if @element.trip

    display @element
  end


  def create(trip_element)

		# Fetch a reference to the trip itself:
		@trip = Trip.get(trip_element[:trip_id]) || Trip.get(params[:trip_id]) || Trip.new

		accept_valid_date_fields_for trip_element, [ :start_date, :end_date, :booking_expiry ]

    # Make assumptions for missing dates:
    # Depricated: Leave this job to for the model to sort out.
    #trip_element["start_date"] ||= @trip.start_date.to_s
    #trip_element["end_date"]   ||= ( Date.strptime( trip_element["start_date"] ) + 1 ).to_s

    # TODO: Handle this in the model!
    # Some users leave out the colon from flight times so add it if necessary: (Eg '1315' => '13:15')
    trip_element["start_time"] = trip_element["start_time"].to_s.insert(2,':') if trip_element["start_time"].to_s =~ /^[0-9]{4}$/
    trip_element["end_time"  ] = trip_element["end_time"  ].to_s.insert(2,':') if trip_element["end_time"  ].to_s =~ /^[0-9]{4}$/
    
    # TODO: Handle this in the model!
    # For FLIGHT elements we must merge the date and time field strings:
		if trip_element["type_id"].to_i == TripElementType::FLIGHT
			trip_element["start_date"] << " #{ trip_element["start_time"].strip }" unless trip_element["start_date"].blank? || trip_element["start_time"].blank?
			trip_element["end_date"]   << " #{ trip_element["end_time"].strip   }" unless trip_element["end_date"].blank?   || trip_element["end_time"].blank?
		end

    # TODO: Handle this in the model!
    # Best not to assume that date and time fields will always be set in a helpful order so REMOVE TIME ATTRIBUTES to prevent confusion:
		trip_element.delete("start_time")
		trip_element.delete("end_time")
		
		trip_element[:created_by] = session.user.login
		trip_element[:updated_by] = session.user.login

    #@element = @trip.trip_elements.new(trip_element)
    @element = TripElement.new(trip_element)

    if @element.save

			message[:notice] = "The new #{ @element.element_type.name } element has been added to your trip"

      # TODO: Unreliable! Was necessary because save does not set id of new row! See http://groups.google.com/group/datamapper/browse_thread/thread/d59fa1c381897225
      #      @element = @element.trip.trip_elements.last

      #redirect resource(@element), :message => {:notice => "TripElement was successfully created"}     
      if request.ajax?
        #render :index
      else
        #message[:notice] = "Your new Element has been added to the Trip"
        #display @element, :edit
        #display(@element, :edit)
        #redirect resource(@element.trip.context, @element.trip, :trip_elements),
        #    :message => {:notice => "TripElement was created successfully"},
        #    :ajax => true, :layout=>false
      end

    else
      message[:error] = "Could not save your new Trip Element because \n" + @element.errors.full_messages().join("\n")
      #render :new
    end

    @trip.reload
    render :index
    #redirect nested_resource( @trip, :trip_elements), :message =>message    
    #display :trip_elements, :index

  end


  def update(id, trip_element)

    @element = TripElement.get(id)
    raise NotFound unless @element

    # Fetch a reference to the trip itself:
    @trip = @element.trip || Trip.get(params[:trip_id]) || Trip.new
		
		trip_element[:updated_by] = session.user.login
		accept_valid_date_fields_for trip_element, [ :start_date, :end_date, :booking_expiry ]

    # Ensure we're not accidentally overriding dates and times etc on PNR Flights:
    if @element.bound_to_pnr?

		  trip_element.delete("supplier_id")  # Note: handler_id *can* be modified.
		  trip_element.delete("start_date")
		  trip_element.delete("start_time")
		  trip_element.delete("end_date")
		  trip_element.delete("end_time")

    # Try to tidy up start/end_date (and start/end_time) on anything other than a PNR flight element:
    else

      # TODO: Handle this in the model!
      # Some users leave out the colon from flight times so add it if necessary: (Eg '1315' => '13:15')
      trip_element["start_time"] = trip_element["start_time"].to_s.insert(2,':') if trip_element["start_time"].to_s =~ /^[0-9]{4}$/
      trip_element["end_time"  ] = trip_element["end_time"  ].to_s.insert(2,':') if trip_element["end_time"  ].to_s =~ /^[0-9]{4}$/

      # TODO: Handle this in the model!
		  # For FLIGHT elements we must merge the date and time field strings:
		  if trip_element["type_id"].to_i == TripElementType::FLIGHT
			  trip_element["start_date"] << " #{ trip_element["start_time"].strip }" unless trip_element["start_date"].blank? || trip_element["start_time"].blank?
			  trip_element["end_date"]   << " #{ trip_element["end_time"].strip   }" unless trip_element["end_date"].blank?   || trip_element["end_time"].blank?
		  end

      # TODO: Handle this in the model!
		  # Best not to assume that date and time fields will always be set in a helpful order so remove time attributes to prevent confusion:
		  trip_element.delete("start_time")
		  trip_element.delete("end_time")

    end

    puts trip_element.inspect

    @element.attributes = trip_element

    if @element.valid? && @element.save! # <-- Note use of exclamation mark !

      # Because of the number of before/after:save hooks on elements and trips we must do this manually.
      # (This fixes a bug where trips with pnrs keep reloading all elements before their attributes get saved!)
      # TODO: Find a better solution! (Also see notes in pnr.refresh_flight_elements_for)
      @trip.update_prices()
      @trip.save!
      
      message[:notice] = "The Trip Element has been updated with your changes"

      #  if request.ajax?
      #    @trip = @element.trip
      #    render :index
      #  else
      #    display @element, :edit
      #    #redirect resource(@element.trip.context, @element.trip, :elements),
      #    #    :message => {:notice => "Trip element was updated successfully"}
      #  end

    else
      message[:error] = "Trip Element could not be updated because \n #{ @element.errors.full_messages().join("\n") } #{ @trip.errors.full_messages().join("\n") }"
      #display @element, :edit
    end

    #redirect nested_resource( @element.trip, :trip_elements ), :message =>message
    @trip.reload  # To fix comments in bug 161
    render :index
    
  end
  

  def destroy(id)

    @element = TripElement.get(id)
    raise NotFound unless @element

    # Fetch a reference to the trip itself:
    @trip = @element.trip || Trip.get(params[:trip_id]) || Trip.new

    if @element.destroy

      message[:notice] = "The element has been deleted from your trip"

      #@client = Client.get( params[:client_id] ) || @element.trip.primaries.first
      
      #redirect resource(:trip_elements)      
#      if request.ajax?
#        @trip = @element.trip
#        render :index
#      else
        #redirect nested_resource( @element.trip, :trip_elements), :message =>message
#      end
  
    else
      message[:error] = "Trip Element could not be deleted \n #{ @element.errors.full_messages().join("\n") } #{ @trip.errors.full_messages().join("\n") }"
      #raise InternalServerError
    end

    @trip.reload
    render :index
    
  end

end # TripElements
