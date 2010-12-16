require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/document_spec.rb

describe Document do

  before :all do

    seed_lookup_tables()
    
    @user               = User.first_or_create( {:id=>1}, valid_user_attributes )
    @client             = Client.create( valid_client_attributes )
    @company            = Company.first_or_create( {}, valid_company_attributes.merge( :initials => 'SV' ) )
    @document_template  = DocumentTemplate.create( valid_document_template_attributes )
    @trip               = Trip.first_or_create( {:id=>1}, valid_trip_attributes )
    
    # Ensure our test company has initials "SV" because we'll be using an SV doc template:
    @company.update!( :initials => 'SV' ) unless @company.initials == 'SV'

    # Override default paths in app_settings:
    CRM[:doc_folder_path]    = 'C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/(Sample Documents)'
    CRM[:doc_templates_path] = 'C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/(Sample Templates)'
    
    # Create a custom INI file for testing:
    Document.create_doc_builder_settings_file

    live_doc_templates_path = '//selfs/Documents/Templates'

    shell_command = "xcopy /E /D /Y \"#{ live_doc_templates_path.gsub(/\//,'\\') }\\*.doc\" \"#{ CRM[:doc_templates_path].gsub(/\//,'\\') }\""
    IO.popen(shell_command)

  end

  before :each do
    @document.destroy! unless @document.nil?
    @document = Document.new(valid_document_attributes)
  end

  after :all do
    @user.destroy!
    @client.destroy!
    @document_template.destroy!
    @document.destroy! unless @document.nil?
  end



  it "should be valid" do
    puts @document.errors.full_messages.inspect unless @document.valid?
    @document.should be_valid
    @document.save.should be_true
  end

  it "should have valid test data" do
    puts @user.errors.full_messages.inspect unless @user.valid?
    puts @client.errors.full_messages.inspect unless @client.valid?
    puts @company.errors.full_messages.inspect unless @company.valid?
    puts @document_template.errors.full_messages.inspect unless @document_template.valid?
    @user.should be_valid
    @client.should be_valid
    @company.should be_valid
    @document_template.should be_valid
  end

  it "should find the doc_builder shell script etc" do
    File.exist?( CRM[:shell_commands_folder_path] ).should be_true
    File.exist?( Document.doc_builder_script_path ).should be_true
    File.exist?( Document.doc_builder_settings_path ).should be_true
    File.exist?( Document.folder ).should be_true
    File.exist?( DocumentTemplate.folder ).should be_true
  end

  it "should fail to generate a document when it has no id" do
    @document.id = nil
    @document.generate_doc.should be_false
  end

  it "should be able to generate a new file_name" do

    custom_attributes = {
      :document_type_name => 'Itinerary',
      :client_name        => 'Client Name',
      :booking_ref        => 'Booking Ref',
      :user_name          => 'Consultant Name'
    }

    # Test with custom attributes:
    #@document.file_name = Document.file_name_for(nil, custom_attributes )
    @document.file_name = @document.default_file_name( custom_attributes )
    
    @document.file_name.should match custom_attributes[:document_type_name]
    @document.file_name.should match custom_attributes[:client_name]
    @document.file_name.should match custom_attributes[:booking_ref]
    @document.file_name.should match custom_attributes[:user_name]
    @document.file_name.should match Date.today.year.to_s

    # Test with default document attributes:
    @document.file_name = @document.default_file_name
    
    @document.file_name.should match valid_client_attributes[:name]
    @document.file_name.should match Date.today.year.to_s
    
  end


  it "should generate a Word doc" do

    # Might as well use auto-generated file_name:
    @document.file_name = @document.default_file_name

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc)
    File.exist?( @document.doc_path ).should be_false

    # Start document generation MANUALLY: 
    @document.save.should be_true
    @document.generate_doc.should be_true

    # Verify that the generation report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i

    # Verify that the doc file has been created:
    File.exist?( @document.doc_path ).should be_true

  end


  it "should generate a Word doc automatically when generate_doc_after_create is set" do
    
    # Might as well use auto-generated file_name:
    @document.file_name = @document.default_file_name

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc).should be_true
    @document.doc_exist?.should be_false
    
    # Start document generation AUTOMATICALLY: 
    @document.generate_doc_after_create = true
    @document.save.should be_true
    
    # Verify that the generation report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i
    
    # Verify that the doc file has been created:
    File.exist?( @document.doc_path ).should be_true
    
  end


  it "should generate a Word doc automatically when generate_doc_after_create is set" do
    
    # Might as well use auto-generated file_name:
    @document.file_name = @document.default_file_name

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc).should be_true
    @document.doc_exist?.should be_false
    
    # Start document generation AUTOMATICALLY: 
    @document.generate_doc_after_create = true
    @document.save.should be_true
    
    # Verify that the generation report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i
    
    # Verify that the doc file has been created:
    File.exist?( @document.doc_path ).should be_true
    
  end


  it "should generate an Itinerary doc file" do
    
    @document.document_type_id = DocumentType::ITINERARY
    @document.parameters = nil
    @document.document_template_file = nil
    puts @document.errors.full_messages.inspect unless @document.valid?
    @document.should be_valid

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc).should be_true
    @document.doc_exist?.should be_false
    
    # Start document generation AUTOMATICALLY: 
    @document.generate_doc_after_create = true
    @document.save.should be_true
    
    # Verify that the generated report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i

    # Verify that the doc file has been created:
    @document.doc_exist?.should be_true
    
  end


  it "should generate a Main Invoice doc file" do
    
    @document.document_type_id = DocumentType::MAIN_INVOICE
    @document.parameters = nil
    @document.document_template_file = nil
    @document.should be_valid

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc).should be_true
    @document.doc_exist?.should be_false
    
    # Start document generation AUTOMATICALLY: 
    @document.generate_doc_after_create = true
    @document.save.should be_true
    
    # Verify that the generation report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i

    # Verify that the doc file has been created:
    @document.doc_exist?.should be_true
    
  end


  it "should generate a Supp Invoice doc file" do
    
    @document.document_type_id = DocumentType::SUPP_INVOICE
    @document.parameters = nil
    @document.document_template_file = nil
    @document.should be_valid

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc).should be_true
    @document.doc_exist?.should be_false
    
    # Start document generation AUTOMATICALLY: 
    @document.generate_doc_after_create = true
    @document.save.should be_true
    
    # Verify that the generation report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i

    # Verify that the doc file has been created:
    @document.doc_exist?.should be_true
    
  end


  it "should generate a Credit Invoice doc file" do
    
    @document.document_type_id = DocumentType::CREDIT_NOTE
    @document.parameters = nil
    @document.document_template_file = nil

    @document.should be_valid

    # Delete any existing doc file if there is one:
    @document.delete_file!(:doc).should be_true
    @document.doc_exist?.should be_false
    
    # Start document generation AUTOMATICALLY: 
    @document.generate_doc_after_create = true
    @document.save.should be_true
    
    # Verify that the generation report includes the word 'Success'!
    @document.reload
    @document.document_status_id == 3   # 3=Success
    @document.doc_builder_output.should match /\*Success\*/i

    # Verify that the doc file has been created:
    @document.doc_exist?.should be_true
    
  end
end





def valid_document_attributes

  return {
    #:name                   => 'New document',				         
    #:file_name	            => 'test.doc',
    :document_type_id	      => 1,
    :client_id	            => 1,
    :company_id	            => 1,
    :trip_id		            => 1,
    :created_by	            => 'Tester User',
    
    # Fields used only during document generation:
    :document_status_id     => 0,
    #:document_template_id   => 1, # DEPRICATED   
    :document_template_file => 'SE_Itinerary.doc',
    :parameters             => '<job><client_id>1</client_id><user_id>1</user_id></job>'
  }

end

def valid_document_template_attributes

  return {
    :name              => 'Test template',				         
    :file_name	       => 'SE_Itinerary.doc',
    :document_type_id  => 1
  }

end


def valid_client_attributes

  title = Title.first_or_create( { :name => 'Mr' }, { :name => 'Mr' } )

  return {
    :title              => title,
    :forename           => 'Joe',
    :name               => 'Bloggs',		
    :addressee          => 'Mr J Bloggs',
    :salutation         => 'Mr Bloggs',
    :address_client_id  => 1
  }

end

