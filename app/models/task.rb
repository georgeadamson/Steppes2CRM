class Task
  include DataMapper::Resource
  
  # Note: Former TaskHistory rows were migrated with TaskHistoryID+100000
  
  property :id,                 Serial
  property :name,               String, :required => true, :length => 500  # Formerly TaskNotes.
  property :due_date,           Date,   :required => true  # Formerly DateTimeDue.
  property :type_id,            Integer,:required => true  # Formerly TaskTypeID.
  property :status_id,          Integer,:required => true  # Formerly TaskResultID.
  property :client_id,          Integer,:required => true  # Formerly ContactID / ClientID.
  property :user_id,            Integer,:required => true  # Formerly ConsultantID.
  property :closed_date,        Date,   :required => false # Formerly DateTimeClosed.
  property :closed_by_user_id,  Integer,:required => false # Formerly ClosedByConsultantID.
  property :closed_notes,       String, :required => false, :length => 500 # Formerly ClosingNotes.
  property :created_on,         Date

  belongs_to :type,   :model => "TaskType",   :child_key => [:type_id]
  belongs_to :status, :model => "TaskStatus", :child_key => [:status_id]
  belongs_to :client
  belongs_to :user
  belongs_to :closed_by_user, :model => "User", :child_key => [:closed_by_user_id]

  alias notes  name
  alias notes= name=

  # Set the default sort order:
  default_scope(:default).update( :order => [ :due_date.desc, :type_id, :created_on ] )

end


# Task.auto_migrate!		# Warning: Running this will clear the table!