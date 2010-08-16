class MoneyStatus
  include DataMapper::Resource
  
  property :id,           Serial
  property :name,         String, :required => true
  property :description,  String, :required => true

  has n, :money_outs, :child_key => [:status_id]

end

# MoneyStatus.auto_migrate!		# Warning: Running this will clear the table!