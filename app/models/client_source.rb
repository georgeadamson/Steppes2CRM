class ClientSource
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  has n, :clients, :child_key => [:source_id]
  has n, :clients, :child_key => [:original_source_id]

  # Set the default sort order:
  default_scope(:default).update(:order => [:name])

end
