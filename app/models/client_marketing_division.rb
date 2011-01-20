class ClientMarketingDivision
  include DataMapper::Resource
  
  property :id, Serial

  property :client_id,    Integer, :required => true
  property :division_id,  Integer, :required => true

  property :allow_email,  Boolean, :required => true, :default => false
  property :allow_postal, Boolean, :required => true, :default => false

  belongs_to :client
  belongs_to :division

end

# ClientMarketingDivision.auto_migrate!		# Warning: Running this will clear the table!
