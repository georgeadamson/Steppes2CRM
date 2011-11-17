class ClientMarketingDivision
  include DataMapper::Resource
  
  property :id, Serial

  property :client_id,    Integer, :required => true
  property :division_id,  Integer, :required => true

  property :allow_email,  Boolean, :required => true, :default => false
  property :allow_postal, Boolean, :required => true, :default => false

  belongs_to :client
  belongs_to :division


  # Not much point in keeping empty records:
  after :save do
    if !self.allow_email && !self.allow_postal
      self.destroy
    end
  end


  # Friendly readable summary of this marketing preference:
  # Eg: "Discovery: Email & Postal" (Used by client.marketing_summary)
  def summary( filter = :all, verbose = false )

    filter = :all unless filter.to_s =~ /all|email|postal/

    return case
      when filter == :all && self.allow_email && self.allow_postal
        "#{ self.division.name }: Email & Postal"
      when filter == :email && self.allow_email
        "#{ self.division.name }: Email"
      when filter == :postal && self.allow_postal
        "#{ self.division.name }: Postal"
      else
        verbose ? "#{ self.division.name }: None" : ''
    end

  end

  alias name summary

end

# ClientMarketingDivision.auto_migrate!		# Warning: Running this will clear the table!
