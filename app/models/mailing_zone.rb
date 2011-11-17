class MailingZone
  include DataMapper::Resource
  
  property :id,				Serial
  property :name,			String, :length => 10, :required => true, :unique => true, :default => 'New zone'
  property :order_by,	Integer,:default => 1

  has n, :countries

  #cache_attributes_for :name
  
end
