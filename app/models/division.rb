class Division
  include DataMapper::Resource
  
  # These are categories within the whole of the Steppes Group, to which the various companies belong.
  # Typically used for marketing. Eg: Discovery, Steppes and Traveller. 

  property :id,   Serial
  property :name, String, :required => true, :unique => true

  has n, :companies
  has n, :client_marketing_divisions
  has n, :clients, :through => :client_marketing_divisions

end

#  Division.auto_migrate!		# Warning: Running this will clear the table!
