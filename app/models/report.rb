class Report
  include DataMapper::Resource
  
  property :id, Serial
  
  property :name,         String,   :required => true,  :default => 'A report with no title'
  property :description,  String,   :required => true,  :default => 'This report has no description'
  
  property :source,       String,   :required => true,  :default => MoneyIn.to_s  # Every report must be based on something.
  property :sort_by,      String,   :required => true,  :default => 'name'
  property :limit,        Integer,  :required => true,  :default => 500
  
  has n, :report_fields,  :filter_operator      => nil  #, :constraint => :destroy
  has n, :report_filters, :filter_operator.not  => nil, :model => 'ReportField'
  alias columns report_fields
  alias filters report_filters
  
  # report.report_fields_attributes=()
  accepts_nested_attributes_for :report_fields,   :allow_destroy => true
  accepts_nested_attributes_for :report_filters,  :allow_destroy => true
  
  before :destroy do
    self.report_fields.destroy!
    self.report_filters.destroy!
  end


#  # report.report_filters_attributes=()
#  # This is a custom version of what dm-accepts_nested_attributes does:
#  # It can only be called *AFTER* report_fields_attributes=() to set additional filter attributes on fields.
#  def report_filters_attributes=( attributes_collection = {} )
#
#puts "SETTING report_filters_attributes= !!!"
#
#    # normalize_attributes_collection:
#    if attributes_collection.is_a?(Hash)
#      attributes_collection   = attributes_collection.map{ |i,attributes| attributes }
#    else
#      attributes_collection ||= []
#    end
#    
#    # assign_nested_attributes_for_related_collection:
#    attributes_collection.each do |attributes|
#      
#puts attributes.inspect
#
#      # Discard the filter attributes if _delete flag is set: 
#      if delete = attributes.delete('_delete')
#puts 'deleting filter'
#        attributes.merge!( :filter_operator => nil, :filter_value => nil )
#      end
#
#      # Update field attributes using id:
#      if !attributes[:id].blank?
#
#puts 'apply attributes by id'
#        if existing_field = self.report_fields.get(attributes[:id])
#puts ' applying attributes by id'
#          existing_field.attributes = attributes
#        end
#
##      # Update field attributes using name:
##      # Important: This makes a valiant attempt to find an existing UNSAVED filter by name too.
##      # Without this, filters might be added again if they were previously added using report_fields_attributes and not saved yet!
##      elsif !attributes[:name].blank? &&
##            existing_field = ( self.report_fields.first(       :name => attributes[:name] ) ) #||
##                               #self.report_fields.select{ |f| f.name == attributes[:name] }.first )
##
##puts 'apply attributes by name'
##        existing_field.attributes = attributes
#
#      # Otherwise create new field object: (Unless _delete flag was set)
#      elsif !delete
#
#puts 'apply new filter attributes'
#        self.report_fields.new( attributes.except([:id,:_delete]) )
#
#      end
#
#    end
#
#  end
  

  
  # Override default setter for source attribute to clear the report_fields whenever source changes:
  def source=(new_value)

    old_value = self.attribute_get(:source)
    self.attribute_set(:source, new_value)
    
    # Discard filters if source has changed:
    self.report_fields.clear if self.attribute_get(:source) != old_value

  end




  # Return the source Model class instead of just it's name: (Eg 'MoneyIn' => MoneyIn class )
  # (Tried overriding the source attribute instead but it does not seem to work)
  def source_model( src = nil )
    src ||= attribute_get(:source)
    return Kernel.const_get src.to_s.singularize.camel_case
  end
  
  
  
  # Apply the filters and run the report:
  # Return an array of row-hashes:
  # Important: Instead of merging all the conditions into one hash and calling self.source_model.all(conditions) once,
  # we add each condition one by one: This allows us to apply more than one filter value per field when necessary.
  def run( aggregate = false, sum_field = nil )
    
    default_conditions = { :limit => self.limit }
    filtered_results   = self.source_model.all(default_conditions)

    # Apply each condition one by one so that more than one filter can be applied to each field: 
    self.filter_conditions.each do |condition|
      filtered_results = filtered_results.all(condition)
    end

    if aggregate == :count
      filtered_results.count
    elsif aggregate == :sum && sum_field.blank?
      nil
    elsif aggregate == :sum
      filtered_results.sum sum_field.to_sym
    else    
      build_rows_for filtered_results
    end

  end
  

  # Get all the field values from all the rows (objects) in the collection:
  # As an array of row-hashes:
  def build_rows_for( collection )

    rows = []
    
    collection.each do |obj|
      rows << build_row_for(obj)
    end

    return rows

  end


  # Get all the report_field values from the object representing the current row: 
  # As a hash of { fieldname => value } pairs:
  def build_row_for(obj)

    row = {}

    self.report_fields.each do |field|
      row.merge! get_field_value_for(obj,field)
    end

    return row

  end


  # Return a simple { fieldname => value } hash to represent the field value:
  def get_field_value_for(obj,field)

    begin

      path  = field.tokenise_filter_field_name()
      value = { field.name => walk_path_to_value( obj, path ) }
      #puts value.inspect

    rescue

      # Sometimes the path is invalid and cannot be processed:
      return {}

    end

    return value

  end


  def walk_path_to_value( obj, parts )

    if parts.length > 1
      
      # RECURSE further if necessary:
      name      = parts.shift
      next_obj  = obj.send(name)
      return walk_path_to_value( next_obj, parts ) if next_obj
      
    else
      
      begin
        # Otherwise return the value from the named property:
        return obj.send(parts.last) if obj
      rescue
        return 'oops'
      end

    end

  end

  
  # Collect conditions from each filter as one big hash ready to use as a query condition:
  def filter_conditions
    
    #conditions = {}
    conditions = []
    
    # Build up query syntax for each filter: Eg: { :amount.gte => 100 } and { MoneyIn.trip.name.like => '%honeymoon%' }
    self.filters.each do |filter|
      puts "!!! Merging filter: #{filter.filter_condition}"
      #conditions.merge! filter.filter_condition #unless filter.filter_operator.nil?
      conditions << filter.filter_condition #unless filter.filter_operator.nil?
    end
    
    return conditions
    
  end
  
  
  
  def deleted_filters
    return @destroyables || []
  end
  
  
  # Array of possible field objects available for this report to use: (Based on chosen source_model.potential_report_fields)
  # This also iterates through related models to derive nested paths, so it actually does a lot of work!
  # We avoid recursing too far by checking whether the model name is already in the nested_path.
  # Eg: If MoneyIn.potential_report_fields includes :trip then we derive filters for MoneyIn.trip.name and MoneyIn.trip.trip_clients.client and so on.
  def potential_fields( nested_path = [], source_model = nil )
    
    # Get a reference to the model class that is providing the fields:
    source_model  ||= self.source_model
    nested_path     = [source_model.name] if nested_path.blank?
    fields          = []
    
    # Most models that we use in reporting will have a list of available report fields defined:
    named_fields = source_model.respond_to?(:potential_report_fields) ? source_model.potential_report_fields : [:name]
    
    named_fields.each do |name|
      
      # Eg: 'MoneyIn.amount'
      nested_name = ( nested_path + [name] ).join('.')
      field       = self.report_fields.new( :name => nested_name )
      # puts "#{ field.name }, #{ field.property_type }"

      if field.property_type == ReportField::ATTRIBUTE || field.property_type == ReportField::CUSTOM
        fields << field

      elsif field.property_type == ReportField::OBJECT && !nested_path.include?(name)     # Avoid recursion!
        preceeding_model  = Kernel.const_get nested_path.last.to_s.singularize.camel_case
        nested_model      = preceeding_model.relationships[name].parent_model || Kernel.const_get( name.to_s.singularize.camel_case )
        #nested_model      = Kernel.const_get name.to_s.singularize.camel_case
        fields.concat potential_fields( nested_path + [name], nested_model )

      elsif field.property_type == ReportField::COLLECTION && !nested_path.include?(name) # Avoid recursion!

        nested_model = Kernel.const_get name.to_s.singularize.camel_case
        #fields.concat potential_fields( nested_path + [name], nested_model )
        nested_name = ( nested_path + [name,'count'] ).join('.')
        fields << self.report_fields.new( :name => nested_name )
        
        # TODO: Add a nested_model.sum.propname filter for every numeric property of nested_model

      end
      
    end
    
    return fields
    
  end
  
  
  # Array of possible field objects available for this report to use as filters:
  def potential_filters
    return self.potential_fields.select{ |f| f.property_type == ReportField::ATTRIBUTE }
  end



  def sources_list

	  Report.sources.map do |source|
		  [ self.source_model(source), Report.class_display_name_of( self.source_model(source) ).pluralize ]
	  end
  
  end
  
  



  # Class methods:
  
  # Define list of models that reports can be based on: (Every report must have one source)
  def self.sources
    return [ :money_ins, :clients, :trips, :money_outs ]
  end





	def self.class_display_name_of( model )
		
		if model.respond_to? :class_display_name
			model.class_display_name
		else
			model.to_s.snake_case.gsub('_',' ').capitalize
		end
		
	end

end




# Report.auto_migrate!		# Warning: Running this will clear the table!