class CountryUser
  include DataMapper::Resource
  
  property :id, Serial

  #property :countryId, Integer
  #property :userId, Integer

  belongs_to :country
  belongs_to :user

end
