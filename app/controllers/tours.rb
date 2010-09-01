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
      message[:notice] = "Tour was created successfully"
      #redirect resource(@tour), :message => message
      render :show
    else
      message[:error] = error_messages_for @tour, :header => 'The tour could not be created because'
      render :new
    end
  end

  def update(id, tour)
    @tour = Tour.get(id)
    raise NotFound unless @tour
    if @tour.update(tour)
      message[:notice] = "Tour was updated successfully"
      #redirect resource(@tour)
      render :show
    else
      message[:error] = error_messages_for @tour, :header => 'The tour could not be updated because'
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
