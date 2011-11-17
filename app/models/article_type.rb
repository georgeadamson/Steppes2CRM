class ArticleType
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :length=>20

  has n, :articles

end
