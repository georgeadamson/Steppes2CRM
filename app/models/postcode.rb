class Postcode
  include DataMapper::Resource
  
  def self.default_repository_name
    :postcodes
  end

  property :id, Serial              # This only exists to help datamapper uniquely identify rows!
  
  property :street_numbers,         String, :field => 'StreetNos'    # Semicolon-separated list of numbers. May contain blanks or ranges eg 7-9.
  property :address1,               String, :field => 'PremiseName'  # Semicolon-separated list of names.
  property :address2d,              String, :field => 'StreetD'      # More localised Street or Lane.
  property :address2,               String, :field => 'Street'
  property :address3d,              String, :field => 'LocalityDD'   # More localised area of Locality, perhaps a district.
  property :address3,               String, :field => 'LocalityD'    # Village, Region or Suburb.
  property :address4,               String, :field => 'PostTown'     # Postal town or city.
  property :address5,               String, :field => 'County'
  property :postcode,               String, :field => 'PostCode',    :index => true
  
  property :po_box,                 String, :field => 'POBox',             :lazy => true
  property :organisation,           String, :field => 'OrgPremise',        :lazy => true
  property :county_old_postal,      String, :field => 'CountyOldPostal',   :lazy => true
  property :county_old_traditional, String, :field => 'CountyTraditional', :lazy => true
  
  alias name  postcode
  alias name= postcode=



  # EXCLUDE postcodes table from AUTO MIGRATIONS because it is used as a readonly lookup only...

  def self.auto_upgrade!(args = nil)
    DataMapper.logger.warn("Skipping #{self.name}.auto_upgrade! because postcodes is a readonly lookup")
  end

  def self.auto_migrate!(args = nil)
    DataMapper.logger.warn("Skipping #{self.name}.auto_migrate! because postcodes is a readonly lookup")
  end

  def self.auto_migrate_up!(args = nil)
    DataMapper.logger.warn("Skipping #{self.name}.auto_migrate_up! because postcodes is a readonly lookup")
  end

  def self.auto_migrate_down!(args = nil)
    DataMapper.logger.warn("Skipping #{self.name}.auto_migrate_down! because postcodes is a readonly lookup")
  end

end
