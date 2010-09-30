class WebRequestStatus
  include DataMapper::Resource
  
  PENDING   = 1  unless defined? PENDING  
  PROCESSED = 2  unless defined? PROCESSED
  ALLOCATED = 3  unless defined? ALLOCATED
  REJECTED  = 4  unless defined? REJECTED 
  
  property :id,           Serial
  property :name,         String, :required => true, :unique => true
  property :action_name,  String, :required => true, :unique => true

  has n, :web_requests, :child_key => [:status_id]
  
end

# WebRequestStatus.auto_migrate!		# Warning: Running this will clear the table!