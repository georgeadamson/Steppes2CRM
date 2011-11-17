class Countries < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @countries = Country.all( :order=>[:name] )
    display @countries
  end

  def show(id)
    @country = Country.get(id)
    raise NotFound unless @country
    display @country
  end

  def new
    only_provides :html
    @country = Country.new
    # @country.articles.new #"Unsaved Parent Error - You cannot intialize until the parent is saved"
    display @country
  end

  def edit(id)
    only_provides :html
    @country = Country.get(id)
    # @article
    @worldRegions = WorldRegion.all
    raise NotFound unless @country
    display @country
  end

  def create(country)
		generic_action_create( country, Country, :collect_errors_for => [:companies] )
  end

  def update(id, country)
		generic_action_update( id, country, Country, :collect_errors_for => [:companies] )
  end

  def destroy(id)
		generic_action_destroy( id, Country )
  end

end # Countries
