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
    generic_action_create( client_source, ClientSource )
  end

  def update(id, client_source)
    generic_action_update( id, client_source, ClientSource )
  end

  def destroy(id)
    generic_action_destroy( id, ClientSource )
  end

end # ClientSources
