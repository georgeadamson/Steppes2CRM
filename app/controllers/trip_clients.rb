class TripClients < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @trip_clients = TripClient.all
    display @trip_clients
  end

  def show(id)
    @trip_client = TripClient.get(id)
    raise NotFound unless @trip_client
    display @trip_client
  end

  def new
    only_provides :html
    @trip_client = TripClient.new
    display @trip_client
  end

  def edit(id)
    only_provides :html
    @trip_client = TripClient.get(id)
    raise NotFound unless @trip_client
    display @trip_client
  end

  def create(trip_client)
    @trip_client = TripClient.new(trip_client)
    if @trip_client.save
      redirect resource(@trip_client), :message => {:notice => "TripClient was successfully created"}
    else
      message[:error] = "TripClient failed to be created"
      render :new
    end
  end

  def update(id, trip_client)
    @trip_client = TripClient.get(id)
    raise NotFound unless @trip_client
    if @trip_client.update_attributes(trip_client)
       redirect resource(@trip_client)
    else
      display @trip_client, :edit
    end
  end

  def destroy(id)
    @trip_client = TripClient.get(id)
    raise NotFound unless @trip_client
    if @trip_client.destroy
      redirect resource(:trip_clients)
    else
      raise InternalServerError
    end
  end

end # TripClients
