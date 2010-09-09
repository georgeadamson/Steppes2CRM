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
  property :closed_date,        Date,   :required => false # Formerly DateTimeClosed.
  property :closed_by_user_id,  Integer,:required => false # Formerly ClosedByConsultantID.
  property :closed_notes,       String, :required => false, :length => 500 # Formerly ClosingNotes.
  property :created_on,         Date

  belongs_to :type,   :model => "TaskType",   :child_key => [:type_id]
  belongs_to :status, :model => "TaskStatus", :child_key => [:status_id]
  belongs_to :contact_client, :model => "Client", :child_key => [:contact_client_id]
  belongs_to :client
  belongs_to :user
  belongs_to :closed_by_user, :model => "User", :child_key => [:closed_by_user_id]

  alias notes  name
  alias notes= name=

  # Set the default sort order:
  default_scope(:default).update( :order => [:status_id, :due_date.desc, :closed_date.desc] )

  def open?
    return self.status_id == TaskStatus::OPEN
  end

  before :save do

    self.status_id   ||= TaskStatus::OPEN
    self.closed_date ||= Date.today unless self.status_id == TaskStatus::OPEN

  end

end


# Task.auto_migrate!		# Warning: Running this will clear the table!