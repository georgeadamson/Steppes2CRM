class ClientMarketingDivision
  include DataMapper::Resource
  
  property :id, Serial

  property :client_id,    Integer, :required => true
  property :division_id,  Integer, :required => true

  property :allow_email,  Boolean, :required => true, :default => false
  property :allow_postal, Boolean, :required => true, :default => false

  belongs_to :client
  belongs_to :division

  def summary

    return case
      when self.allow_email && self.allow_postal
        'Email & Postal'
      when self.allow_email
        'Email only'
      when self.allow_postal
        'Postal only'
      else
        'None'
      end
  
  end

end

# ClientMarketingDivision.auto_migrate!		# Warning: Running this will clear the table!
