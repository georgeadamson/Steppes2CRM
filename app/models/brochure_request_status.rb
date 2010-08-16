class BrochureRequestStatus
  include DataMapper::Resource
 
  property :id,   Serial
  property :name, String, :required => true

  has n, :brochure_requests, :child_key => [:status_id]
  
end


# BrochureRequestStatus.auto_migrate!		# Warning: Running this will clear the table!