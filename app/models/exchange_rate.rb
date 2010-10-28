class ExchangeRate
  include DataMapper::Resource
  
  property :id,								Serial
  property :name,							String,			:required => true, :unique => true, :default => 'New currency'
  property :rate,							BigDecimal, :required => true, :precision => 10, :scale => 2, :default => 1	# AKA SterlingRate
  property :new_rate,					BigDecimal, :required => true, :precision => 10, :scale => 2, :default => 1	# AKA NewSterlingRate
  property :new_rate_on_date,	Date,				:required => true

  property :created_at,       DateTime
  property :created_by,       String
  property :updated_at,       DateTime
  property :updated_by,       String
  
  has n, :suppliers,  :child_key => [:currency_id]
  has n, :money_outs, :child_key => [:currency_id]  # Formerly known as SupplierPaymentRequests
  
  before :save do

		# Apply new_rate immediately if today's date was specified:
    if self.new_rate_on_date.jd == Date.today.jd

		  self.rate = self.new_rate

    # Disregard future-dated change if new_rate is no different:
    elsif self.new_rate == self.rate && self.new_rate_on_date > Date.today

      self.new_rate_on_date = Date.today

    end

  end
	
  after :save do
		# Clear cached lists after saving any changes:
		refresh_cached_hash_of(:exchange_rates)
  end
	
  def name_and_rate
		return "#{ self.name } [#{ self.rate.to_s('F') }]"
  end
  alias display_name name_and_rate

end

# Allow Currency to be used an alias for ExchangeRate:
class Currency < ExchangeRate
end

# SQL script to add table columns 5-Oct-2010:
=begin

  BEGIN TRANSACTION
  GO
  ALTER TABLE dbo.exchange_rates ADD
  created_at datetime NULL,
  created_by varchar(50) NULL,
  updated_at datetime NULL,
  updated_by varchar(50) NULL
  GO
  ALTER TABLE dbo.exchange_rates ADD CONSTRAINT
  DF_exchange_rates_created_at DEFAULT getdate() FOR created_at
  GO
  ALTER TABLE dbo.exchange_rates ADD CONSTRAINT
  DF_exchange_rates_updated_at DEFAULT getdate() FOR updated_at
  GO
  COMMIT

  UPDATE exchange_rates SET created_at = '2010-10-01' WHERE created_at IS NULL

=end