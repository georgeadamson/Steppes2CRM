class ReportField
  include DataMapper::Resource

  # Field property types:
  # Note: Only ATTRIBUTE fields can be used as filters (because their name matches a database field)
  ATTRIBUTE   = 1 unless defined? ATTRIBUTE   # Normal property, eg: Trip.name. Only this type can be used as filters.
  OBJECT      = 2 unless defined? OBJECT      # Relationship, eg: Trip.trip_clients
  COLLECTION  = 3 unless defined? COLLECTION  # Relationship, eg: Trip.trip_clients
  COUNT       = 4 unless defined? COUNT       # count. Special fields requiring special attention.
  AGGREGATE   = 5 unless defined? AGGREGATE   # sum, min, max, avg. Special fields requiring special attention.
  CUSTOM      = 6 unless defined? CUSTOM      # Custom method or alias, eg: Trip.title (ie can be displayed but not queried in database)
  

  property :id,               Serial
  property :report_id,        Integer,  :required => true
  property :name,             String,   :required => true,  :length  => 200   # Eg: 'amount' or 'money_in[trip][start_date]'
  property :is_active,        Boolean,  :required => true,  :default => true

  property :filter_operator,  String,   :required => false   # Important: Default to not apply filter.
  property :filter_value,     String,   :required => false

  alias show? is_active
  alias show= is_active=
  
  belongs_to :report


  def filter_value=(new_value)
    
    if new_value.is_a?(Array)
      self.attribute_set( :filter_value, new_value.join(',') )
    else
      self.attribute_set( :filter_value, new_value )
    end
      
  end

  #  def filter_value
  #    
  #    if self.attribute_get( :filter_value ) =~ /,/
  #      self.attribute_get( :filter_value ).split(',')
  #    else
  #      self.attribute_get( :filter_value )
  #    end
  #      
  #  end



  def display_name
		
    source_model  ||= self.report.source_model
    parts = tokenise_filter_field_name(source_model).unshift(source_model.name)
    
    parts.map! do |part|

      model_name = part.singularize.camel_case

      if Report.sources.include?( model_name.pluralize.snake_case.to_sym ) && 
         ( model_class = !model_name.blank? && defined?(model_name.to_sym) && Kernel.const_get(model_name) ) && 
         model_class.respond_to?(:class_display_name)
         
        if part.singularize != part
          model_class.class_display_name.pluralize
        else
          model_class.class_display_name
        end

      # Display boolean field names with a question mark:
      elsif model_name =~ /^Is[A-Z]/

        model_name + '?'

      else
        part.camel_case
      end
      
    end
    
    #return self.name.snake_case.gsub(/_|\./,' ').capitalize
    return parts.join(' ')

  end


  # Return the actual datatype of the field's property on the model:
  # Eg: "Client.name" => String, "MoneyIn.deposit" => DataMapper::Types::Boolean 
	def property_data_type
		
		# Fetch the final model and property name from the end of a field name:
		# Eg: "money_in.trip.client.name" => [ Client, "name" ]
		#model_class, prop_name = field.last_part_of_name()
    model_class, prop_name = self.last_part_of_name()
		
    #data_type = model_class.properties[prop_name].type
		#return data_type ? data_type.split(':').pop : nil
    
    return model_class.properties[prop_name].type
    
	end
  


  # Helper to tell us what type of thing will be returned by the filter property:
  attr_reader :property_type
  def property_type

    # Discard cached property_type if field name has been changed recently:
    @property_type = nil  if self.attribute_dirty?(:name)
    return @property_type if @property_type
    
    # Fetch the final model and property name from the end of a field name:
    # Eg: "money_in.trip.client.name" => [ Client, "name" ]
    model_class, prop_name, model_name = self.last_part_of_name()

    if model_class && prop_name

      props = model_class.properties
      rels  = model_class.relationships

      @property_type ||= case

        # Eg: Trip.price_per_adult
        when props && props[prop_name]
          then ATTRIBUTE

        # Eg: Client.trips.count (an alias)
        when prop_name == 'count'
          then COUNT

        # Eg: Trip.elements.sum.total_price (an alias)
        when model_name =~ /sum|avg|min|max/
          then AGGREGATE

        # Eg: Trip.user
        when rels && ( rels[prop_name].is_a?( DataMapper::Associations::OneToOne::Relationship   ) ||
                       rels[prop_name].is_a?( DataMapper::Associations::ManyToOne::Relationship  ) )
          then OBJECT

        # Eg: Trip.trip_clients or Trip.clients
        when rels && ( rels[prop_name].is_a?( DataMapper::Associations::OneToMany::Relationship  ) ||
                       rels[prop_name].is_a?( DataMapper::Associations::ManyToMany::Relationship ) )
          then COLLECTION

        # Eg: Trip.title (a custom method) or Trip.elements (an alias)
        when model_class.instance_methods.include?( prop_name.to_s )
          then CUSTOM
          
      end

    end
    
    return @property_type ||= nil

  end


  # Helper to fetch the final model and property name from the end of a field name:
  # Eg: "money_in.trip.client.name" => [ Client, "name" ]
  def last_part_of_name( parts = nil, source_model = nil )

    source_model  ||= self.report.source_model
    parts         ||= tokenise_filter_field_name(source_model).unshift(source_model.name)
    
    prop_name   = parts.pop
    model_name  = parts.pop.singularize.camel_case

    if model_name.blank?
      # Eg: ["name"] => source_model
      model_class = source_model

    elsif model_class = is_model?(model_name)
      # Yay we found it.
      # Eg: ["Trip", "name"] => Trip

    elsif ( preceeding_class = is_model?(parts.pop) ) && preceeding_class.relationships[model_name.snake_case]
      # See if we can derive model from property of preceeding model:
      # Eg: ["Trip", "status", "name"] => TripState
      model_class = preceeding_class.send(model_name.snake_case).model
    
    end
        
    # Important: The values returned in the array are expected in a specific order: (model_class,property_name)
    return [
      model_class ||= nil,
      prop_name,
      model_name
    ]

  end

  # Return the model Class if it exists:
  # Much safer than Kernel.const_get(model_name)
  def is_model?(model_name)
    !model_name.blank? && DataMapper::Model.descendants.select{|klass| klass.name == model_name.singularize.camel_case }.first
  end


  # Separate nested field names into an array: Eg: 'money_in[trip][client][name]' =>  ["money_in", "trip", "client", "name"]
  # (Allows for fields separated either with a dot or enclosed in square brackets)
  # Discard first field if it is simply referring to this report's source class: Eg: ["money_in", "trip"] => ["trip"]
  def tokenise_filter_field_name( source_model = nil )
    source_model  ||= self.report.source_model
    fields          = self.name.sub(/\]$/,'').split(/\]\[|\[|\./)
    fields.shift    if fields.first.to_s.singularize.camel_case == source_model.to_s
    return fields
  end


  # Prepare a DATAMAPPER FILTER PATH from field name:
  # Eg: self.name = "trip[trip_clients][client][name]" => Trip.trip_clients.client.name
  # When combined with operator and value the report can do { Trip.trip_clients.client.name.like => 'armit%' }
  def filter_path
    
    # Separate nested field names into an array: Eg: 'money_in[trip][client][name]' =>  ["money_in", "trip", "client", "name"]
    source_model  ||= self.report.source_model
    fields          = tokenise_filter_field_name(source_model)

    # Build simple property path: (Eg: :amount)
    if fields.length == 1
      
      path = fields.first.to_sym
    
    # Or a more complex path: (Eg: MoneyIn.trip.trip_clients.client.client_addresses.address.postcode)
    elsif fields.length > 1
      
      # Begin with class: (Eg: MoneyIn)
      path = source_model
      
      # Then build up the method calls: (Using a loop to RECURSE)
      fields.each do |field|
        begin
          path = path.send(field.to_sym)                                # Using send() to avoid undefined method error.
        rescue
          # Sometimes a field is not available on the model:
          return nil
        end
      end
      
    end
    
    return path ||= nil
    
  end
  

  # Derive filter condition syntax from filter path, operator and value: Eg: { Client.name.like => 'smith%' }
  def filter_condition

    # Bail out if we cannot derive filter_path:
    return {} unless ( filter_path = self.filter_path() )
    
    operator = self.filter_operator
    value    = self.filter_value

    # Convert '*' wildcards to '%' and add wildcards when none provided:
    if operator == 'like'

      # Ensure empty filter values don't accidentally filter out all results:
      return {} if value.blank?

      value.gsub!('*','%')
      value = "%#{ value }%" if value !~ /(\%|\?)/

    # Change custom begins operator to like. Convert '*' wildcards to '%' and add wildcard suffix:
    elsif operator == 'begins'

      value    = "#{ value.gsub!('*','%') }%"
      operator = 'like'

    # Change custom begins operator to like. Convert custom '*' wildcards to '%' and add wildcard prefix:
    elsif operator == 'ends'

      value    = "%#{ value.gsub!('*','%') }"
      operator = 'like'

    # Change custom nil operator to .eql => nil
    elsif operator == 'nil'

      value    = nil
      operator = 'eql'

    # Change custom true/false operator to ".eql => 1" and ".eql => 0"
    elsif operator == 'true' || operator == 'false'

      value    = ( operator == 'true' ) ? 1 : 0
      operator = 'eql'

    # Change custom not.nil operator to not.eql => nil
    elsif operator == 'not.nil'

      value    = nil
      operator = 'not'

    # Depricated? Allow boolean filter-values to be expressed as yes, no, true, false, on, off, 1, 0 etc:
    elsif property_data_type == DataMapper::Types::Boolean

      value = ( value =~ /true|yes|on|1/i  || value.to_i != 0 ) ? 1 : 0

    # Change comma separated values to an array of values:
    # TODO: Seems hacky. Is there a better way?!
    elsif value =~ /,/

      value = value.split(',')

    end

    # Append filter_operator to the end of the filter_path (Using send() to avoid undefined method error)
    # Unfortnately "explicit use of eql operator is deprecated" so we have to exclude it explicitly instead:
    # Otherwise we could have used: operator = filter.filter_operator.to_s.strip.gsub( /^\=?$/, 'eql' )
    #filter_path = self.filter_path().send( operator ) unless operator.blank? || operator == 'eql' || operator == '='   
    #filter_path = self.filter_path().send( operator ) unless ['eql','=','',nil].include?(operator)
    filter_path = self.filter_path().send( operator ) unless ( operator || '') =~ /^(eql|=|\s*)$/

    # Define query syntax for the filter: Eg: { :amount.gte => 100 } or { Trip.trip_clients.client.name.like => 'smith%' }
    return { filter_path => value }

  end


end


# ReportField.auto_migrate!		# Warning: Running this will clear the table!