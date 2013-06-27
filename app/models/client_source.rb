class ClientSource
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  has n, :clients, :child_key => [:source_id]
  has n, :clients, :child_key => [:original_source_id]

  # Set the default sort order:
  default_scope(:default).update(:order => [:name])

  def major
    return self.name.split(' - ').first
  end
  
  def minor
    return self.name.split(' - ').last
  end
  
  # Helper to return a grouped collection, ready for use in a <select> list with <optgroup> tags:
  # Apparently the (&:major) syntax is equivalent to {|i| i.major}
  def self.all_grouped
    return ClientSource.all( :order=>[:name] ).group_by( &:major )
  end
  
end
