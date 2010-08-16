class TripElementTypes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @trip_element_types = TripElementType.all
    display @trip_element_types
  end

  def show(id)
    @trip_element_type = TripElementType.get(id)
    raise NotFound unless @trip_element_type
    display @trip_element_type
  end

  def new
    only_provides :html
    @trip_element_type = TripElementType.new
    display @trip_element_type
  end

  def edit(id)
    only_provides :html
    @trip_element_type = TripElementType.get(id)
    raise NotFound unless @trip_element_type
    display @trip_element_type
  end

  def create(trip_element_type)
    @trip_element_type = TripElementType.new(trip_element_type)
    if @trip_element_type.save
      redirect resource(@trip_element_type), :message => {:notice => "TripElementType was successfully created"}
    else
      message[:error] = "TripElementType failed to be created"
      render :new
    end
  end

  def update(id, trip_element_type)
    @trip_element_type = TripElementType.get(id)
    raise NotFound unless @trip_element_type
    if @trip_element_type.update_attributes(trip_element_type)
       redirect resource(@trip_element_type)
    else
      display @trip_element_type, :edit
    end
  end

  def destroy(id)
    @trip_element_type = TripElementType.get(id)
    raise NotFound unless @trip_element_type
    if @trip_element_type.destroy
      redirect resource(:trip_element_types)
    else
      raise InternalServerError
    end
  end

end # TripElementTypes
