class Companies < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @companies = Company.all( :order => [ :is_active.desc, :name ] )
    display @companies
  end

  def show(id)
    @company = Company.get(id)
    raise NotFound unless @company
    display @company
  end

  def new
    only_provides :html
    @company = Company.new
    display @company
  end

  def edit(id)
    only_provides :html
    @company = Company.get(id)
    raise NotFound unless @company
    display @company
  end

  def create(company)
    generic_action_create( company, Company )
  end

  def update(id, company)
    generic_action_update( id, company, Company )
  end

  def destroy(id)
    generic_action_destroy( id, Company )
  end

end # Companies
