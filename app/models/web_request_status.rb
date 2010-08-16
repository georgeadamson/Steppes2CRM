class WebRequestStatus
  include DataMapper::Resource
  
  property :id,           Serial
  property :name,         String, :required => true, :unique => true
  property :action_name,  String, :required => true, :unique => true

  has n, :web_requests, :child_key => [:status_id]
  
end

# WebRequestStatus.auto_migrate!		# Warning: Running this will clear the table!