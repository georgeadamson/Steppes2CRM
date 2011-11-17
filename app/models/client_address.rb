class ClientAddress
  include DataMapper::Resource
  
  property :id,         Serial
  property :is_active,  Boolean, :required => true, :default => false			# This flag identifies the client's CURRENT address.
  property :client_id,  Integer, :required => true, :unique_index => :client_and_address
  property :address_id, Integer, :required => true, :unique_index => :client_and_address

  belongs_to :client
  belongs_to :address

  alias is_primary  is_active
  alias is_primary= is_active=


  def set_as_primary
    self.client.client_addresses.each{ |a| a.is_active = (a.id == self.id) }.save!
  end


  before :save do
    # Make this is the primary address if there isn't one set for the client:
    # Important: To allow for unsaved changes this must test the loaded instances not the database.
    self.is_active = true unless self.client.client_addresses.select{|a| a.is_active }.length > 0
  end

  after :save do
    #ClientAddress.ensure_client_has_one_primary_address( self.client )
  end
  
  before :destroy do
    @client = self.client
  end

  after :destroy do
    ClientAddress.ensure_client_has_one_primary_address( @client )
  end
  

  def name
    return self.address.name
  end


  # Helper for managing the is_active (primary address) flag:
  def self.ensure_client_has_one_primary_address( client )

    # Make sure exactly one address is tagged as primary:
    # (Sort them by is_active first then ensure only the first one is indeed active)
    # (This original shorter code caused error: Could not cope with boolean as first sort param: self.client.client_addresses.all( :order => [ :is_active.desc, :id ] ).each_with_index do |a,i|
    client.client_addresses.all( :order => [ :id.desc, :is_active ] ).reverse!.each_with_index do |a,i|

      ( a.is_active = (i==0); a.save! ) if a.is_active != (i==0)

    end if client

  end


  
  
  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Addresses'
  end
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :client, :address, :is_active ]
  end
  
end
