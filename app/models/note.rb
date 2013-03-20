class Note
  include DataMapper::Resource
  
	property :id, Serial
	property :name, String, :length => 255, :default => 'Type some notes'
	property :is_favourite, Boolean, :default => false
	property :created_at, DateTime
	property :updated_at, DateTime

	belongs_to :client
	#belongs_to :trip

  alias text name

  def favourite?
    self.is_favourite
  end

end
