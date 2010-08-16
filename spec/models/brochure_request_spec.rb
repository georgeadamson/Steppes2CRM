require File.join( File.dirname(__FILE__), '..', "spec_helper" )
require File.join( File.dirname(__FILE__), '..', "spec_data" )

# To run this: jruby -X-C -S rake spec SPEC=spec/models/brochure_request_spec.rb

describe BrochureRequest do
	
  before :all do

    seed_lookup_tables()
    
  end

	before :each do

    BrochureRequest.all.destroy
		@brochure = BrochureRequest.new(valid_brochure_request_attributes)		

    Merb::Config[:log_stream] = STDOUT
    
	end
  

  it "should be valid" do
    @brochure.should be_valid
    @brochure.save.should be_true
  end
  

  it "should enforce required fields" do
    
    @brochure = BrochureRequest.new( valid_brochure_request_attributes.merge( :document_template_file => '' ) )
    @brochure.should_not be_valid
    
    @brochure = BrochureRequest.new( valid_brochure_request_attributes.merge( :client => nil ) )
    @brochure.should_not be_valid
    
    @brochure = BrochureRequest.new( valid_brochure_request_attributes.merge( :company => nil ) )
    @brochure.should_not be_valid
    
    @brochure = BrochureRequest.new( valid_brochure_request_attributes.merge( :user => nil ) )
    @brochure.should_not be_valid
    
  end


  it "should generate a document record" do

    @brochure.skip_doc_generation = true

    @brochure.generate_doc.should be_true
    @brochure.document.should_not be_nil

  end


  it "should generate a brochure letter (brochure.generate_doc)" do

    # See document_spec.rb for loads more doc generation tests!

    @brochure.skip_doc_generation = false
    @brochure.save.should be_true

    @brochure.generate_doc.should be_true
    @brochure.document.should_not be_nil
    @brochure.document.file_exist?.should be_true
    
  end


  it "should delete associated document record and file when it is destroyed" do

    # See document_spec.rb for loads more doc generation tests!

    @brochure.skip_doc_generation = false
    @brochure.save.should be_true

    @brochure.generate_doc.should be_true
    @brochure.document.should_not be_nil
    @brochure.document.file_exist?.should be_true

    doc_path = @brochure.document.file_path
    File.exist?( doc_path ).should be_true
    @brochure.destroy
    File.exist?( doc_path ).should be_false

  end
  

  it "should run brochure merge (run_merge_for brochures) UNABLE TO TEST THIS until we can figure out how to run win32ole in test environment!" do
    
    #  brochure1 = BrochureRequest.create( valid_brochure_request_attributes.merge( :notes => 'Brochure 1' ) )
    #  brochure2 = BrochureRequest.create( valid_brochure_request_attributes.merge( :notes => 'Brochure 2' ) )
    #  
    #  brochures = BrochureRequest.all
    #  
    #  merge_file = 'c:\temp\merge_docs_test.rspec.docx'
    #
    #  BrochureRequest.run_merge_for( brochures, merge_file ).should be_true
    
  end


  it "should run clear brochure merge" do

      brochure1 = BrochureRequest.create( valid_brochure_request_attributes.merge( :notes => 'Brochure 1' ) )
      brochure2 = BrochureRequest.create( valid_brochure_request_attributes.merge( :notes => 'Brochure 2' ) )
      brochures = BrochureRequest.all

      BrochureRequest.clear_merge_for( brochures ).should be_true
      brochure1.reload
      brochure2.reload
      brochure1.status_id.should == BrochureRequest::CLEARED
      brochure2.status_id.should == BrochureRequest::CLEARED
      
  end


  it "should run clear brochure merge and delete document files" do

      brochure1 = BrochureRequest.create( valid_brochure_request_attributes.merge( :skip_doc_generation => false, :notes => 'Brochure 1' ) )
      brochure2 = BrochureRequest.create( valid_brochure_request_attributes.merge( :skip_doc_generation => false, :notes => 'Brochure 2' ) )
      brochures = BrochureRequest.all

      brochure1.generate_doc.should be_true
      brochure2.generate_doc.should be_true
      doc_path1 = brochure1.document.file_path
      doc_path2 = brochure2.document.file_path

      # Look for doc files before and after clear merge:
      File.exist?( doc_path1 ).should be_true
      File.exist?( doc_path2 ).should be_true
      BrochureRequest.clear_merge_for( brochures ).should be_true
      File.exist?( doc_path1 ).should be_false
      File.exist?( doc_path2 ).should be_false

      # Extra test, just for jollies:
      brochure1.reload
      brochure2.reload
      brochure1.document.should be_nil
      brochure2.document.should be_nil

  end

end