class TripType
  include DataMapper::Resource

  TAILOR_MADE   = 1  unless defined? TAILOR_MADE
  FIXED_DEP     = 2  unless defined? FIXED_DEP
  PRIVATE_GROUP = 3  unless defined? PRIVATE_GROUP  # TODO: Depricate this because TAILOR_MADE trip can do the job.
  
  property :id, Serial
  property :name, String

  has n, :trips, :child_key => [:type_id]

end
