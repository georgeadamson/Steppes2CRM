class Tour
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String,   :required => true,  :default => 'New tour', :length => 100
  property :notes,      Text,     :required => false, :default => '', :lazy => false
  property :company_id, Integer,  :required => true

  belongs_to  :company
  has n,      :trips    # AKA Fixed departures
  
  # These aliases just simplify common code that was originally written to handle client model:
  alias shortname    name
  alias display_name name
    
end



# Tour.auto_migrate!		# Warning: Running this will clear the table!