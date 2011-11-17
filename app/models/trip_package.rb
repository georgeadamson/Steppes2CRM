class TripPackage
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length => 100
  property :year, Integer
  property :notes, String, :length => 255
  
  #has n, :trips

end
