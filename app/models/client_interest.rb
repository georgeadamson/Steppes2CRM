class ClientInterest
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :client	#,  :child_key => [:client_id]
  belongs_to :country	#, :child_key => [:country_id]

end
