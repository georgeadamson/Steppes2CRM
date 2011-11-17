class CountryPhoto
  include DataMapper::Resource
  
  property :id, Serial

  belongs_to :country
  belongs_to :photo

end
