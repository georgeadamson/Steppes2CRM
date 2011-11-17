class Touchdown
  include DataMapper::Resource
  
  # Used by TripElement to indicate when a Flight touches down at other airport(s) before reaching destination.
  
  property :id, Serial

  property :start_date, DateTime
  property :end_date, DateTime

  belongs_to :trip_element
  belongs_to :airport

end
