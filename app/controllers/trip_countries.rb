class TripCountries < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @trip_countries = TripCountry.all
    display @trip_countries
  end

  def show(id)
    @trip_country = TripCountry.get(id)
    raise NotFound unless @trip_country
    display @trip_country
  end

  def new
    only_provides :html
    @trip_country = TripCountry.new
    display @trip_country
  end

  def edit(id)
    only_provides :html
    @trip_country = TripCountry.get(id)
    raise NotFound unless @trip_country
    display @trip_country
  end

  def create(trip_country)
    @trip_country = TripCountry.new(trip_country)
    if @trip_country.save
      redirect resource(@trip_country), :message => {:notice => "TripCountry was successfully created"}
    else
      message[:error] = "TripCountry failed to be created"
      render :new
    end
  end

  def update(id, trip_country)
    @trip_country = TripCountry.get(id)
    raise NotFound unless @trip_country
    if @trip_country.update_attributes(trip_country)
       redirect resource(@trip_country)
    else
      display @trip_country, :edit
    end
  end

  def destroy(id)
    @trip_country = TripCountry.get(id)
    raise NotFound unless @trip_country
    if @trip_country.destroy
      redirect resource(:trip_countries)
    else
      raise InternalServerError
    end
  end

end # TripCountries
