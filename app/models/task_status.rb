class TaskStatus
  include DataMapper::Resource

  # Note: TaskStatus was formerly known as TaskResult. (Completed or Abandoned)

  OPEN       = 0 unless defined? OPEN
  COMPLETED  = 1 unless defined? COMPLETED
  ABANDONNED = 2 unless defined? ABANDONNED

  property :id,   Integer,  :required => true, :unique => true, :key => true
  property :name, String,   :required => true, :unique => true

  has n, :tasks, :child_key => [:status_id]
  
end

# TaskStatus.auto_migrate!		# Warning: Running this will clear the table!