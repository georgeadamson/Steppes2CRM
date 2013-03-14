class TaskType
  include DataMapper::Resource
  
  # Important: Some tasks are created automatically using these hard-coded contants:
  NOTE                  = 3 unless defined? NOTE                # "Note"
  FLIGHT_REMINDER       = 5 unless defined? FLIGHT_REMINDER     # "Flight Ticket Deadline"
  BROCHURE_FOLLOWUP     = 4 unless defined? BROCHURE_FOLLOWUP   # "Brochure Followup"
  SEND_FINALS           = 7 unless defined? SEND_FINALS         # "Send final docs"
  TRIP_FOLLOWUP         = 8 unless defined? TRIP_FOLLOWUP       # "Ring pax 2 days after return"
  
  property :id,   Serial
  property :name, String, :required => true, :unique => true
  
  has n, :tasks, :child_key => [:type_id]

  # Set the default sort order:
  default_scope(:default).update(:order => [:name])

end

# TaskType.auto_migrate!		# Warning: Running this will clear the table!