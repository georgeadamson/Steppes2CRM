class TripClientStatuses < Application
  # provides :xml, :yaml, :js

  def index
    @trip_client_statuses = TripClientStatus.all
    display @trip_client_statuses
  end

  def show(id)
    @trip_client_status = TripClientStatus.get(id)
    raise NotFound unless @trip_client_status
    display @trip_client_status
  end

  def new
    only_provides :html
    @trip_client_status = TripClientStatus.new
    display @trip_client_status
  end

  def edit(id)
    only_provides :html
    @trip_client_status = TripClientStatus.get(id)
    raise NotFound unless @trip_client_status
    display @trip_client_status
  end

  def create(trip_client_status)
    @trip_client_status = TripClientStatus.new(trip_client_status)
    if @trip_client_status.save
      redirect resource(@trip_client_status), :message => {:notice => "TripClientStatus was successfully created"}
    else
      message[:error] = "TripClientStatus failed to be created"
      render :new
    end
  end

  def update(id, trip_client_status)
    @trip_client_status = TripClientStatus.get(id)
    raise NotFound unless @trip_client_status
    if @trip_client_status.update(trip_client_status)
       redirect resource(@trip_client_status)
    else
      display @trip_client_status, :edit
    end
  end

  def destroy(id)
    @trip_client_status = TripClientStatus.get(id)
    raise NotFound unless @trip_client_status
    if @trip_client_status.destroy
      redirect resource(:trip_client_statuses)
    else
      raise InternalServerError
    end
  end

end # TripClientStatuses
