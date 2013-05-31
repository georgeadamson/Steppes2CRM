class DocumentType
  include DataMapper::Resource

  ITINERARY         = 1  unless defined? ITINERARY
  MAIN_INVOICE      = 2  unless defined? MAIN_INVOICE
  CREDIT_NOTE       = 3  unless defined? CREDIT_NOTE
  SUPP_INVOICE      = 4  unless defined? SUPP_INVOICE
  CONTACT_SHEET     = 5  unless defined? CONTACT_SHEET
  CONTROL_SHEET     = 6  unless defined? CONTROL_SHEET
  LETTER            = 8  unless defined? LETTER
  BROCHURE          = 12 unless defined? BROCHURE
  ATOL_CERTIFICATE  = 13 unless defined? ATOL_CERTIFICATE
  COSTING_SHEET     = 14 unless defined? COSTING_SHEET
  # TODO: more...? There must be a better way?

  property :id,                 Serial
  property :name,               String, :required => true, :unique => true, :default => 'New type of document'
  property :template_file_name, String, :required => true, :unique => true, :default => 'template.doc'
  
  has n, :documents
  has n, :document_templates

  def display_name

    display_name = self.name
    display_name << " [#{ self.template_file_name }]" unless self.template_file_name.blank?
    return display_name

  end

end


# DocumentType.auto_migrate!		# Warning: Running this will clear the table!




#  USE steppes2dev
#
#  TRUNCATE TABLE document_types
#  SET IDENTITY_INSERT document_types ON
#
#   INSERT INTO document_types (id,name,template_file_name)
#   SELECT * FROM steppes2live..document_types
#
#  SET IDENTITY_INSERT document_types OFF