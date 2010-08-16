class Excursion
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String

  has n, :trip_element_excursions
  belongs_to :supplier

end
