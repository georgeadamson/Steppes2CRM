class TripElementExcursions < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @trip_element_excursions = TripElementExcursion.all
    display @trip_element_excursions
  end

  def show(id)
    @trip_element_excursion = TripElementExcursion.get(id)
    raise NotFound unless @trip_element_excursion
    display @trip_element_excursion
  end

  def new
    only_provides :html
    @trip_element_excursion = TripElementExcursion.new
    display @trip_element_excursion
  end

  def edit(id)
    only_provides :html
    @trip_element_excursion = TripElementExcursion.get(id)
    raise NotFound unless @trip_element_excursion
    display @trip_element_excursion
  end

  def create(trip_element_excursion)
    @trip_element_excursion = TripElementExcursion.new(trip_element_excursion)
    if @trip_element_excursion.save
      redirect resource(@trip_element_excursion), :message => {:notice => "TripElementExcursion was successfully created"}
    else
      message[:error] = "TripElementExcursion failed to be created"
      render :new
    end
  end

  def update(id, trip_element_excursion)
    @trip_element_excursion = TripElementExcursion.get(id)
    raise NotFound unless @trip_element_excursion
    if @trip_element_excursion.update_attributes(trip_element_excursion)
       redirect resource(@trip_element_excursion)
    else
      display @trip_element_excursion, :edit
    end
  end

  def destroy(id)
    @trip_element_excursion = TripElementExcursion.get(id)
    raise NotFound unless @trip_element_excursion
    if @trip_element_excursion.destroy
      redirect resource(:trip_element_excursions)
    else
      raise InternalServerError
    end
  end

end # TripElementExcursions
