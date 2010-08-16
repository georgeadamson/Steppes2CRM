class Tour
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String,   :required => true,  :default => 'New tour', :length => 100
  property :notes,      Text,     :required => false, :default => '', :lazy => false
  property :company_id, Integer,  :required => true

  belongs_to  :company
  has n,      :trips, :type_id => TripType::TOUR_TEMPLATE    # The condition excludes FIXED_DEP trips that are the client's copy of a TOUR_TEMPLATE.
  
  # These aliases just simplify common code that was originally written to handle client model:
  alias shortname    name
  alias display_name name


  def create_trip_from_template( template_trip )

    new_trip = Trip.new
    new_trip.copy_attributes_from( template_trip )

    return new_trip
    
  end


end



# Tour.auto_migrate!		# Warning: Running this will clear the table!