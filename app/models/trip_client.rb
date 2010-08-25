class TripClient
  include DataMapper::Resource
  
  property :id,             Serial
	property :trip_id,				Integer, :required => true #:unique => true, :scope => :client_id
	property :client_id,			Integer, :required => true #:unique => true, :scope => :trip_id

  property :is_leader,			Boolean, :required => true, :default => false
  property :is_primary,			Boolean, :required => true, :default => false
  property :is_single,			Boolean, :required => true, :default => false
  property :is_invoicable,	Boolean, :required => true, :default => false
  property :status_id,    	Integer, :required => true, :default => 0     # 0=Unconfirmed, 1=Confirmed, Allows for more. (Not to be confused with trip.status!)

	property :created_at, Date
	property :created_by, String, :default => ''
	property :updated_at, Date
	property :updated_by, String, :default => ''
		
  belongs_to :trip
  belongs_to :client
  belongs_to :status, :model => 'TripClientStatus', :child_key => [:status_id]
  #belongs_to :tripElement				# TODO: Handle trip sub group?

	#validates_is_unique :trip_id, :scope => :client_id, :message => "The client is already on this trip"

  def is_confirmed; return self.status_id == TripClientStatus::CONFIRMED; end

  alias confirmation_status status_id # Support for depricated field name


#	before :valid? do
#		# Ensure required fields are not nil:
#		self.is_leader						= self.model.properties[:is_leader].default						if self.is_leader.nil?
#		self.is_primary						= self.model.properties[:is_primary].default					if self.is_primary.nil?
#		self.is_single						= self.model.properties[:is_single].default						if self.is_single.nil?
#		self.is_invoicable				= self.model.properties[:is_invoicable].default				if self.is_invoicable.nil?
#		self.confirmation_status	= self.model.properties[:confirmation_status].default	if self.confirmation_status.nil?
#	end
#
#	before :create do
#		# Ensure both created_by and updated_by are set if only one was specified:
#		self.created_by = self.updated_by if self.created_by.blank?
#		self.updated_by = self.created_by if self.updated_by.blank?
#	end
#	
#  before :save do
# 
#		# When client is the only one on the trip, make sure it is the primary contact etc:
#    if self.trip.clients.length == 1
#      self.is_leader = true
#      self.is_primary = true
#      self.is_invoicable = true
#    end
#
#  end



# Class methods:
  
  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Relate trips with clients'
  end
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :trip, :client, :is_primary ]
  end

end
