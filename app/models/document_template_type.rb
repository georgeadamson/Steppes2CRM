class DocumentTemplateType
  include DataMapper::Resource
  
  

  property :id,   Serial
  property :name, String, :required => true, :length => 20

end

# DocumentTemplateType.auto_migrate!		# Warning: Running this will clear the table!