class DocumentJob
  include DataMapper::Resource
  
  # DEPRICATED. Use Document instead

  # Defines and tracks tasks for generating documents.

  property :id,                   Serial
  property :name,			            String,   :required => true, :length => 500
  property :document_template_id, Integer,  :required => true, :default => 1
  property :parameters,           Object,   :required => true                  # Object datatype auto-migrates as nvarchar(MAX)
  property :document_status_id,   Integer,  :required => true, :default => 0
  
	belongs_to :document_template
  
end

# DocumentJob.auto_migrate!		# Warning: Running this will clear the table!
