class Company
  include DataMapper::Resource
  
  property :id, Serial

  property :name,										String,		  :required => true,	:unique => true,	:default => 'New company'
  property :short_name,							String,		  :required => true,	:length => 10,		:unique => true, :default => 'Company'
  property :initials,								String,		  :required => true,	:length => 3,			:unique => true, :default => 'S'
  property :invoice_prefix,					String,		  :required => true,	:length => 2,			:unique => true, :default => 0
  property :logo_url,								String,		  :required => true,	:length => 250,		:default => 'images/logo.jpg'
  property :images_folder,					String,		  :required => true,	:length => 50,		:default => 'SteppesEast/_Photos'
  property :due_days,								Integer,	  :required => true,	:default => 84
  property :cc_sup,									Decimal,	:required => true,	:default => 2,    :precision=>6, :scale=>2
  property :booking_fee,						Integer,	  :required => true,	:default => 51
  property :brochure_followup_days,	Integer,	  :required => true,	:default => 7
  property :default_deposit,				String,		  :required => true,	:length => 4,			:default => 300
  property :is_active,							Boolean,	  :required => true,	:default => true

  has n, :tours
  has n, :articles		# TBD
  has n, :trips				# Trip handler / cost-centre / invoice-to
  has n, :users				# Formerly known as Consultant.PrimaryCompanyId
  has n, :documents
  has n, :money_ins   # AKA Invoices
  has n, :web_requests
  has n, :brochure_requests
  
  has n, :company_suppliers
  has n, :suppliers, :through => :company_suppliers

  has n, :company_countries
  has n, :companies, :through => :company_countries
	
  # Associate clients with companies: (Only used on client page and for marketing/reports)
  has n, :client_companies
  has n, :clients, :through => :client_companies
  
	# Return a sting like 'Steppes Africa (Active) [SA]'
	def name_and_is_active
		return "#{ self.name } #{ ' (Inactive)' unless self.is_active }#{ ' [' + self.initials + ']' unless self.initials.blank? }"
	end
	alias display_name name_and_is_active

  # Return a string like 'Steppes East (15)' to indicate the number of pending brochure_requests:
  def name_and_pending_brochures
    pending_brochures = BrochureRequest.all( :company_id => self.id, :status_id.not => BrochureRequest::CLEARED )
		return "#{ self.name } (#{ pending_brochures.count })"
		# For some reason this alternative was very slow: return "#{ self.name } [#{ self.brochure_requests( :generated_date => nil ).count }]"
  end

  #cache_attributes_for :name, :display_name
  
end
