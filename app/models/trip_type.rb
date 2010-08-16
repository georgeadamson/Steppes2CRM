class TripType
  include DataMapper::Resource

  TAILOR_MADE   = 1  unless defined? TAILOR_MADE    # A normal bespoke trip.
  FIXED_DEP     = 2  unless defined? FIXED_DEP      # A Fixed Dep trip must belong to a Group Tour object.
  PRIVATE_GROUP = 3  unless defined? PRIVATE_GROUP  # Technically no different from a Tailor Made.
  
  property :id, Serial
  property :name, String

  has n, :trips, :child_key => [:type_id]

end
