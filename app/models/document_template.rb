class DocumentTemplate
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String, :required => true, :length => 500
  property :file_name,  String, :required => true, :length => 500

	belongs_to :document_type


  # Helper to locate the TARGET FOLDER for document generation:
  def self.folder
    return CRM[:doc_templates_path]
  end

end

# DocumentTemplate.auto_migrate!		# Warning: Running this will clear the table!