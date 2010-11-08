class ClientType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  
  has n, :clients, :child_key => [:kind_id]
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :name ]
  end
  
end
