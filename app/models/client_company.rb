class ClientCompany
  include DataMapper::Resource
  
  # Associate clients with companies. (Only used on client page and for marketing/reports)

  property :id,         Serial
  property :client_id,  Integer, :required => true  # Recommend clustered index on this field.
  property :company_id, Integer, :required => true
  
  belongs_to :client
  belongs_to :company

end

# ClientCompany.auto_migrate!		# Warning: Running this will clear the table!