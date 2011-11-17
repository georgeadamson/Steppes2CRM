class TripElementExcursion
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :excursion
  belongs_to :trip_element

end
