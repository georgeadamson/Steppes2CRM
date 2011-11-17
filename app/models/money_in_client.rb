class MoneyInClient
  include DataMapper::Resource
  
  # Records which clients are being paid for by each invoice.

  property :id, Serial

  belongs_to :client
  #belongs_to :money_in
  belongs_to :on_invoices, :model => "MoneyIn", :child_key => [:money_in_id]
    
end

# MoneyInClient.auto_migrate!		# Warning: Running this will clear the table!