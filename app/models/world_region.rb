class WorldRegion
  include DataMapper::Resource
  
  property :id,		Serial
  property :name,	String, :required => true, :default => 'New world region'

  has n, :countries

end
