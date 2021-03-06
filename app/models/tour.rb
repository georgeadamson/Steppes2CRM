class Tour
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String,   :required => true,  :default => 'New group tour', :unique => true, :length => 100
  property :notes,      Text,     :required => false, :default => '', :lazy => false
  property :company_id, Integer,  :required => true

  belongs_to  :company
  has n,      :trips, :type_id => TripType::TOUR_TEMPLATE    # The condition excludes FIXED_DEP trips that are the client's copy of a TOUR_TEMPLATE.
  
  # These aliases just simplify common code that was originally written to handle client model:
  alias shortname    name
  alias display_name name
  alias fullname     name

  def create_trip_from_template( template_trip )

    new_trip = Trip.new
    new_trip.copy_attributes_from( template_trip )

    return new_trip
    
  end

  # Helper to trigger creation of a VirtualCabinet Command File for this user: (For GROUP TOUR only, not for a Client)
  # def open_virtual_cabinet( user, trip_id = nil )
  #   return VirtualCabinet.create user, self, trip_id
  # end

end



# Tour.auto_migrate!		# Warning: Running this will clear the table!