class MoneyOut
  include DataMapper::Resource
  
  # IMPORTANT: Formerly knows as "SupplierPaymentRequests" (Note: SupplierPayments table was unused in old database)
  
  property :id,               Serial
  property :status_id,        Integer,    :required => true,  :default => 1
  property :supplier_id,      Integer,    :required => true
  property :trip_id,          Integer,    :required => true
  property :user_id,          Integer,    :required => true
  property :currency_id,      Integer,    :required => true,  :default => 1
  property :amount_requested, BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2  # AMOUNT REQUESTED
  property :amount_paid,      BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2
  property :requested_date,   DateTime,   :required => true,  :default => lambda{ |obj,prop| DateTime.now }
  property :notes,            Text,       :required => false, :default => ''
  property :user_fullname,    String,     :required => true   # Only used because of legacy migrated data.
  property :created_at,       DateTime
  property :updated_at,       DateTime
  
  belongs_to :supplier
  belongs_to :trip
  belongs_to :status,   :model => "MoneyStatus",  :child_key => [:status_id]
  belongs_to :currency, :model => "ExchangeRate", :child_key => [:currency_id]
  belongs_to :user # Could not use this because of old user names in the the migrated data.
  
  def name
    "Payment to #{ self.supplier.name }"
  end

  
  

#  validates_with_block :amount_requested do
#
#	  supplier_total		= self.trip && self.trip.total_cost_of_supplier(self.supplier) || 0
#	  already_requested = self.trip && self.trip.money_outs.sum( :amount_requested, :supplier_id => self.supplier.id ) || 0
#    expected_amount   = supplier_total - already_requested
#    min_limit        = expected_amount - ( expected_amount * 0.05 )
#    max_limit        = expected_amount + ( expected_amount * 0.05 )
#    
#    if self.amount_requested == 0
#      return [ false, "Can\'t help wondering what is the point of requesting a payment of zero?\n Let\'s forget it and say no more about it shall we?" ]
#    elsif self.amount_requested < min_limit || self.amount_requested > max_limit
#      return [ false, "Requesting payments for silly amounts makes you a bit of a liability frankly.\n Let's stick within 5% for now shall we?" ]
#    else
#      return true
#    end
#
#  end

  
  before :valid? do
    self.user_fullname ||= self.user && self.user.preferred_name
    self.amount_requested = self.amount_requested.to_f
  end





# Class methods:
  
  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Supplier Payment'
  end
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :name, :amount_requested, :requested_date, :notes, :supplier, :trip, :status, :currency, :user, :created_at ]
  end

end


# MoneyOut.auto_migrate!		# Warning: Running this will clear the table!