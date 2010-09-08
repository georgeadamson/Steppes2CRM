class ClientInterest
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :client	#,  :child_key => [:client_id]
  belongs_to :country	#, :child_key => [:country_id]
  
  

  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Client interests'
  end
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :country, client ]
  end
  
end
