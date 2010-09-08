class TripClientStatus
  include DataMapper::Resource
  
  # Confirmation status of clients on trips

  UNCONFIRMED = 0    unless defined? UNCONFIRMED
  CONFIRMED   = 1    unless defined? CONFIRMED
  WAITLISTED  = 2    unless defined? WAITLISTED
  INTERESTED  = 3    unless defined? INTERESTED   # Depricated?
    
  property :id,   Integer,  :key => true, :unique_index => true
  property :name, String,   :required => true, :length => 20

  has n, :trip_clients, :child_key => [:status_id]

end


TripClientStatus.auto_migrate!		# Warning: Running this will clear the table!

# Seed the statuses: (Same IDs as legacy database GroupItineraryStatus, to simplify data migration)
TripClientStatus.first_or_create( { :id => TripClientStatus::UNCONFIRMED }, { :id => TripClientStatus::UNCONFIRMED, :name => 'Unconfirmed' } )
TripClientStatus.first_or_create( { :id => TripClientStatus::CONFIRMED   }, { :id => TripClientStatus::CONFIRMED,   :name => 'Confirmed'   } )
TripClientStatus.first_or_create( { :id => TripClientStatus::WAITLISTED  }, { :id => TripClientStatus::WAITLISTED,  :name => 'Waitlisted'  } )
TripClientStatus.first_or_create( { :id => TripClientStatus::INTERESTED  }, { :id => TripClientStatus::INTERESTED,  :name => 'Interested'  } )
