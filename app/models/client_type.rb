class ClientType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  
  has n, :clients, :child_key => [:type_id]

end
