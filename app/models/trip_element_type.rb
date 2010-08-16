class TripElementType
  include DataMapper::Resource

  FLIGHT  = 1 unless defined?(FLIGHT)
  HANDLER = 2 unless defined?(HANDLER)
  ACCOMM  = 4 unless defined?(ACCOMM)
  GROUND  = 5 unless defined?(GROUND)
  MISC    = 8 unless defined?(MISC)

  property :id,                 Serial	# 1=Flight, 2=FlightAgent, 4=Accomm, 5=Ground, 8=Misc
  property :name,               String
  property :code,               String,   :default => :name, :length => 12
  property :supplier_type_name, String,   :default => :name
  property :is_linked_supplier, Boolean,  :default => false
  property :order_by,           Integer

  has n, :suppliers,      :child_key => [:type_id]
  has n, :trip_elements,  :child_key => [:type_id]

end
