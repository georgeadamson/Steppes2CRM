class ClientMarketings < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @client_marketings = ClientMarketing.all
    display @client_marketings
  end

  def show(id)
    @client_marketing = ClientMarketing.get(id)
    raise NotFound unless @client_marketing
    display @client_marketing
  end

  def new
    only_provides :html
    @client_marketing = ClientMarketing.new
    display @client_marketing
  end

  def edit(id)
    only_provides :html
    @client_marketing = ClientMarketing.get(id)
    raise NotFound unless @client_marketing
    display @client_marketing
  end

  def create(client_marketing)
    @client_marketing = ClientMarketing.new(client_marketing)
    if @client_marketing.save
      redirect resource(@client_marketing), :message => {:notice => "ClientMarketing was successfully created"}
    else
      message[:error] = "ClientMarketing failed to be created"
      render :new
    end
  end

  def update(id, client_marketing)
    @client_marketing = ClientMarketing.get(id)
    raise NotFound unless @client_marketing
    if @client_marketing.update_attributes(client_marketing)
       redirect resource(@client_marketing)
    else
      display @client_marketing, :edit
    end
  end

  def destroy(id)
    @client_marketing = ClientMarketing.get(id)
    raise NotFound unless @client_marketing
    if @client_marketing.destroy
      redirect resource(:client_marketings)
    else
      raise InternalServerError
    end
  end

end # ClientMarketings
