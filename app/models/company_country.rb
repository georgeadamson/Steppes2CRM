class CompanyCountry
  include DataMapper::Resource
  
  property :id, Serial
	
  belongs_to :company
  belongs_to :country

end
