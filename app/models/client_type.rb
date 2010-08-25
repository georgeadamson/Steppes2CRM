class ClientType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String
  
  has n, :clients, :child_key => [:type_id]
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :name ]
  end
  
end
