class TripPackages < Application
  # provides :xml, :yaml, :js
	
  # Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @trip_packages = TripPackage.all
    display @trip_packages
  end

  def show(id)
    @trip_package = TripPackage.get(id)
    raise NotFound unless @trip_package
    display @trip_package
  end

  def new
    only_provides :html
    @trip_package = TripPackage.new
    display @trip_package
  end

  def edit(id)
    only_provides :html
    @trip_package = TripPackage.get(id)
    raise NotFound unless @trip_package
    display @trip_package
  end

  def create(trip_package)
    @trip_package = TripPackage.new(trip_package)
    if @trip_package.save
      redirect resource(@trip_package), :message => {:notice => "TripPackage was successfully created"}
    else
      message[:error] = "TripPackage failed to be created"
      render :new
    end
  end

  def update(id, trip_package)
    @trip_package = TripPackage.get(id)
    raise NotFound unless @trip_package
    if @trip_package.update_attributes(trip_package)
       redirect resource(@trip_package)
    else
      display @trip_package, :edit
    end
  end

  def destroy(id)
    @trip_package = TripPackage.get(id)
    raise NotFound unless @trip_package
    if @trip_package.destroy
      redirect resource(:trip_packages)
    else
      raise InternalServerError
    end
  end

end # TripPackages
