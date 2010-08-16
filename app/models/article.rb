class Article
  include DataMapper::Resource
  
  property :id, Serial
  #property :name, String, :default => "Notes"
  property :description, String, :length => 2000, :default => "Add notes here"

  belongs_to :article_type
  belongs_to :company
  belongs_to :country

end
