require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/money_in_spec.rb


describe MoneyIn do
  
  before :all do

    require 'FileUtils' unless defined? FileUtils

    seed_lookup_tables()
    @company = Company.first_or_create( :initials => 'SE' )
    
    # Override default paths in app_settings:
    @doc_folder_path    = CRM[:doc_folder_path]    = 'C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/(Sample Documents)'
    @doc_templates_path = CRM[:doc_templates_path] = 'C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/(Sample Templates)'
    
    # Ensure we have template documents:
    #Document.doc_builder_templates_path

    # TODO Read live path from live environment: AppSetting.first( :repository => repository(:production), :name => 'doc_templates_path' ).value
    live_doc_templates_path = '//selfs/Documents/Templates'

    # Eg: //selfs/Documents/Templates/SE_Invoice.doc | SE_InvoiceSupp.doc | SE_CreditNote.doc
    @live_main_invoice_template_path = live_doc_templates_path / Document.new( :document_type_id => DocumentType::MAIN_INVOICE ).default_document_template_file
    @live_supp_invoice_template_path = live_doc_templates_path / Document.new( :document_type_id => DocumentType::SUPP_INVOICE ).default_document_template_file
    @live_cred_invoice_template_path = live_doc_templates_path / Document.new( :document_type_id => DocumentType::CREDIT_NOTE  ).default_document_template_file
    
    @main_invoice_template_path = @doc_templates_path / Document.new( :document_type_id => DocumentType::MAIN_INVOICE ).default_document_template_file
    @supp_invoice_template_path = @doc_templates_path / Document.new( :document_type_id => DocumentType::SUPP_INVOICE ).default_document_template_file
    @cred_invoice_template_path = @doc_templates_path / Document.new( :document_type_id => DocumentType::CREDIT_NOTE  ).default_document_template_file
    
    # Copy live templates to our test folder:
    FileUtils.copy( @live_main_invoice_template_path, @main_invoice_template_path ) if File.exist?(@live_main_invoice_template_path)
    FileUtils.copy( @live_supp_invoice_template_path, @supp_invoice_template_path ) if File.exist?(@live_supp_invoice_template_path)
    FileUtils.copy( @live_cred_invoice_template_path, @cred_invoice_template_path ) if File.exist?(@live_cred_invoice_template_path)

    # For debugging:
    @do_not_destroy_records_while_attempting_to_debug = false
    
  end

	before :each do

    # Reset InvoiceNumbers:
    InvoiceNumber.auto_migrate!

    @main_invoice_number    = "#{ @company.initials }1"
    @supp_invoice_number    = "#{ @company.initials }1/1"
    @supp_invoice_number2   = "#{ @company.initials }1/2"
    @credit_invoice_number  = "#{ @company.initials }1/1C"
    @credit_invoice_number2 = "#{ @company.initials }1/2C"

    @invoice      = MoneyIn.new( valid_invoice_attributes )
    @invoice2     = MoneyIn.new( valid_invoice_attributes.merge( :name => @main_invoice_number ) )
    @supp_invoice = MoneyIn.new( valid_invoice_attributes )
    
    # Copy live templates to our test folder if missing:
    # (This has already been done by before:all but some tests may have renamed or deleted a template)
    FileUtils.copy( @live_main_invoice_template_path, @main_invoice_template_path ) if File.exist?(@live_main_invoice_template_path) && !File.exist?(@main_invoice_template_path)
    FileUtils.copy( @live_supp_invoice_template_path, @supp_invoice_template_path ) if File.exist?(@live_supp_invoice_template_path) && !File.exist?(@supp_invoice_template_path)
    FileUtils.copy( @live_cred_invoice_template_path, @cred_invoice_template_path ) if File.exist?(@live_cred_invoice_template_path) && !File.exist?(@cred_invoice_template_path)
    
  end

	after :each do

    # Delete all test invoices!
    unless @do_not_destroy_records_while_attempting_to_debug
      MoneyIn.all.destroy!
      Document.all.destroy!   # This also deletes any generated doc files for us.
    end
    
  end
  
  after :all do

    @company.destroy!

  end



  it "should have copies of template docs ready for testing" do

    # To help with debugging:
    puts " ! Failed to prepare test template: #{ @main_invoice_template_path }" unless File.exist?(@main_invoice_template_path)
    puts " ! Failed to prepare test template: #{ @supp_invoice_template_path }" unless File.exist?(@supp_invoice_template_path)
    puts " ! Failed to prepare test template: #{ @cred_invoice_template_path }" unless File.exist?(@cred_invoice_template_path)

    File.exist?(@main_invoice_template_path).should be_true
    File.exist?(@supp_invoice_template_path).should be_true
    File.exist?(@cred_invoice_template_path).should be_true
    
  end



  it "should be valid" do
    # To help with debugging:
    puts @invoice.errors.inspect unless @invoice.valid?
    @invoice.should be_valid
    @invoice.document.should be_nil
  end

  it "should require client" do
		@invoice.client_id = nil  
    @invoice.should_not be_valid
    @invoice.errors.on(:client_id).to_s.should match /must not be blank/
  end

  it "should report missing MAIN invoice template when validating" do

    File.delete(@main_invoice_template_path) if File.exist?(@main_invoice_template_path)

    @invoice.should_not be_valid
    @invoice.document.should be_nil
    
    @invoice.errors.should have(2).item
    @invoice.errors.on(:document_template_file).to_s.should match /not.*found/  # Error collected from document

  end


  it "should report missing SUPP invoice template when validating" do
    
    File.delete(@supp_invoice_template_path) if File.exist?(@supp_invoice_template_path)

    main_invoice = MoneyIn.new( valid_invoice_attributes )
    main_invoice.save.should be_true
    supp_invoice = MoneyIn.new( valid_invoice_attributes.merge( :name => main_invoice.number ) )

    supp_invoice.should_not be_valid
    supp_invoice.document.should be_nil
    
    supp_invoice.errors.should have(2).items
    supp_invoice.errors.on(:document_template_file).to_s.should match /not.*found/  # Error collected from document
    
  end
  
  
  it "should report missing CREDIT template when validating" do
    
    File.delete(@cred_invoice_template_path) if File.exist?(@cred_invoice_template_path)
    
    main_invoice = MoneyIn.new( valid_invoice_attributes )
    main_invoice.save.should be_true
    credit_note = MoneyIn.new( valid_invoice_attributes.merge( :name => "#{ main_invoice.number }/C" ) )
    
    credit_note.should_not        be_valid
    credit_note.document.should            be_nil
    
    credit_note.errors.should have(2).items
    credit_note.errors.on(:document_template_file).to_s.should match /not.*found/  # Error collected from document

  end



  it "should identify itself as a MAIN invoice" do

    # Before save:
    @invoice.should               be_valid
    @invoice.main_invoice?.should be_true
    @invoice.supp_invoice?.should be_false
    @invoice.credit_note?.should  be_false
    @invoice.deposit?.should      be_false
    
    # And the same tests after save:
    @invoice.save.should          be_true
    @invoice.main_invoice?.should be_true
    @invoice.supp_invoice?.should be_false
    @invoice.credit_note?.should  be_false
    @invoice.deposit?.should      be_false
    
  end

  it "should identify itself as a SUPP invoice" do

    @invoice.save.should be_true

    supp_invoice = MoneyIn.new( valid_invoice_attributes.merge( :name => @invoice.number ) )
    
    # Before save:
    supp_invoice.should               be_valid
    supp_invoice.main_invoice?.should be_false
    supp_invoice.supp_invoice?.should be_true
    supp_invoice.credit_note?.should  be_false
    supp_invoice.deposit?.should      be_false
    
    # And the same tests after save:
    supp_invoice.save.should          be_true
    supp_invoice.main_invoice?.should be_false
    supp_invoice.supp_invoice?.should be_true
    supp_invoice.credit_note?.should  be_false
    supp_invoice.deposit?.should      be_false
    
  end

  it "should identify itself as a CREDIT invoice" do

    @invoice.save.should be_true
    supp_invoice = MoneyIn.create( valid_invoice_attributes.merge( :name => @invoice.number ) )
    credit_note  = MoneyIn.new(    valid_invoice_attributes.merge( :name => "#{ @invoice.number }/C" ) )
    
    # Before save:
    credit_note.should                be_valid
    credit_note.main_invoice?.should  be_false
    credit_note.supp_invoice?.should  be_false
    credit_note.credit_note?.should   be_true
    credit_note.deposit?.should       be_false
    
    # And the same tests after save:
    credit_note.save.should           be_true
    credit_note.main_invoice?.should  be_false
    credit_note.supp_invoice?.should  be_false
    credit_note.credit_note?.should   be_true
    credit_note.deposit?.should       be_false
    
  end

  it "should identify itself as a DEPOSIT" do

    deposit = MoneyIn.new( valid_invoice_attributes.merge( :name => @invoice.number, :is_deposit => true ) )
    
    # Before save:
    deposit.should                be_valid
    deposit.main_invoice?.should  be_false
    deposit.supp_invoice?.should  be_false
    deposit.credit_note?.should   be_false
    deposit.deposit?.should       be_true
    
    # And the same tests after save:
    deposit.save.should           be_true
    deposit.main_invoice?.should  be_false
    deposit.supp_invoice?.should  be_false
    deposit.credit_note?.should   be_false
    deposit.deposit?.should       be_true
    
  end


  it "should be valid when Main Invoice deposit is zero" do
		@invoice.deposit = 0
    @invoice.should be_valid
  end

  it "should not be valid when Main Invoice amount is zero" do
		@invoice.amount = 0
    @invoice.should_not be_valid
  end

  it "should not be valid when Main Invoice amount is negative" do
		@invoice.amount = -100
    @invoice.should_not be_valid
  end

  it "should not be valid when Main Invoice deposit is negative" do
		@invoice.deposit = -100
    @invoice.should_not be_valid
  end

  it "should not be valid when Supp Invoice amount is zero" do
    @invoice.number = @main_invoice_number
		@invoice.amount = 0
    @invoice.should_not be_valid
  end


  it "should derive main_invoice_id" do
    @invoice.number = @main_invoice_number
    @invoice.main_invoice_number.should == @main_invoice_number
    @invoice.number = @supp_invoice_number
    @invoice.main_invoice_number.should == @main_invoice_number
  end

  it "should know when invoice is new" do
    @invoice.main_invoice_exists?.should == false
  end

  it "should know when main invoice already exists" do

    main_invoice_number = 'SE123'
    
    @supp_invoice.number = "#{ main_invoice_number }/1"
    @supp_invoice.main_invoice_exists?.should be_false

    @invoice2.number = @supp_invoice.main_invoice_number
    @invoice2.save
    @supp_invoice.main_invoice_exists?.should be_true

  end


  it "should save new invoice with new number when number not provided" do

    @invoice.save.should be_true
    @invoice.name.should    == @main_invoice_number
    @invoice.number.should  == @main_invoice_number

    @invoice.history.should have(1).money_ins
    @invoice.deposits.should have(0).money_ins
    @invoice.supplements.should have(0).money_ins
    @invoice.credit_notes.should have(0).money_ins

  end
  

  it "should create deposit record automatically when creating main invoice" do

    @invoice.deposit = 100
    @invoice.amount  = 1000
    
    @invoice.save.should be_true
    @invoice.name.should == @main_invoice_number
    @invoice.history.should have(2).money_ins
    @invoice.deposits.should have(1).money_ins
    @invoice.supplements.should have(0).money_ins
    @invoice.credit_notes.should have(0).money_ins
    @invoice.deposits.first.main_invoice_number.should == @main_invoice_number
    
  end
  

  it "should not create deposit record automatically when creating supp invoice" do

    @invoice.deposit = 0
    @invoice.amount  = 1000
    @invoice.save.should be_true

    @supp_invoice.number  = @main_invoice_number
    @supp_invoice.deposit = 100
    @supp_invoice.amount  = 1000
    
    @supp_invoice.save.should be_true
    @supp_invoice.name.should == @supp_invoice_number
    @supp_invoice.history.should have(2).money_ins
    @supp_invoice.deposits.should have(0).money_ins
    @supp_invoice.supplements.should have(1).money_ins
    @supp_invoice.credit_notes.should have(0).money_ins
    
  end
  
  
  # TODO: Move this test to money_in_spec!
  it 'should calculate total_requested' do
    
    @invoice.deposit = 100
    @invoice.amount  = 1000
    
    # Before save:
    @invoice.deposits.should have(0).money_ins
    @invoice.history.should have(0).money_ins
    @invoice.total_requested.should == 0
    
    # After save:
    @invoice.save.should be_true
    @invoice.deposits.should have(1).money_ins
    @invoice.history.should have(2).money_ins
    @invoice.total_deposits.should == @invoice.deposit
    @invoice.total_requested.should == @invoice.deposit + @invoice.amount
    
    # After adding a supp invoice too:
    @invoice2.amount = 500
    @invoice2.save.should be_true
    @invoice2.deposits.should have(1).money_ins
    @invoice2.history.should have(3).money_ins
    @invoice2.total_deposits.should == @invoice.deposit
    @invoice2.total_requested.should == @invoice.deposit + @invoice.amount + @invoice2.amount
    
  end


  it "should fetch supplemental invoices for a specified invoice number" do

    # Prepare data:
    main_invoice_attrs = valid_invoice_attributes.merge( :amount => 1000, :deposit => 100 )
    supp_invoice_attrs = valid_invoice_attributes.merge( :amount => 400,  :name => @main_invoice_number )

    # Create main invoice and deposit record:
    main_invoice = MoneyIn.new( main_invoice_attrs )
    main_invoice.save.should be_true
    main_invoice.deposits.should have(1).money_ins
    main_invoice.history.should have(2).money_ins
    main_invoice.supplements.should have(0).money_ins

    # Create supp invoice:
    supp_invoice = MoneyIn.new( supp_invoice_attrs )
    supp_invoice.save.should be_true
    supp_invoice.main_invoice_exists?.should == true
    supp_invoice.deposits.should have(1).money_ins
    supp_invoice.history.should have(3).money_ins
    supp_invoice.supplements.should have(1).money_ins
    main_invoice.supplements.should have(1).money_ins
        
  end


  it "should save new invoice as 1st supplemental when number exists" do

    main_invoice = MoneyIn.create( valid_invoice_attributes )
    
    @invoice.name = @main_invoice_number
    @invoice.main_invoice_exists?.should == true

    @invoice.save
    @invoice.name.should == @supp_invoice_number

  end


  it "should save new invoice as 2nd supplemental when 1st supplemental exists" do

    main_invoice = MoneyIn.create( valid_invoice_attributes )
    supp_invoice = MoneyIn.create( valid_invoice_attributes.merge( :name => @main_invoice_number ) )
    
    @invoice.name = @main_invoice_number
    @invoice.main_invoice_exists?.should == true

    @invoice.save
    @invoice.name.should == @supp_invoice_number2

  end


  it "should save new invoice as 1st credit note when number exists & number/C is provided" do

    main_invoice = MoneyIn.create( valid_invoice_attributes )
    
    @invoice.name = "#{ main_invoice.number }/C"
    @invoice.main_invoice_exists?.should == true

    @invoice.save
    @invoice.name.should == @credit_invoice_number

  end


  it "should save new invoice with 2nd credit note number when 2nd number/C is provided" do

    main_invoice = MoneyIn.create( valid_invoice_attributes )
    supp_invoice = MoneyIn.create( valid_invoice_attributes.merge( :name => main_invoice.number ) )
    
    @invoice.name = "#{ main_invoice.number }/C"
    @invoice.main_invoice_exists?.should == true

    @invoice.save.should be_true
    @invoice.name.should == @credit_invoice_number2

  end


  it "should always save credit note amount as a negative value" do

    main_invoice = MoneyIn.create( valid_invoice_attributes )
    supp_invoice = MoneyIn.create( valid_invoice_attributes.merge( :name => main_invoice.number ) )

    credit_note  = MoneyIn.new( valid_invoice_attributes.merge( :name => "#{ main_invoice.number }/C" ) )
    credit_note.main_invoice_exists?.should == true
    
    # Create with negative amount:
    credit_note.amount = -100
    credit_note.save.should be_true
    credit_note.amount.should == -100

    credit_note  = MoneyIn.new( valid_invoice_attributes.merge( :name => "#{ main_invoice.number }/C" ) )
    credit_note.main_invoice_exists?.should == true
    
    # Create with positive amount:
    credit_note.amount = 200
    credit_note.save.should be_true
    credit_note.amount.should == -200
    
    # Update with positive amount: (Updates should never happen but we might as well be on the safe side!)
    credit_note.amount = 300
    credit_note.save.should be_true
    credit_note.amount.should == -300
    
    # Update with negative amount: (Updates should never happen but we might as well be on the safe side!)
    credit_note.amount = -400
    credit_note.save.should be_true
    credit_note.amount.should == -400

  end
  
  

  it "should retrieve client" do
    
    @invoice.deposit = 100
    @invoice.save.should be_true
    @invoice.deposits.should have(1).money_in

    invoice = MoneyIn.get( @invoice.id )
    invoice.client_id.should == 1
    
  end



  it "should derive invoice due_date from trip.start_date and company.due_days" do

    # This should never happen but in the absence of a trip, default to 28 days from now:
    @invoice.trip = nil
    @invoice.due_date.to_s.should == ( Date.today + 28 ).to_s

    # Here's the proper test:
    @invoice      = MoneyIn.new( valid_invoice_attributes )
    @invoice.trip = Trip.first_or_create( { :id => 1 }, valid_trip_attributes )
    @invoice.due_date.to_s.should == ( @invoice.trip.start_date - @invoice.company.due_days ).to_s

  end


  it "should not generate documents when initialising document object" do

		document = Document.new(
      :invoice_id                 => 1,
      :trip_id					          => 1,
      :client_id				          => 1,
      :company_id				          => 1,
      :user_id					          => 1,
      :created_by                 => 'Tester',
      :document_type_id	          => DocumentType::MAIN_INVOICE,
      :generate_doc_after_create	=> false,
      :generate_doc_later	        => false
    )
          
    document.should be_a Document
    document.should be_valid
    document.file_exist?.should be_false
    document.doc_builder_output.should be_blank

  end


  
  it "should not generate documents while validating" do
    
    client = Client.first_or_create( { :id => 1 }, valid_client_attributes )
    trip   = Trip.first_or_create(   { :id => 1 }, valid_trip_attributes   )
    
    # Trigger validation to create dummy document object that does not get saved:
    @invoice.valid?.should be_true
    @invoice.document.should be_nil
    trip.reload.documents.should have(0).documents
    
    # Delete old copy of doc if there is one:
    doc_path = @invoice.doc_path
    File.delete(doc_path) if File.exist?(doc_path)
    File.exist?(doc_path).should_not be_true
    
    # Trigger validation to create dummy document object that does not get saved:
    @invoice.valid?.should be_true
    @invoice.document.should be_nil
    trip.reload.documents.should have(0).documents

    File.exist?(doc_path).should_not be_true

  end



  it "should generate MAIN invoice document file" do
    
    client = Client.first_or_create( { :id => 1 }, valid_client_attributes )
    trip   = Trip.first_or_create(   { :id => 1 }, valid_trip_attributes   )
    
    # Trigger validation to create dummy document object that does not get saved:
    @invoice.valid?.should be_true
    trip.reload.documents.should have(0).documents
    
    # Delete old copy of doc if there is one:
    doc_path = @invoice.doc_path
    File.delete(doc_path) if File.exist?(doc_path)
    File.exist?(doc_path).should_not be_true

    @invoice.skip_doc_generation = false
    @invoice.save.should be_true
    @invoice.document.should be_valid
    @invoice.document.reload
    # puts " SPEC doc_builder_output : " + credit_note.document.doc_builder_output
    
    @invoice.document.doc_path.should_not be_blank
    @invoice.document.file_exist?.should be_true
    
    trip.reload
    trip.documents[0].document_type_id.should == DocumentType::MAIN_INVOICE
    trip.documents.should have(1).documents
    
  end


  it "should generate SUPP invoice document file" do
    
    client = Client.first_or_create( { :id => 1 }, valid_client_attributes )
    trip   = Trip.first_or_create(   { :id => 1 }, valid_trip_attributes   )

    @invoice.skip_doc_generation = false
    @invoice.save.should be_true
    supp_invoice = MoneyIn.new( valid_invoice_attributes.merge( :name => @invoice.number ) )
    
    # Trigger validation to create dummy document object:
    supp_invoice.valid?.should be_true
    trip.reload.documents.should have(1).documents
    
    # Delete old copy of doc if there is one:
    doc_path = supp_invoice.doc_path
    File.delete(doc_path) if File.exist?(doc_path)
    File.exist?(doc_path).should_not be_true

    supp_invoice.skip_doc_generation = false
    supp_invoice.save.should be_true
    supp_invoice.document.should be_valid
    supp_invoice.document.reload
    # puts " SPEC doc_builder_output : " + credit_note.document.doc_builder_output
    
    supp_invoice.document.doc_path.should_not be_blank
    supp_invoice.document.file_exist?.should be_true
    
    trip.reload
    trip.documents[0].document_type_id.should == DocumentType::MAIN_INVOICE
    trip.documents[1].document_type_id.should == DocumentType::SUPP_INVOICE
    trip.documents.should have(2).documents
    
  end


  it "should generate CREDIT invoice document file" do
    
    client = Client.first_or_create( { :id => 1 }, valid_client_attributes )
    trip   = Trip.first_or_create(   { :id => 1 }, valid_trip_attributes   )

    @invoice.skip_doc_generation = false
    @invoice.save.should be_true
    trip.reload.documents.should have(1).documents

    credit_note = MoneyIn.new( valid_invoice_attributes.merge( :name => "#{ @invoice.number }/C" ) )
    
    # Trigger validation to create dummy document object:
    credit_note.valid?.should be_true
    
    # Delete old copy of doc if there is one:
    doc_path = credit_note.doc_path
    File.delete(doc_path) if File.exist?(doc_path)
    File.exist?(doc_path).should_not be_true

    credit_note.skip_doc_generation = false
    credit_note.save.should be_true
    credit_note.document.should be_valid
    credit_note.document.reload
    # puts " SPEC doc_builder_output : " + credit_note.document.doc_builder_output

    credit_note.document.doc_path.should_not be_blank
    credit_note.document.file_exist?.should be_true
    
    trip.reload
    trip.documents[0].document_type_id.should == DocumentType::MAIN_INVOICE
    trip.documents[1].document_type_id.should == DocumentType::CREDIT_NOTE
    trip.documents.should have(2).documents

  end


  it "should not generate invoice document file now when generate_doc_later is specified" do
    
    client = Client.first_or_create( { :id => 1 }, valid_client_attributes )
    trip   = Trip.first_or_create(   { :id => 1 }, valid_trip_attributes   )
    
    # Trigger validation to create dummy document object that does not get saved:
    @invoice.skip_doc_generation = false
    @invoice.generate_doc_later  = true
    @invoice.valid?.should be_true
    trip.reload.documents.should have(0).documents
    
    # Delete old copy of doc if there is one:
    doc_path = @invoice.doc_path
    File.delete(doc_path) if File.exist?(doc_path)
    File.exist?(doc_path).should_not be_true
    
    @invoice.save.should be_true
    @invoice.document.should be_a Document          # Should have a document object but
    @invoice.document.file_exist?.should be_false   # no physical doc file.
    
    trip.reload
    trip.documents.should have(1).documents
    
    #  Kernel::sleep 10
    #  trip.reload
    #  trip.documents.should have(1).documents
    #  @invoice.reload
    #  @invoice.document.should be_a Document          # Should have a document object
    #  @invoice.document.file_exist?.should be_false   # but no physical file.
    
  end


  #  # Depricated feature
  #  it "should generate MAIN invoice document file later when specified" do
  #    
  #    client = Client.first_or_create( { :id => 1 }, valid_client_attributes )
  #    trip   = Trip.first_or_create(   { :id => 1 }, valid_trip_attributes   )
  #    
  #    # Trigger validation to create dummy document object that does not get saved:
  #    @invoice.valid?.should be_true
  #    trip.reload.documents.should have(0).documents
  #    
  #    # Delete old copy of doc if there is one:
  #    doc_path = @invoice.doc_path
  #    File.delete(doc_path) if File.exist?(doc_path)
  #    File.exist?(doc_path).should_not be_true
  #
  #    @invoice.skip_doc_generation = false
  #    @invoice.generate_doc_later  = true
  #    @invoice.save.should be_true
  #    @invoice.document.should be_a Document
  #    @invoice.document.file_exist?.should be_false
  #    
  #    trip.reload
  #    trip.documents.should have(1).documents
  #    
  #    Kernel::sleep 10
  #    @invoice.document.file_exist?.should be_true
  #
  #  end

end




