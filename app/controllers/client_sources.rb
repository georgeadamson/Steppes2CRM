class ClientSources < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @client_sources = ClientSource.all
    display @client_sources
  end

  def show(id)
    @client_source = ClientSource.get(id)
    raise NotFound unless @client_source
    display @client_source
  end

  def new
    only_provides :html
    @client_source = ClientSource.new
    display @client_source
  end

  def edit(id)
    only_provides :html
    @client_source = ClientSource.get(id)
    raise NotFound unless @client_source
    display @client_source
  end

  def create(client_source)
    @client_source = ClientSource.new(client_source)
    if @client_source.save
      redirect resource(@client_source), :message => {:notice => "ClientSource was successfully created"}
    else
      message[:error] = "ClientSource failed to be created"
      render :new
    end
  end

  def update(id, client_source)
    @client_source = ClientSource.get(id)
    raise NotFound unless @client_source
    if @client_source.update_attributes(client_source)
       redirect resource(@client_source)
    else
      display @client_source, :edit
    end
  end

  def destroy(id)
    @client_source = ClientSource.get(id)
    raise NotFound unless @client_source
    if @client_source.destroy
      redirect resource(:client_sources)
    else
      raise InternalServerError
    end
  end

end # ClientSources
