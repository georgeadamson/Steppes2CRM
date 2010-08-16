class WebRequestStatuses < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @web_request_statuses = WebRequestStatus.all
    display @web_request_statuses
  end

  def show(id)
    @web_request_status = WebRequestStatus.get(id)
    raise NotFound unless @web_request_status
    display @web_request_status
  end

  def new
    only_provides :html
    @web_request_status = WebRequestStatus.new
    display @web_request_status
  end

  def edit(id)
    only_provides :html
    @web_request_status = WebRequestStatus.get(id)
    raise NotFound unless @web_request_status
    display @web_request_status
  end

  def create(web_request_status)
    @web_request_status = WebRequestStatus.new(web_request_status)
    if @web_request_status.save
      redirect resource(@web_request_status), :message => {:notice => "WebRequestStatus was successfully created"}
    else
      message[:error] = "WebRequestStatus failed to be created"
      render :new
    end
  end

  def update(id, web_request_status)
    @web_request_status = WebRequestStatus.get(id)
    raise NotFound unless @web_request_status
    if @web_request_status.update(web_request_status)
       redirect resource(@web_request_status)
    else
      display @web_request_status, :edit
    end
  end

  def destroy(id)
    @web_request_status = WebRequestStatus.get(id)
    raise NotFound unless @web_request_status
    if @web_request_status.destroy
      redirect resource(:web_request_statuses)
    else
      raise InternalServerError
    end
  end

end # WebRequestStatuses
