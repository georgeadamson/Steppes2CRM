class TripTypes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @trip_types = TripType.all
    display @trip_types
  end

  def show(id)
    @trip_type = TripType.get(id)
    raise NotFound unless @trip_type
    display @trip_type
  end

  def new
    only_provides :html
    @trip_type = TripType.new
    display @trip_type
  end

  def edit(id)
    only_provides :html
    @trip_type = TripType.get(id)
    raise NotFound unless @trip_type
    display @trip_type
  end

  def create(trip_type)
    @trip_type = TripType.new(trip_type)
    if @trip_type.save
      redirect resource(@trip_type), :message => {:notice => "TripType was successfully created"}
    else
      message[:error] = "TripType failed to be created"
      render :new
    end
  end

  def update(id, trip_type)
    @trip_type = TripType.get(id)
    raise NotFound unless @trip_type
    if @trip_type.update_attributes(trip_type)
       redirect resource(@trip_type)
    else
      display @trip_type, :edit
    end
  end

  def destroy(id)
    @trip_type = TripType.get(id)
    raise NotFound unless @trip_type
    if @trip_type.destroy
      redirect resource(:trip_types)
    else
      raise InternalServerError
    end
  end

end # TripTypes
