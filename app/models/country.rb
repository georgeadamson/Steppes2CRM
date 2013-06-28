require "dm-accepts_nested_attributes"

class Country
  include DataMapper::Resource
  
  # Special constant for the UK's country id: (Was '6' at time of writing)
  UK = repository(:default).adapter.select("SELECT TOP 1 id FROM countries WHERE code = 'UK'").first || 0 unless defined? UK
  
  property :id,								Serial
  property :name,							String,		:required => true,	:unique => true, :default => 'New country'
  property :code,							String,		:length => 2,				:unique => true		# Eg: GB, US
  property :notes,						String,		:length => 2000
  property :exclusions,				String,		:length => 1000
  property :inclusions,				String,		:length => 1000
  property :mailing_zone_id,	Integer,	:required => true,	:default => 1	# Zone UK
  property :world_region_id,	Integer,	:required => true

  has n, :addresses # Client address
  has n, :airports
  has n, :articles
  has n, :images
  has n, :suppliers

  has n, :trip_countries
  has n, :trips, :through => :trip_countries	#, :mutable => true
  
  belongs_to :world_region
  belongs_to :mailing_zone
  #belongs_to :exchange_rate  # Allows exchange_rates to have a default country

  has n, :country_photos
  has n, :photos, :through => :country_photos	#, :mutable => true

  has n, :client_interests
  has n, :clients, :through => :client_interests	#, :child_key => [:country_id]

  has n, :country_users  # Countries assigned to Consultants.
  has n, :users, :through => :country_users

  has n, :company_countries
  has n, :companies, :through => :company_countries


	accepts_ids_for :companies
  #accepts_nested_attributes_for :trips	# See: http://github.com/snusnu/dm-accepts_nested_attributes

  #cache_attributes_for :name, :code

	validates_with_method :require_one_or_more_companies





	def require_one_or_more_companies
		
		if self.companies.empty?
			return [ false, 'This country must be assigned to at least one company before you can use it' ]
		else
			return true
		end
		
	end



  def id_and_name
    [ self.id, self.name ]
  end

  
  def world_region_name
    return self.world_region.name
  end

end
