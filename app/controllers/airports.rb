class Airports < Application
  # provides :xml, :yaml, :js
  provides :html, :json

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @airports = Airport.all( :order => [:name] )
    display @airports
  end

  def show(id)
    @airport = Airport.get(id)
    raise NotFound unless @airport
    display @airport
  end

  def new
    only_provides :html
    @airport = Airport.new
    display @airport
  end

  def edit(id)
    only_provides :html
    @airport = Airport.get(id)
    raise NotFound unless @airport
    display @airport
  end

  def create(airport)
    generic_action_create( airport, Airport )
  end

  def update(id, airport)
    generic_action_update( id, airport, Airport )
  end

  def destroy(id)
    generic_action_destroy( id, Airport )
  end

end # Airports
