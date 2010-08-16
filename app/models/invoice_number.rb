class InvoiceNumber
  include DataMapper::Resource
  
  # Simply used to GENERATE NEXT INVOICE NUMBER!

  property :id,       Serial    # <-- The id provides our seqential invoice numbers.
  property :prefix,   String,   :required => true, :length => 2
  property :trip_id,  Integer,  :required => false


  # CLASS HELPER to create a new invoice id and return it's formatted invoice number
  def self.generate_for( company_id, trip_id = nil )

    prefix = Company.get(company_id.to_i).initials

    new_record = InvoiceNumber.create(
      :prefix   => prefix,
      :trip_id  => trip_id
    )

    return new_record.invoice_name

  end



  # Helper to derive main invoice number from properties: Eg: "SE12345":
  def main_invoice_number
    return "#{ self.prefix }#{ self.id }"
  end

  # Helper to tell us whether main invoice has already been created with this id:
  def main_invoice_exists?
    return MoneyIn.all( :name => "#{ self.main_invoice_number }", :is_deposit => false ).count() > 0
  end
  

  # Helper to generate an invoice number like "SE12345" or "SE12345/1"
  def invoice_name

    if self.main_invoice_exists?
      
      # Automatically derive next supplement number for this invoice_number:
      last_supplement_number = self.supplements.count()

      return "#{ self.main_invoice_number }/#{ last_supplement_number + 1 }"

    else

      return self.main_invoice_number

    end

  end

end


#InvoiceNumber.auto_migrate!		# Warning: Running this will clear the table!