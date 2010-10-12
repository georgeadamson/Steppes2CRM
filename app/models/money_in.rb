class MoneyIn
  include DataMapper::Resource
  
  
  # AKA client INVOICE.
  #
  # Formerly known as PricesDueIn.
  # One MoneyIn object can represent a Deposit, Main Invoice, Supplementary Invoice or Credit Note.
  
  # Note: Check the invoice.document property for errors after saving:
  #       The invoice might save ok but the document object may be invalid!
  
  
  DEFAULT_NEW_MAIN_INVOICE_NAME = 'NEW'                     unless defined?(DEFAULT_NEW_MAIN_INVOICE_NAME)
  OTHERWISE_RETURN_NO_MATCHES   = '-NON_EXISTENT_INVOICE-'  unless defined?(OTHERWISE_RETURN_NO_MATCHES)  # Fake invoice number for returning no matches when searching.
  
  property :id,                 Serial
  property :name,               String,     :required => true,  :default => DEFAULT_NEW_MAIN_INVOICE_NAME   # AKA PaymentRef or InvoiceNumber in old database
  property :trip_id,            Integer,    :required => true   # The trip that the client is paying for.
  property :client_id,          Integer,    :required => true   # The client being invoiced.
  property :amount,             BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2  # AMOUNT DUE
  property :biz_supp_amount,    BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2
  property :single_supp_amount, BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2
  property :adjustment_amount,  BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2
  property :adjustment_name,    String,     :required => true,  :default => 'Custom adjustment'
  property :total_amount,       BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2  # INCLUDES amounts already paid!
  property :amount_received,    BigDecimal, :required => true,  :default => 0,  :precision  => 12, :scale	=> 2
  property :due_date,           Date,       :required => true,  :default => lambda{ |obj,prop| obj.default_due_date }
  property :received_date,      DateTime
  property :is_deposit,         Boolean,    :required => true,  :default => false
  property :is_received,        Boolean,    :required => true,  :default => false
  property :payment_method,     String
  #property :travellers,         Integer,    :required => true,  :default => lambda{ |invoice,prop| invoice.clients.length }
  property :narrative,          Text,       :required => false  # Text => nvarchar(MAX) in sqlserver.
  property :company_id,         Integer,    :required => false
  property :user_id,            Integer,    :required => true   # TODO: May need only be required for new invoices.
  property :document_id,        Integer,    :required => false
  property :created_at,         DateTime,   :required => true,  :default => lambda{ |obj,prop| DateTime.now }
  
  belongs_to :trip
  belongs_to :client  #, :model => "Client", :child_key => [:client_id]
  belongs_to :company
  belongs_to :user
  belongs_to :document          # Relates invoice to it's generated document.
  
  # Associate clients with the invoices that paid for them:
  has n, :money_in_clients
  has n, :clients, :through => :money_in_clients
  
  #accepts_nested_attributes_for :clients
  accepts_ids_for :clients
  
  # Attempt to ensure credit note value is negative:
  # Depricated because it assumes number has already been set so we'd know whether this is a credit note.
  #  def amount=(value)
  #    value = 0 - value.to_f if self.credit_note? && value.to_f > 0
  #    attribute_set( :amount, value )
  #  end
  
  # Flags to prevent immediate document generation: (Or switch it off completely when testing)
  attr_accessor :generate_doc_later
  attr_accessor :skip_doc_generation
  
  # Expose a 'draft' flag to tell us whether we should record a real invoice:
  attr_accessor :draft
  alias draft? draft
  
  alias number          name
  alias number=         name=
  alias invoice_number  name
  alias invoice_number= name=
  alias payment_ref     name
  alias payment_ref=    name=
  alias deposit?        is_deposit
  alias received?       is_received
  alias invoice_date    created_at
  alias invoice_date=   created_at=
  
  
  validates_with_method :amount, :method => :validate_amount
  validates_with_method :validate_generate_doc #, :when => :doc_gen
  
  def validate_amount
    
    if self.amount == 0 && !self.deposit?
      
      return [ false, "An invoice for nothing? Stop wasting my time!" ]
      
    elsif self.amount < 0 && ( self.main_invoice? || self.supp_invoice? )
      
      return [ false, "An invoice for a negative amount? Surely a credit note would be a better idea?" ]
      
    elsif self.deposit < 0 && self.main_invoice?
      
      return [ false, "A main invoice with a negative deposit? How's that going to work?!" ]
      
    elsif self.main_invoice? && self.deposit.zero?
      
      # Depricated: Turns out we do have to allow zero deposit occasionally: (Eg when trip is a prize)
      # return [ false, "A main invoice with no deposit? That does not seem right to me" ]
      return true
      
    else
      return true
    end
    
    
  end
  
  
  def validate_generate_doc
    
    # Skip this validation for deposits:
    # For other invoices etc, any doc-gen errors will be added to self.errors:
    if self.deposit? || self.generate_doc( dummy_run = true )
      
      return true
      
    else
      
      return [ false, "It would not be possible to generate the document" ]
      
    end
    
  end
  
  
  
  
  # Note: This model calls self.calc_defaults() when initialising.
  
  before :valid? do
    
    self.name               = DEFAULT_NEW_MAIN_INVOICE_NAME if self.name.blank?
    self.user             ||= self.trip && self.trip.user
    
    # Ensure submitted currency strings such as "123.00" are valid decimals:
    self.amount             = self.amount.to_f
    self.amount_received    = self.amount_received.to_f
    self.adjustment_amount  = self.adjustment_amount.to_f
    
  end
  
  
  
  before :save do
    
    self.company_id ||= self.trip.company_id
    
    # Ensure credit notes are saved with a negative amount:
    self.amount = 0 - self.amount if self.credit_note? && self.amount > 0
    
    
    # Rules for new invoices:
    # When name is '' or 'NEW'  => Generate new invoice number
    # When name is 'SE123'      => Generate supplementary invoice 'SE123/1'
    # When name is 'SE123/n'    => Generate supplementary invoice 'SE123/n+1' (but derive n from count of existing records!)
    # When name is 'SE123/C'    => Generate credit-note   invoice 'SE123/1C'
    # When generating new main invoice and deposit is set => Generate deposit as well
    
    if self.new? 
      
      # When a main invoice number has been provided...
      # Automatically derive next SUPPLEMENT or CREDIT NOTE for the invoice_number if necessary:
      if self.main_invoice_exists?
        
        supp_number = self.supplements.count() + 1
        suffix      = self.credit_note? ? 'C' : ''
        self.name   = "#{ self.main_invoice_number }/#{ supp_number }#{ suffix }"
        
      # Or generate NEW MAIN INVOICE:
      # TODO: Wrap the deposit creation in a transaction?
      elsif self.valid? && self.new_main_invoice?
        
        main_invoice      = self
        main_invoice.name = InvoiceNumber.generate_for( self.company_id, self.trip_id )
        
        # If is_deposit flag was set then automatically create a new deposit row:
        if defined?(@deposit_amount_for_main_invoice) && @deposit_amount_for_main_invoice > 0 && !self.is_deposit
          
          MoneyIn.create!(
            main_invoice.attributes.merge(
              :is_deposit => true,
              :narrative  => '',
              :amount     => @deposit_amount_for_main_invoice,
              :skip_doc_generation => true  # Just a belt and braces precaution. Deposits shoud not generate docs even when this flag is set.
            )
          )
          
        end
        
      end
      
    end
    
  end  
  
  
  after :create do
    
    # Automatically generate a DOCUMENT for anything other than a deposit:
    self.generate_doc() unless self.deposit? || @skip_doc_generation
    
  end
  
  
  after :save do
    
    # Trip becomes CONFIRMED when MAIN INVOICE is created:
    self.trip.update!( :status_id => Trip::CONFIRMED ) if self.trip && self.trip.unconfirmed? && self.main_invoice? && self.total_requested > 0
    
    # Recalculate client total_spend:
    self.client.update_total_spend!
    
  end
  
  
  
  
  # Helper to create a new document object for this invoice and generate a word doc:
  def generate_doc( dummy_run = false )
    
    document_status_id = false
    
    # Only proceed if this type of invoice has a corresponding document_type_id:
    if self.default_document_type_id
      
      Merb.logger.info "money_in.generate_doc (document_type_id #{ self.default_document_type_id })"  if !dummy_run
      Merb.logger.info "Skipping doc generation (because money_in.skip_doc_generation is true)"       if !dummy_run && @skip_doc_generation
      
			new_document = Document.new(
				:invoice_id                 => self.id,
        :trip_id					          => self.trip_id,
				:client_id				          => self.client_id,
				:company_id				          => self.company_id,
				:user_id					          => self.user_id,
        :created_by                 => self.user && self.user.preferred_name,
				:document_type_id	          => self.default_document_type_id,       # Main Invoice / Credit note / Supp invoice.
				:generate_doc_after_create	=> !dummy_run && !@skip_doc_generation, # @skip_doc_generation is for debugging only.
				:generate_doc_later	        => self.generate_doc_later || false     # This feature not yet available in models.
			)
      
      if new_document.nil?

        # Doc init failed.
        Merb.logger.error "Unable to save document details for new money_in record #{ self.id }: Could not initialise a new document record"
        
      elsif dummy_run
        
        if new_document.valid?
          
          # The dry-run succeeded:
          Merb.logger.info "Dummy run: Document looks valid and document.save would probably succeed!"
          document_status_id = new_document.document_status_id
          
        else
          # The dry-run failed. The error messages will be collected from the document object.
        end
        
      elsif ( self.document = new_document ) && !self.document.valid?
        
        # Validation failed. The error messages will be collected from the document object.
        Merb.logger.error "Unable to save document details for new money_in record #{ self.id }. #{ self.document.errors.inspect }"
        
      elsif self.document.save
        
        # Exit with SUCCESS!
        Merb.logger.info "Document #{ self.document.id } details saved successfully for new money_in record #{ self.id }"
        document_status_id = self.document.document_status_id
        
      else
        
        # Save failed. The error messages will be collected from the document object.
        Merb.logger.error "Failed to save document details for new money_in record #{ self.id }. #{ self.document.errors.inspect }"
        
      end

      # Attempt to retrieve error details from the document into this money_in object:
      # collect_child_error_messages_for self, self.document
      new_document.errors.each_pair{|name,desc| self.errors.add name,[desc].flatten.join(', ') } if new_document && new_document.errors

      # Make a note of the doc_path while we have it. Only used for debugging & testing:
      @doc_path = new_document.doc_path
      
      if dummy_run
        new_document.destroy!
        new_document = nil    
      end
      
    end
    
    return document_status_id || false
    
  end
  
  
  
  
  
  # Return true if invoice_number does not indicate a supplement number:
  # Important: This flag must work both before and after the object is saved.
  def main_invoice?
    self.name && !self.is_deposit && self.name !~ /\// && ( self.new_main_invoice? || !self.supp_invoice? )
  end
  
  # Return true if invoice_number ends with '/number':
  # Important: This flag must work both before and after the object is saved.
  # Note: The first part of the logic may not be necessary but can help to avoid a database call in main_invoice_exists?)
  def supp_invoice?
    #!( self.new? && self.main_invoice_number.blank? || self.main_invoice_number == DEFAULT_NEW_MAIN_INVOICE_NAME ) \
    self.name && !self.new_main_invoice? && ( self.name =~ /\/[0-9]+$/ || ( self.new? && !self.credit_note? && self.main_invoice_exists? ) )
  end
  
  # Return true if invoice_number ends with 'C':
  # Important: This flag must work both before and after the object is saved.
  def credit_note?
    self.name && self.name =~ /C$/i
  end
  
  # TODO: Depricate these? (The "is_" naming was intended to be consistent with the is_deposit property)
  alias is_main_invoice main_invoice? 
  alias is_credit_note  credit_note?  
  alias is_supplement   supp_invoice? 
  alias supplement?     supp_invoice? 
  
  
  
  # When DEPOSIT is set on a main invoice, a new deposit row will be created automatically:
  def deposit=(value)
    @deposit_amount_for_main_invoice = value.to_f
  end
  
  # Return DEPOSIT if the deposit attribute has been set, otherwise return total deposits for this invoice:
  def deposit
    
    if self.deposit?
      return self.amount
    elsif defined?(@deposit_amount_for_main_invoice) && self.main_invoice?
      return @deposit_amount_for_main_invoice || 0
    else
      return self.total_deposits
    end
    
  end
  
  
  
  # Helper to derive main invoice number from properties: Eg: "SE123/2" => "SE123"
  def main_invoice_number
    return self.name.split('/').shift()
  end
  
  # Helper to return the main invoice if it exists:
  def main_invoice
    return MoneyIn.first( :name => self.main_invoice_number, :is_deposit => false )
  end
  
  # Helper to tell us whether main invoice has already been created with this id:
  def main_invoice_exists?
    #return !self.main_invoice_number.blank? && 
    #  self.main_invoice_number != DEFAULT_NEW_MAIN_INVOICE_NAME && 
    return !self.new_main_invoice? && MoneyIn.all( :name => self.main_invoice_number, :is_deposit => false ).count() > 0
  end
  
  # Total amount received: (including all deposits, supplements and credits)
  def total_received
    return self.history.sum(:amount_received) || 0
  end
  
  # Total amount invoiced: (including all deposits, supplements and credits)
  def total_requested
    return self.history.sum(:amount) || 0
  end
  
  # Return a negative amount for money owed, or positive when in credit: (including all deposits, supplements and credits)
  def total_balance
    return self.total_received - self.total_requested
  end
  
  def total_deposits
    return self.deposits.sum(:amount) || 0
  end
  
  
  # Helper to count how many clients this invoice is paying for:
  def travellers
    return self.clients.length
  end
  
  
  
  # Helper to return ALL related MoneyIn objects of ANY TYPE:
  # Eg: Everything matching 'SA123' or 'SA123/*'
  # Warning: Do not be tempted to simplify search to match "#{ main }%" because this could return false matches!
  def history
    main = self.main_invoice_number || OTHERWISE_RETURN_NO_MATCHES
    return MoneyIn.all( :name => main ) + MoneyIn.all( :name.like => "#{ main }/[123456789]%")
  end
  
  
  # Helper to return all related MoneyIn objects that are DEPOSITS:
  def deposits
    main = self.main_invoice_number || OTHERWISE_RETURN_NO_MATCHES
    return MoneyIn.all( :name => main, :is_deposit => true )
  end
  
  # Helper to return all related MoneyIn objects that are SUPPLEMENTARY invoices only:
  def supplements
    main = self.main_invoice_number || OTHERWISE_RETURN_NO_MATCHES
    return MoneyIn.all( :name.like => "#{ main }/[123456789]%", :is_deposit => false ).all( :name.like => "#{ main }/%[^C]" )
  end
  
  # Helper to return all related MoneyIn objects that are CREDITNOTES only:
  def credit_notes
    main = self.main_invoice_number || OTHERWISE_RETURN_NO_MATCHES
    return MoneyIn.all( :name.like => "#{ main }/[123456789]%C", :is_deposit => false )
  end
  
  
  
  # Helper to tell us which type of document we need to generate for this money_in:
  def default_document_type_id
    
    return case
      
    when self.main_invoice? then DocumentType::MAIN_INVOICE   # Use Main invoice template.
    when self.supp_invoice? then DocumentType::SUPP_INVOICE   # Use Supplematary invoice template.
    when self.credit_note?  then DocumentType::CREDIT_NOTE    # Use Credit note template.
    when self.deposit?      then nil                          # No template for deposits.
    else                         nil
      
    end
    
  end
  
  
  
  def default_narrative
    
    return '' if self.trip.nil?
    
    trip              = self.trip
    price_per_person  = self.total_amount / self.travellers
    destinations      = trip.countries_names.join(', ')
    
    return case trip.company_id
      
    when 1 #Steppes East
      "Re. Holiday to #{ destinations } #{ trip.date_summary } including international flights, domestic flights and accommodation with meals as specified, all transfers, sightseeing with private English speaking guide and entrance fees - all details as per the attached itinerary @ #{ price_per_person.to_currency(:uk) } per person."
    when 4 #Steppes Latin America
      "Re. Destination #{ destinations } #{ trip.date_summary } including international flights, domestic flights and accommodation with meals as specified, all transfers - all details as per the attached itinerary @ #{ price_per_person.to_currency(:uk) } per person."
      #when 2 #Steppes Africa
      #	"Re. Holiday to #{ destinations } #{ trip.date_summary } including international flights, domestic flights and accommodation with meals as specified, all transfers - all details as per the attached itinerary @ #{ price_per_person.to_currency(:uk) } per person."
      #when 3 #Discovery Initiatives
      #	"Re. Holiday to #{ destinations } #{ trip.date_summary } including international flights, domestic flights and accommodation with meals as specified, all transfers - all details as per the attached itinerary @ #{ price_per_person.to_currency(:uk) } per person."
      #when 5 #Steppes Travel (English)
      #	"Re. Holiday to #{ destinations } #{ trip.date_summary } including international flights, domestic flights and accommodation with meals as specified, all transfers - all details as per the attached itinerary @ #{ price_per_person.to_currency(:uk) } per person."
    else
      "Re. Holiday to #{ destinations } #{ trip.date_summary } including international flights, domestic flights and accommodation with meals as specified, all transfers - all details as per the attached itinerary @ #{ price_per_person.to_currency(:uk) } per person."
      
    end
    
  end
  
  
  # Calculate trip.start_date minus company.due_days
  def default_due_date
    
    if self.trip
      
      # The first two conditions here should always be present but the rest are there just in case:
      company = self.company || self.trip.company || ( self.trip.user && self.trip.user.company ) || ( self.user && self.user.company )
      
      return self.trip.start_date - ( company && company.due_days || 84 )
      
    else
      # This should never happen but in the absence of a trip, default to 28 days from now:
      Date.today + 28
    end
    
  end
  

  # Helper for deriving the full path of the document.
  # If document object has been created then return it's path.
  # If document object has not been created then run validation to set @doc_path variable.
  def doc_path
     return @doc_path ||= ( self.document && self.document.doc_path ) || ( self.valid? && @doc_path )
  end
  
  
  # Helper to set default values for a MoneyIn object:
  def calc_defaults
    
    # Ensure submitted currency strings such as "123.00" are valid decimals:
    self.amount             = self.amount.to_f
    self.amount_received    = self.amount_received.to_f
    self.adjustment_amount  = self.adjustment_amount.to_f
    
    
    # Calculate default values when creating a new invoice for a trip:
    if self.new_main_invoice? && self.trip
      
	    self.single_supp_amount = self.trip.calc( :total, :actual, :gross, :for_all, :singles,                       :final_prices => true, :string_format => false ) if self.single_supp_amount.zero?
	    self.biz_supp_amount    = self.trip.calc( :total, :actual, :gross, :for_all, :travellers, :biz_supp => true, :final_prices => true, :string_format => false ) if self.biz_supp_amount.zero?
    	
	    self.deposit						= self.trip.default_deposit unless defined?(@deposit_amount_for_main_invoice)
	    self.total_amount				= self.trip.total_price.zero? ? self.trip.calc( :daily, :actual, :gross, :for_all, :travellers, :with_all_extras => true, :final_prices => true, :string_format => false ) : self.trip.total_price if self.total_amount.zero?
      self.amount_received    = self.deposit if self.amount_received.zero?
      
	    # Default to assume invoice will pay for all clients on this trip:
	    self.clients.concat(trip.clients) if self.clients.empty?
      
      # Set default narrative last because it probably includes other properties:
      self.narrative        ||= self.default_narrative
      
    end
    
    # Calculate amount due:
    self.amount               = self.total_amount - self.amount_received if self.amount.zero?
    
    self.user_id            ||= self.trip.user_id if self.trip
    
  end
  
  
  
  def initialize( args = nil )
    
    super
    #self.calc_defaults()
    
  end
  



# Class methods:
  
  # Helper to provide a consistent 'friendly' name: (Used when users select content for reports etc)
  def self.class_display_name
    return 'Invoice'
  end
  
  
  # Define which properties are available in reports  
  def self.potential_report_fields
    return [ :name, :created_at, :amount, :is_deposit, :travellers, :narrative, :client, :trip, :company, :user, :clients, :trips ]
  end
  
  
protected
  
  def new_main_invoice?
    return self.new? && ( self.main_invoice_number.blank? || self.main_invoice_number == DEFAULT_NEW_MAIN_INVOICE_NAME )
  end

end

# This idea did not work:
# alias Invoice     MoneyIn
# alias Deposit     MoneyIn
# alias CreditNote  MoneyIn



# MoneyIn.auto_migrate!		# Warning: Running this will clear the table!
