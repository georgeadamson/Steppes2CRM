class Addresses < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @addresses = Address.all
    display @addresses
  end

  def show(id)
    @address = Address.get(id)
    raise NotFound unless @address
    display @address
  end

  def new
    only_provides :html
    @address = Address.new
    display @address
  end

  def edit(id)
    only_provides :html
    @address = Address.get(id)
    raise NotFound unless @address
    display @address
  end

  def create(address)
    @address = Address.new(address)
    if @address.save
      redirect resource(@address), :message => {:notice => "Address was successfully created"}
    else
      message[:error] = "Address failed to be created"
      render :new
    end
  end

  def update(id, address)
    @address = Address.get(id)
    raise NotFound unless @address
    if @address.update(address)
       redirect resource(@address)
    else
      display @address, :edit
    end
  end

  def destroy(id)
    @address = Address.get(id)
    raise NotFound unless @address
    if @address.destroy
      redirect resource(:addresses)
    else
      raise InternalServerError
    end
  end

end # Addresses
