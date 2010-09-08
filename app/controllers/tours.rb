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
      message[:notice] = "Group was created successfully"
      #redirect resource(@tour), :message => message
      render :show
    else
      message[:error] = error_messages_for @tour, :header => 'The Group could not be created because'
      render :new
    end
  end

  def update(id, tour)
    @tour = Tour.get(id)
    raise NotFound unless @tour
    if @tour.update(tour)
      message[:notice] = "Group was updated successfully"
      #redirect resource(@tour)
      render :show
    else
      message[:error] = error_messages_for @tour, :header => 'The Group could not be updated because'
      display @tour, :edit
    end
  end

  def destroy(id)
    @tour = Tour.get(id)
    raise NotFound unless @tour
    if @tour.trips.count > 0
      message[:error] = 'Ah, now, the thing is, this Group cannot be deleted because it has trips associated with it'
      display @tour, :show
    elsif @tour.destroy
      message[:notice] = "The Group has been deleted"
      redirect resource(:tours), :message => message
    else
      message[:error] = error_messages_for @tour, :header => 'The Group could not be created because'
      raise InternalServerError
    end
  end

end # Tours
