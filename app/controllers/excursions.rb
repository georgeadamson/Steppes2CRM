class Excursions < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @excursions = Excursion.all
    display @excursions
  end

  def show(id)
    @excursion = Excursion.get(id)
    raise NotFound unless @excursion
    display @excursion
  end

  def new
    only_provides :html
    @excursion = Excursion.new
    display @excursion
  end

  def edit(id)
    only_provides :html
    @excursion = Excursion.get(id)
    raise NotFound unless @excursion
    display @excursion
  end

  def create(excursion)
    @excursion = Excursion.new(excursion)
    if @excursion.save
      redirect resource(@excursion), :message => {:notice => "Excursion was successfully created"}
    else
      message[:error] = "Excursion failed to be created"
      render :new
    end
  end

  def update(id, excursion)
    @excursion = Excursion.get(id)
    raise NotFound unless @excursion
    if @excursion.update_attributes(excursion)
       redirect resource(@excursion)
    else
      display @excursion, :edit
    end
  end

  def destroy(id)
    @excursion = Excursion.get(id)
    raise NotFound unless @excursion
    if @excursion.destroy
      redirect resource(:excursions)
    else
      raise InternalServerError
    end
  end

end # Excursions
