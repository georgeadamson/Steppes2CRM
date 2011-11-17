class Task
  include DataMapper::Resource
  
  # Note: Former TaskHistory rows were migrated with TaskHistoryID+100000

  # Note: Only 5 migrated tasks had differing Client and Contact so that feature was never used!
  # SELECT * FROM Task INNER JOIN Clients ON Clients.ClientID = Task.ClientID WHERE Clients.ContactID != Task.ContactID
  
  property :id,                 Serial
  property :name,               String, :required => false, :length => 500  # Formerly TaskNotes.
  property :due_date,           Date,   :required => true  # Formerly DateTimeDue.
  property :type_id,            Integer,:required => true  # Formerly TaskTypeID.
  property :status_id,          Integer,:required => true, :default => TaskStatus::OPEN # Formerly TaskResultID.
  property :client_id,          Integer,:required => true  # Formerly ClientID.
  property :contact_client_id,  Integer,:required => true, :default => lambda{ |task,prop| task.client_id }  # Formerly ContactID.
  property :user_id,            Integer,:required => true  # Formerly ConsultantID.
  property :trip_element_id,    Integer,:required => false # Formerly LinkedID.
  property :brochure_request_id,Integer,:required => false # Formerly LinkedID.
  property :closed_date,        Date,   :required => false # Formerly DateTimeClosed.
  property :closed_by_user_id,  Integer,:required => false # Formerly ClosedByConsultantID.
  property :closed_notes,       String, :required => false, :length => 500 # Formerly ClosingNotes.
  property :created_on,         Date

  belongs_to :status, :model => "TaskStatus", :child_key => [:status_id]
  belongs_to :contact_client, :model => "Client", :child_key => [:contact_client_id]
  belongs_to :client
  belongs_to :user
  belongs_to :closed_by_user, :model => "User", :child_key => [:closed_by_user_id]
  belongs_to :task_type,   :model => "TaskType",   :child_key => [:type_id]
  alias type task_type

  # Context-specific relationships:
  belongs_to :trip_element
  belongs_to :brochure_request
  
  alias notes  name
  alias notes= name=

  # Set the default sort order:
  default_scope(:default).update( :limit => 1000, :order => [:status_id, :due_date.desc, :closed_date.desc] )

  def open?
    return self.status_id == TaskStatus::OPEN
  end

  before :valid? do

    self.status_id          ||= TaskStatus::OPEN
    self.closed_date        ||= Date.today unless self.status_id == TaskStatus::OPEN
    self.contact_client_id  ||= self.client_id

  end

end


# Task.auto_migrate!		# Warning: Running this will clear the table!