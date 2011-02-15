class Divisions < Application
  # provides :xml, :yaml, :js

  def index
    @divisions = Division.all
    display @divisions
  end

  def show(id)
    @division = Division.get(id)
    raise NotFound unless @division
    display @division
  end

  def new
    only_provides :html
    @division = Division.new
    display @division
  end

  def edit(id)
    only_provides :html
    @division = Division.get(id)
    raise NotFound unless @division
    display @division
  end

  def create(division)
    @division = Division.new(division)
    if @division.save
      redirect resource(@division), :message => {:notice => "Division was successfully created"}
    else
      message[:error] = "Division failed to be created"
      render :new
    end
  end

  def update(id, division)
    @division = Division.get(id)
    raise NotFound unless @division
    if @division.update(division)
       redirect resource(@division)
    else
      display @division, :edit
    end
  end

  def destroy(id)
    @division = Division.get(id)
    raise NotFound unless @division
    if @division.destroy
      redirect resource(:divisions)
    else
      raise InternalServerError
    end
  end

end # Divisions
