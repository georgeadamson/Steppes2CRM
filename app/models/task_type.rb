class TaskType
  include DataMapper::Resource
  
  property :id,   Serial
  property :name, String, :required => true, :unique => true
  
  has n, :tasks, :child_key => [:type_id]

  # Set the default sort order:
  default_scope(:default).update(:order => [:name])

end

# TaskType.auto_migrate!		# Warning: Running this will clear the table!