class Titles < Application
  # provides :xml, :yaml, :js
	
	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
	
  def index
    @titles = Title.all
    display @titles
  end

  def show(id)
    @title = Title.get(id)
    raise NotFound unless @title
    display @title
  end

  def new
    only_provides :html
    @title = Title.new
    display @title
  end

  def edit(id)
    only_provides :html
    @title = Title.get(id)
    raise NotFound unless @title
    display @title
  end

	def create(title)
		generic_action_create( title, Title )
	end

	def update(id, title)
		generic_action_update( id, title, Title )
	end

	def destroy(id)
		generic_action_destroy( id, Title )
	end

end # Titles
