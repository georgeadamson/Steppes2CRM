class Address
  include DataMapper::Resource
  
  property :id, Serial, :index => true

  property :address1, String, :length => 60, :index => :address, :default => ""
  property :address2, String, :length => 60, :index => :address, :default => ""
  property :address3, String, :length => 60, :index => :address, :default => ""
  property :address4, String, :length => 60, :index => :address, :default => ""
  property :address5, String, :length => 60, :index => :address, :default => ""
  property :address6, String, :length => 60, :index => :address, :default => ""	# DEPRICATED. Holds legacy data.
  property :postcode, String, :length => 10, :index => true,     :default => ""	# AKA address6. UK postcode pattern: /^([A-Z][A-Z]?[0-9][0-9A-Z]? *[0-9][A-Z][A-Z])$/
  property :country_id, Integer, :default => 6  								# AKA address7 (Defaults to Country.first(:code=>"UK").id)

  property :tel_home, String, :default => ""
  property :fax_home, String, :default => ""

  belongs_to :country                           # AKA address7

  has n, :client_addresses
  has n, :clients, :through => :client_addresses


  # Helper for returning the full address with commas between each line:
  # Note we separate lines with 2 spaces to provide a way for receiving code to distinguish the address lines if necessary.
  # (Html always renders 2 spaces as one so they're not a problem)
  # Also used by the client_address model.
  def name

    addr = []
    addr << self.address1 unless self.address1.blank?
    addr << self.address2 unless self.address2.blank?
    addr << self.address3 unless self.address3.blank?
    addr << self.address4 unless self.address4.blank?
    addr << self.address5 unless self.address5.blank?
    addr << self.address6 unless self.address6.blank?
    addr << self.postcode unless self.postcode.blank?
    addr << self.country.name unless self.country.nil?

    return addr.join(',  ')

  end

  alias entire_address name


  
  
  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Address'
  end
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :entire_address, :address1, :address2, :address3, :address4, :address5, :address6, :postcode ]
  end

end

