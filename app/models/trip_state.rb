class TripState   # Would have been TripStatus but pluralisation went screwy
  include DataMapper::Resource
  
  # Constants used throught the app. (Eg @trip.status_id = TripState::UNCONFIRMED)
  UNCONFIRMED = 1 unless defined? UNCONFIRMED
  CONFIRMED   = 2 unless defined? CONFIRMED
  COMPLETED   = 3 unless defined? COMPLETED
  ABANDONNED  = 4 unless defined? ABANDONNED
  CANCELLED   = 5 unless defined? CANCELLED
  
  property :id,   Serial									# 1=Active, 2=Confirmed, 3=complete, 4=Canceled, 5=Abandonned.
  property :name, String
	property :code, String, :length => 20	# Used for generating css class names (Eg: "trip-confirmed")

  has n, :trips, :child_key => [:status_id]

  #cache_attributes_for :name, :code
  
#  alias orig_attribute_get attribute_get
#
#  def attribute_get(name)
#    @@cached_attributes ||= {}
#    @@cached_attributes[name] ||= orig_attribute_get(name)
#  end

end
