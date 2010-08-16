class ExchangeRate
  include DataMapper::Resource
  
  property :id,								Serial
  property :name,							String,			:required => true, :unique => true, :default => 'New currency'
  property :rate,							BigDecimal, :required => true, :precision => 6, :scale => 2, :default => 1	# AKA SterlingRate
  property :new_rate,					BigDecimal, :required => true, :precision => 6, :scale => 2, :default => 1	# AKA NewSterlingRate
  property :new_rate_on_date,	Date,				:required => true

  has n, :suppliers,  :child_key => [:currency_id]
  has n, :money_outs, :child_key => [:currency_id]  # Formerly known as SupplierPaymentRequests
  
  before :save do
		# Apply new_rate immediately if today's date was specified:
		self.rate = self.new_rate if self.new_rate_on_date.jd == Date.today.jd
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