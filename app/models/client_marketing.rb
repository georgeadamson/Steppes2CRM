class ClientMarketing
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  has n, :clients, :child_key => [:marketing_id]

end
