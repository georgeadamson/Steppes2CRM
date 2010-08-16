class WebRequestTypes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @web_request_types = WebRequestType.all( :order => [:is_active.desc, :name] )
    display @web_request_types
  end

  def show(id)
    @web_request_type = WebRequestType.get(id)
    raise NotFound unless @web_request_type
    display @web_request_type
  end

  def new
    only_provides :html
    @web_request_type = WebRequestType.new
    display @web_request_type
  end

  def edit(id)
    only_provides :html
    @web_request_type = WebRequestType.get(id)
    raise NotFound unless @web_request_type
    display @web_request_type
  end


	def create(web_request_type)
		generic_action_create( web_request_type, WebRequestType )
	end
  
	def update(id, web_request_type)
		generic_action_update( id, web_request_type, WebRequestType )
	end
  
	def destroy(id)
		generic_action_destroy( id, WebRequestType )
  end


end # WebRequestTypes
