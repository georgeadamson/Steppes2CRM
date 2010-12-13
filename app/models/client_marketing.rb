class ClientMarketing
  include DataMapper::Resource
  
  # 0	No marketing
  # 1	Any marketing
  # 2	Email marketing
  # 4	Postal marketing

  property :id, Serial
  property :name, String

  has n, :clients, :child_key => [:marketing_id]

end
