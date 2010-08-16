class WorldRegions < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
	
  def index
    @world_regions = WorldRegion.all( :order => [:name] )
    display @world_regions
  end

  def show(id)
    @world_region = WorldRegion.get(id)
    raise NotFound unless @world_region
    display @world_region
  end

  def new
    only_provides :html
    @world_region = WorldRegion.new
    display @world_region
  end

  def edit(id)
    only_provides :html
    @world_region = WorldRegion.get(id)
    raise NotFound unless @world_region
    display @world_region
  end

  def create(world_region)
		generic_action_create( world_region, WorldRegion )
  end

  def update(id, world_region)
		generic_action_update( id, world_region, WorldRegion )
  end

  def destroy(id)
		generic_action_destroy( id, WorldRegion )
  end

end # WorldRegions
