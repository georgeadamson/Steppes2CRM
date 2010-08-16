class UserClient
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :client
  belongs_to :user
  property   :is_open,     Boolean, :default => false	# True when client is open in UI.
  property   :is_selected, Boolean, :default => false	# True when client is open and selected in UI.
  
  property   :created_at, DateTime
  property   :updated_at, DateTime

end
