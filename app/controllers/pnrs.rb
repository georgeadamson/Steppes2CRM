class Pnrs < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @pnrs = Pnr.all( :limit => 200, :order => [ :updated_at.desc, :file_date.desc, :file_name.desc ] )
    display @pnrs
  end

  def show(id)
    @pnr = Pnr.get(id)
    raise NotFound unless @pnr
    display @pnr
  end

  def new
    only_provides :html
    @pnr = Pnr.new
    display @pnr
  end

  def edit(id)
    only_provides :html
    @pnr = Pnr.get(id)
    raise NotFound unless @pnr
    display @pnr
  end

  def create(pnr)
    @pnr = Pnr.new(pnr)
    if @pnr.save
      redirect resource(@pnr), :message => {:notice => "Pnr was successfully created"}
    else
      message[:error] = "Pnr failed to be created"
      render :new
    end
  end

  def update(id, pnr)
    @pnr = Pnr.get(id)
    raise NotFound unless @pnr
    if @pnr.update(pnr)
       redirect resource(@pnr)
    else
      display @pnr, :edit
    end
  end

  def destroy(id)
    @pnr = Pnr.get(id)
    raise NotFound unless @pnr
    if @pnr.destroy
      redirect resource(:pnrs)
    else
      raise InternalServerError
    end
  end

end # Pnrs
