class Touchdowns < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @touchdowns = Touchdown.all
    display @touchdowns
  end

  def show(id)
    @touchdown = Touchdown.get(id)
    raise NotFound unless @touchdown
    display @touchdown
  end

  def new
    only_provides :html
    @touchdown = Touchdown.new
    display @touchdown
  end

  def edit(id)
    only_provides :html
    @touchdown = Touchdown.get(id)
    raise NotFound unless @touchdown
    display @touchdown
  end

  def create(touchdown)
    @touchdown = Touchdown.new(touchdown)
    if @touchdown.save
      redirect resource(@touchdown), :message => {:notice => "Touchdown was successfully created"}
    else
      message[:error] = "Touchdown failed to be created"
      render :new
    end
  end

  def update(id, touchdown)
    @touchdown = Touchdown.get(id)
    raise NotFound unless @touchdown
    if @touchdown.update_attributes(touchdown)
       redirect resource(@touchdown)
    else
      display @touchdown, :edit
    end
  end

  def destroy(id)
    @touchdown = Touchdown.get(id)
    raise NotFound unless @touchdown
    if @touchdown.destroy
      redirect resource(:touchdowns)
    else
      raise InternalServerError
    end
  end

end # Touchdowns
