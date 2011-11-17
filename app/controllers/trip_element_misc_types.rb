class TripElementMiscTypes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @trip_element_misc_types = TripElementMiscType.all( :order => [:name] )
    display @trip_element_misc_types
  end

  def show(id)
    @trip_element_misc_type = TripElementMiscType.get(id)
    raise NotFound unless @trip_element_misc_type
    display @trip_element_misc_type
  end

  def new
    only_provides :html
    @trip_element_misc_type = TripElementMiscType.new( :default_margin => "#{ CRM[:default_margin] || 24 }%" )
    display @trip_element_misc_type
  end

  def edit(id)
    only_provides :html
    @trip_element_misc_type = TripElementMiscType.get(id)
    raise NotFound unless @trip_element_misc_type
    display @trip_element_misc_type
  end

  def create(trip_element_misc_type)
    generic_action_create( trip_element_misc_type, TripElementMiscType )
  end

  def update(id, trip_element_misc_type)
    generic_action_update( id, trip_element_misc_type, TripElementMiscType )
  end

  def destroy(id)
    generic_action_destroy( id, TripElementMiscType )
  end


end # TripElementMiscTypes
