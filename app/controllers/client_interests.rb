class ClientInterests < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @client_interests = ClientInterest.all
    display @client_interests
  end

  def show(id)
    @client_interest = ClientInterest.get(id)
    raise NotFound unless @client_interest
    display @client_interest
  end

  def new
    only_provides :html
    @client_interest = ClientInterest.new
    display @client_interest
  end

  def edit(id)
    only_provides :html
    @client_interest = ClientInterest.get(id)
    raise NotFound unless @client_interest
    display @client_interest
  end

  def create(client_interest)
    @client_interest = ClientInterest.new(client_interest)
    if @client_interest.save
      redirect resource(@client_interest), :message => {:notice => "ClientInterest was successfully created"}
    else
      message[:error] = "ClientInterest failed to be created"
      render :new
    end
  end

  def update(id, client_interest)
    @client_interest = ClientInterest.get(id)
    raise NotFound unless @client_interest
    if @client_interest.update_attributes(client_interest)
       redirect resource(@client_interest)
    else
      display @client_interest, :edit
    end
  end

  def destroy(id)
    @client_interest = ClientInterest.get(id)
    raise NotFound unless @client_interest
    if @client_interest.destroy
      redirect resource(:client_interests)
    else
      raise InternalServerError
    end
  end

end # ClientInterests
