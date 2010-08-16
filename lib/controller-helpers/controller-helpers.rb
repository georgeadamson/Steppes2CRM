
# Helpers called by controller actions to provide common functionality.


# Generic handler for controller 'create' action:
def generic_action_create( attrs, model_class, opts = {} )
	
	model					= model_class.name.snake_case.to_sym				# Eg: :world_region
	controller		= model_class.name.plural.snake_case.to_sym	# Eg: :world_regions
	collection		= "@#{ controller }"												# Eg: '@world_regions'
	
	item_label	= model.to_s.gsub('_',' ')									# Eg: 'world region'
	items_label	= controller.to_s.gsub('_',' ')							# Eg: 'world regions'
	
	@obj = model_class.new(attrs)
	
	if @obj.save
		
		message[:notice] = "New #{ item_label.capitalize } was added successfully"
		
		if request.ajax?
			# Eg: @world_regions = WorldRegion.all( :order => [:name] )
			self.instance_variable_set collection, model_class.all( :order => [:name] )
			render :index
		else
			# Eg: redirect resource(:world_regions), :message => message
			redirect resource(controller), :message => message
		end
		
	else

		opts[:collect_errors_for].each{ |association_name| collect_error_messages_for @obj, association_name } if opts[:collect_errors_for]

		message[:error] = error_messages_for( @obj, :header => "The new #{ item_label.capitalize } could not be saved because" )

		render :new

end
	
end


# Generic handler for controller 'update' action:
def generic_action_update( id, attrs, model_class, opts = {} )
	
	model					= model_class.name.snake_case.to_sym				# Eg: :world_region
	controller		= model_class.name.plural.snake_case.to_sym	# Eg: :world_regions
	collection		= "@#{ controller }"												# Eg: '@world_regions'
	
	item_label	  = model.to_s.gsub('_',' ')									# Eg: 'world region'
	items_label	  = controller.to_s.gsub('_',' ')							# Eg: 'world regions'
	
	
	@obj = model_class.get(id)
	raise NotFound unless @obj
	
	if @obj.update(attrs)
		
		message[:notice] = "#{ item_label.capitalize } details were updated successfully"
		
		if request.ajax?
			# Eg: @world_regions = WorldRegion.all( :order => [:name] )
			self.instance_variable_set collection, model_class.all( :order => [:name] )
			render :index
		else
			# Eg: redirect resource(:world_regions), :message => message
			redirect resource(controller), :message => message
		end
		
	else
    
		opts[:collect_errors_for].each{ |association_name| collect_error_messages_for @obj, association_name } if opts[:collect_errors_for]
  	
  	message[:error] = error_messages_for( @obj, :header => "The #{ item_label } details could not be saved because:" )
		
		display @obj, :edit
	end
	
end


# Generic handler for controller 'destroy' action:
def generic_action_destroy( id, model_class )
	
	model					= model_class.name.snake_case.to_sym				# Eg: :world_region
	controller		= model_class.name.plural.snake_case.to_sym	# Eg: :world_regions
	collection		= "@#{ controller }"												# Eg: '@world_regions'
	
	item_label	= model.to_s.gsub('_',' ')									# Eg: 'world region'
	items_label	= controller.to_s.gsub('_',' ')							# Eg: 'world regions'
	
	@obj = model_class.get(id)
	raise NotFound unless @obj
	
  begin

	  if @obj.destroy
  		
		  message[:notice] = "The #{ item_label } '#{ @obj.name }' has been deleted"
  		
		  if request.ajax?
			  # Eg: @world_regions = WorldRegion.all( :order => [:name] )
			  self.instance_variable_set collection, model_class.all( :order => [:name] )
			  render :index
		  else
			  # Eg: redirect resource(:world_regions), :message => message
			  redirect resource(controller), :message => message
		  end
  		
	  else
		  raise InternalServerError
    end
	
  rescue
		message[:notice] = "Hold your horses, the #{ item_label } '#{ @obj.name }' cannot be deleted because other things rely on it"
		display @obj, :edit
  end

end
