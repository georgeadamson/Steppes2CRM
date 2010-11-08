class TaskType
  include DataMapper::Resource
  
  # Important: Some tasks are created automatically using these hard-coded contants:
  FLIGHT_REMINDER       = 5 unless defined? FLIGHT_REMINDER     # "Flight Ticket Deadline"
  BROCHURE_FOLLOWUP     = 4 unless defined? BROCHURE_FOLLOWUP   # "Brochure Followup"
  
  property :id,   Serial
  property :name, String, :required => true, :unique => true
  
  has n, :tasks, :child_key => [:kind_id]

  # Set the default sort order:
  default_scope(:default).update(:order => [:name])

end

# TaskType.auto_migrate!		# Warning: Running this will clear the table!