class Photo
  include DataMapper::Resource
  #include UUIDTools
  require 'rubygems'
  require 'uuidtools'

  
  property :id, Serial
  property :name, String, :default=>"Photo" # AKA Image "alt" text
  property :path, String, :default=>"", :length=>500
  property :tags, String, :default=>"", :length=>200
  property :width, Integer, :default=>0
  property :height, Integer, :default=>0
  property :fileSize, Integer, :default=>0
  property :resolution, String, :default=>"M", :length=>1
  property :approved, Boolean, :default=>false
  property :uuid, UUID #, :default => UUIDTools::UUID.random_create  # Matches uuid stored inside JPG file, eg: <rdf:Description rdf:about='uuid:6250f8c2-08c4-11dc-b8f7-b2521d7a20e2'... -OR- xapMM:DocumentID="uuid:20C5A23E8CDEDC11BA3FADB041B0CA27" xapMM:InstanceID="uuid:21C5A23E8CDEDC11BA3FADB041B0CA27"

  has n, :country_photos
  has n, :countries, :through => :country_photos  #, :mutable => true

  attr_accessor :companyFolder, :destinationFolder, :countryIdlist

  before :create do
    #self.uuid = UUIDTools.random_create
    #self.uuid = UUIDTools::UUID.random_create
  end

  def url
    return "/ImageLibrary" / path
  end

  def countryId
    return countryPhotos.first.id
  end

  def countryId=(countryId)
    countryPhotos.first = Country.get(countryId)
  end

  def country
    return countryPhotos.first
  end

  #def initialize
  #  #@countryIdlist = "hello" #countries.map{ |country| country.id }.join(",")
  #end

end
