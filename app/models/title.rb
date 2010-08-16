class Title
  include DataMapper::Resource
  
  # Definitions of Client Titles such as Mr, Mrs, Professor etc
  
  property :id,		      Serial
  property :name,       String, :required => true, :unique => true, :default => 'New title'
  property :sort_order, Integer, :default => 100
  
  has n, :clients
  
end

# Title.auto_migrate!