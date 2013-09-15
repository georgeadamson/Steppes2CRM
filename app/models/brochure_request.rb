class BrochureRequest
  include DataMapper::Resource

  # Sample brochure request letter generation:
  #   CScript.exe "C:/SteppesCRM/steppes2dev/scripts/documents/doc_builder/sdb.vbs" 1234
  #   where 1234 is a document_id that references a brochure_request record.

  PENDING   = 0 unless defined? PENDING  
  GENERATED = 1 unless defined? GENERATED   # Unused?
  MERGED    = 2 unless defined? MERGED      # Unused?
  CLEARED   = 3 unless defined? CLEARED   
  
  property :id,                     Serial
  property :notes,                  String,   :length   => 255,   :default  => ''       # Formerly SpecificRequests
  property :custom_text,            Text,     :required => false, :default  => ''       # Formerly CustomText
  property :status_id,              Integer,  :required => true,  :default  => PENDING  # 0=Pending
  #property :use_template,          Boolean,  :required => true,  :default  => true     # Formerly UseStandardText (To use XX_Brochure.doc)
  property :document_template_file, String,   :required => true,  :length => 255        #(Eg: XX_Brochure.doc)
  property :requested_date,         DateTime, :required => true,  :default  => lambda{ |obj,prop| DateTime.now }
  property :generated_date,         DateTime, :required => false                        # Formerly DateTimeSent
  property :client_id,              Integer,  :required => true
  property :company_id,             Integer,  :required => true
  property :user_id,                Integer,  :required => true
  property :document_id,            Integer,  :required => false
  property :created_at,             DateTime
  property :updated_at,             DateTime
  
  belongs_to :client
  belongs_to :company
  belongs_to :user
  belongs_to :document
  belongs_to :status, :model => "BrochureRequestStatus", :child_key => [:status_id]
  
  has n, :tasks         # Brochure followups
  
  alias name notes
  alias description custom_text

  # Allow new brochure_request form to set Area of Interest and Source:
  attr_accessor :client_source_id
  attr_accessor :client_country_id
  attr_accessor :client_country_ids

  # Hard-coded doc type id!
  attr_accessor :document_type_id

  # Flags to prevent immediate document generation: (Or switch it off completely when testing)
  attr_accessor :generate_doc_later   # For future enhancement? (Because run_later only applies in controllers and views)
  attr_accessor :skip_doc_generation  # Useful when testing. Doc gen will go through the motions without actually generating.

  # Allow new brochure_request form to set Area of Interest and Source:
  # accepts_nested_attributes_for :client

  validates_with_method :client_source_id,   :method => :validate_require_client_source
  validates_with_method :client_country_ids, :method => :validate_require_client_countries_of_interest
  
  
  before :valid? do
    # If necessary, attempt to choose a template for the current brochure.company:
    self.document_template_file ||= self.default_template_file_name
  end
  
  after :create do
    
    if self.client_source_id
      self.client.update!( :source_id => self.client_source_id )
    end
    
    interests = self.client.client_interests
    
    if self.client_country_ids
      interests.destroy!
      self.client_country_ids.each{|id| interests.create!( :country_id => id ) }
      # Deprecated:
    elsif self.client_country_id
      interests.destroy!
      interests.create!( :country_id => self.client_country_id )
    end
    
  end
  
  before :update do
    self.status_id = PENDING   if self.doc_file_should_exist? && !self.doc_file_exists?
    self.status_id = GENERATED if self.status_id == PENDING   &&  self.doc_file_exists?
  end
  
  after :update do
    
    if self.status_id == CLEARED
      
      self.document.destroy if self.document
      self.create_task()
      
    end
    
  end
  
  after :destroy do
    self.document.destroy if self.document
  end
  
  
  
  def validate_require_client_source

    # Only require the custom client_source attribute when new an on form that also set client_country_ids:
    if self.new? && self.client_source_id.blank? && !self.client_country_ids.nil?
      return [ false, 'Yoiks, you must choose a Client Source' ]
    else
      return true
    end
    
  end
  
  def validate_require_client_countries_of_interest

    # The custom client_country_ids attribute must be nil or contain at least one id:
    if self.new? && !self.client_country_ids.nil? && self.client_country_ids.empty?
      return [ false, 'Hang on a mo, you need to choose at least one Area of Interest' ]
    else
      return true
    end
    
  end
    


  # Helper to tell us whether we expect the doc file to have been generated:
  def doc_file_should_exist?
    return self.status_id == GENERATED || self.status_id == MERGED
  end

  # Helper to tell us whether the doc file actually exists:
  def doc_file_exist?
    return self.document && self.document.file_exist?
  end
  alias doc_file_exists? doc_file_exist?



  # Helper to create a new document record for this brochure_request and generate a word doc:
  # Returns self.document.document_status_id if successful!
  def generate_doc( current_user = nil )

    self.document_type_id

      Merb.logger.info "brochure_request.generate_doc (document_type_id #{ self.document_type_id })"
      Merb.logger.info "Skipping doc generation (because brochure_request.skip_doc_generation is true)" if @skip_doc_generation

			self.document = Document.new(
        :client                     => self.client,
        :company                    => self.company,
        :user                       => self.user || current_user,
        :created_by                 => current_user && current_user.preferred_name || 'Unknown user',
        #:brochure_request           => self, # Changed to use id instead, to work around DM bug. GA, Nov 2011.
        :brochure_request_id        => self.id,
        :document_type_id           => DocumentType::BROCHURE,
        :document_template_file     => self.document_template_file, #569: Use template that was chosen when brochure requested on client home page
				:generate_doc_after_create	=> !self.skip_doc_generation,
				:generate_doc_later	        => false  # This feature not yet available within models.
			)

      if self.document && self.document.save

        # SUCCESS!
        Document.logger.info "Document #{ self.document.id } details saved successfully for new brochure_request #{ self.id }"
        Document.logger.info self.document.doc_builder_output
        
        self.generated_date = Time.now
        self.status_id      = GENERATED
        self.save!

        return self.document.document_status_id

      elsif self.document && !self.document.valid?

        # INVALID:
        Document.logger.error "Unable to save document details for brochure_request #{ self.id }. #{ self.document.errors.inspect }"

      elsif !self.document

        # NIL:
        Document.logger.error "Failed to save document details for brochure_request #{ self.id }. No record was created so there are no error details!"

      else

        # Other:
        Document.logger.error "Failed to save document details for brochure_request #{ self.id }. \n brochure_request: #{ self.errors.inspect } \n document: #{ self.document.errors.inspect }"

      end

      # Attempt to retrieve error details from the document into this money_in object:
      collect_child_error_messages_for self, self.document if self.document

  end



  
  # Generate a followup for this request *if* it has been cleared:
  def create_task(force = false)

    # Check whether there's already a followup for this flight:
    task = self.tasks.first

    if !task && ( force || self.status_id == CLEARED )
      
      # This logic is based on the legacy database stored-procedure named "ClearBrochureMerge"
      due_date = Date.today + ( self.company.brochure_followup_days || 7 )

      # Automatically create a followup task for this flight:
      task = Task.new(
        :name                 => "Follow up brochure #{ "sent on #{ self.generated_date.formatted(:uidate) }" if self.generated_date } ",
        :status_id            => TaskStatus::OPEN,
        :type_id              => TaskType::BROCHURE_FOLLOWUP,
        :due_date             => due_date,
        :user                 => self.user,
        :client               => self.client,
        :brochure_request_id  => self.id  # Linked item id
      )

      if task.save!
        self.tasks.reload
      else
        # For debugging:
        task.valid?
        Merb.logger.error "ERROR: Could not create brochure followup automatically because: #{ task.errors.inspect }"
      end

    end

    return task

  end






  def self.run_merge_for( brochures, merge_path, current_user = nil )

    doc_paths = []

    brochures.each do |brochure|

      brochure.generate_doc(current_user) unless brochure.document && brochure.document.file_path
      brochure.save

      doc_paths << brochure.document.doc_path if brochure.document
  
    end

    succeeded = DocUtils::merge_docs( merge_path, doc_paths )

    brochures.each{ |brochure| brochure.status_id = MERGED }.save if succeeded

    return succeeded

  end




  def self.clear_merge_for(brochures)

    brochures.each do |brochure|

      #brochure.document.destroy if brochure.document
      brochure.status_id = CLEARED
      brochure.save

    end

    return brochures.all( :status_id => CLEARED ).count

  end
  
  
  # Helper to derive the default template for a brochure
  def default_template_file_name
  	initials					= self.company.initials unless self.company.blank?
    default_template	= DocumentType.get( DocumentType::BROCHURE )
    "#{ initials }_#{ default_template.template_file_name }" if default_template && initials
  end
  
  

  # Unused helper:
  #  def self.all_pending( company_id = nil )
  #    pending_requests = BrochureRequest.all( :generated_date => nil )
  #    pending_requests = pending_requests.all( :company_id => company_id ) if company_id.to_i > 0
  #    return pending_requests
  #  end


  def initialise(*args)

    super
    self.document_type_id ||= DocumentType::BROCHURE

  end

end


# BrochureRequest.auto_migrate!		# Warning: Running this will clear the table!