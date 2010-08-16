class Tours < Application
  # provides :xml, :yaml, :js

  def index
    @tours = Tour.all
    display @tours
  end

  def show(id)
    @tour = Tour.get(id)
    raise NotFound unless @tour
    display @tour
  end

  def new
    only_provides :html
    @tour = Tour.new
    display @tour
  end

  def edit(id)
    only_provides :html
    @tour = Tour.get(id)
    raise NotFound unless @tour
    display @tour
  end

  def create(tour)
    @tour = Tour.new(tour)
    if @tour.save
      redirect resource(@tour), :message => {:notice => "Tour was successfully created"}
    else
      message[:error] = "Tour failed to be created"
      render :new
    end
  end

  def update(id, tour)
    @tour = Tour.get(id)
    raise NotFound unless @tour
    if @tour.update(tour)
       redirect resource(@tour)
    else
      display @tour, :edit
    end
  end

  def destroy(id)
    @tour = Tour.get(id)
    raise NotFound unless @tour
    if @tour.destroy
      redirect resource(:tours)
    else
      raise InternalServerError
    end
  end

end # Tours
