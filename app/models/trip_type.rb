class TripType
  include DataMapper::Resource

  TAILOR_MADE   = 1  unless defined? TAILOR_MADE    # A normal bespoke trip.
  PRIVATE_GROUP = 3  unless defined? PRIVATE_GROUP  # Technically no different from a Tailor Made.
  TOUR_TEMPLATE = 2  unless defined? TOUR_TEMPLATE  # A Template trip must belong to a Group Tour object.
  FIXED_DEP     = 4  unless defined? FIXED_DEP      # A Fixed Dep trip must belong to a Group Tour object.
  
  property :id, Serial
  property :name, String

  has n, :trips, :child_key => [:type_id]

end
