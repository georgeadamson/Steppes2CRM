class WebRequestType
  include DataMapper::Resource
  
  property :id,         Serial
  property :name,       String,   :required => true,  :unique   => true
  property :form_name,  String,   :required => true,  :unique   => true
  property :is_active,  Boolean,  :required => true,  :default  => true

  has n, :web_requests, :child_key => [:kind_id]
  
  alias active? is_active

  def display_name
    return "#{ self.name }#{ ' [Associated with website form]' if self.is_active }"
  end

end


# WebRequestType.auto_migrate!		# Warning: Running this will clear the table!