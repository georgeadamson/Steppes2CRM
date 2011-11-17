class TripCountry
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :trip
  belongs_to :country

end
