
# TROUBLESHOOTING:
#
# Symptom  : *ERROR* Unable to open job recordset: Cannot find either column "parameters" or the user-defined function or aggregate "parameters.query", or the name is ambiguous. (-2147217900)
# Solution : The document or template row does not exist.
#
# Symptom  : *ERROR* user record with id x not found: Unable to parse fields (10005)
# Solution : The user or user's company row does not exist.
#

# TODO: Prevent the doc builder script from logging the db connection details!

class Document
  include DataMapper::Resource
  require 'fileutils'
  
  # document_status_id:
  PENDING   = 0 unless defined? PENDING  
  RUNNING   = 1 unless defined? RUNNING  
  FAILED    = 2 unless defined? FAILED   
  SUCCEEDED = 3 unless defined? SUCCEEDED
  
  property :id,					            Serial
  property :name,				            String,  :required => true, :length => 255, :default => 'Document'
	property :file_name,	            String,  :required => true, :length => 500, :default => ''
  property :document_type_id,	      Integer, :required => true
  property :client_id,	            Integer, :required => true  # The person this document was created for. Others may have access to it too through trip.
  property :company_id,	            Integer, :required => true
  property :trip_id,		            Integer, :required => false
  property :user_id,		            Integer, :required => false  # Not applicable for legacy database1 user_names because they are not in users list.
  property :brochure_request_id,    Integer, :required => false
  
  # Fields used only during document generation:
  property :document_status_id,     Integer, :required => true,  :default => PENDING  # 0=Pending, 1=Running, 2=Failed, 3=Succeeded
  property :document_template_id,   Integer, :required => true,  :default => 1  # DEPRICATED?
  property :document_template_file, String,  :required => true,  :default => '', :length => 255
  property :parameters,             Text,    :required => true,  :default => '' # Xml. Parameters are provided in xml for the Steppes Document Builder to use when querying for data.
  
  property :doc_builder_output,     Text,    :required => false, :default => '' # String for feedback from the generation process.
  property :pdf_builder_output,     Text,    :required => false, :default => '' # String for feedback from the generation process.
  
	property :created_at,	            DateTime
	property :created_by,	            String,  :required => true, :length => 50, :auto_validation => false	  # Consultant name
	#property :user_name,	            String,  :required => true, :length => 50,  :default => ''	# Consultant name
  
	belongs_to :document_template  
	belongs_to :document_type
	belongs_to :trip
	belongs_to :client
	belongs_to :company
	belongs_to :user
	belongs_to :brochure_request
  
  has 1, :money_in                # Some documents may be associated with an invoice record.
  #has 1, :brochure_request        # Some documents may be associated with a brochure_request.
  
  # Flag to trigger document generation:
  attr_accessor :generate_doc_after_create
  attr_accessor :generate_doc_later
  
  # Optional extra properties used to set doc builder parameters:
  # Note: These are not saved in corresponding database fields but are included in the parameters xml.
  attr_accessor :invoice_id
  attr_accessor :voucher_id
  
  
  # Custom validations:
  validates_with_method :validate_file_paths
  validates_with_method :document_template_file, :method => :validate_document_template_file #, :when => [:now]
  validates_present     :created_by #, :when => [:now]
  

  def status_name

    case self.document_status_id
      when PENDING   then 'Pending'
      when RUNNING   then 'Running'
      when FAILED    then 'Failed'
      when SUCCEEDED then 'Succeeded'
      else                '(Unknown)'
    end

  end
      


  def validate_file_paths

    #raise IOError, "The Document.doc_builder_commands_folder_path does not exist (#{ Document.doc_builder_commands_folder_path })"  unless File.exist?( Document.doc_builder_commands_folder_path )
    #raise IOError, "The Document.doc_builder_script_path does not exist (#{ Document.doc_builder_script_path })"                    unless File.exist?( Document.doc_builder_script_path )
    #raise IOError, "The Document.doc_builder_settings_path does not exist (#{ Document.doc_builder_settings_path })"                unless File.exist?( Document.doc_builder_settings_path )
    #raise IOError, "The Document.folder does not exist (#{ Document.folder })"                                                      unless File.exist?( Document.folder )
    #raise IOError, "The Document sub-folder does not exist (#{ self.sub_folder })"                                                  unless File.exist?( Document.folder / self.sub_folder )
    
    if !File.exist?( Document.folder )
      return [false, "Cannot find the folder where the generated documents are stored (#{ Document.folder })"]
    
    # This sub-folder check is not helpful because the doc-generator will create the sub-folder structure if necessary:
    #  elsif !File.exist?( Document.folder / self.sub_folder )
    #    return [false, "Cannot find the subfolder where the generated document would be saved to (#{ Document.folder / self.sub_folder })"]
    
    elsif !File.exist?( Document.doc_builder_commands_folder_path )      
      return [false, "Cannot find the folder where the document-generation gizmo lives (#{ Document.doc_builder_commands_folder_path })"]
    
    elsif !File.exist?( Document.doc_builder_script_path )
      return [false, "Cannot find the script that does the document-generation (#{ Document.doc_builder_script_path })"]
    
    elsif !File.exist?( Document.doc_builder_settings_path )
      return [false, "Cannot find the settings for the document-generation script (#{ Document.doc_builder_settings_path })"]
      
    else
      return true
    end

  end


  
  # Method for custom validations:
  def validate_document_template_file
    
    #if self.document_type_id == DocumentType::LETTER || self.document_type_id == DocumentType::BROCHURE
    if [ DocumentType::LETTER, DocumentType::BROCHURE ].include? self.document_type_id
      template_path = Document.doc_builder_letter_templates_path / self.document_template_file
    else
      template_path = Document.doc_builder_templates_path / self.document_template_file
    end
    
    return [false, "No template file has been chosen for this document"]          if self.document_template_file.blank?
    return [false, "The template file could not be found at #{ template_path }"]  if !File.exist?(template_path)
    return true
    
  end
  
  
  before :valid? do
    
    # Do what we can to derive missing parameters:
    self.user                 ||= self.trip && self.trip.user
    self.company              ||= self.default_company
    self.file_name              = self.default_file_name              if self.file_name.blank?
    self.name                   = self.file_name                      if self.name.blank?
    self.document_template_file = self.default_document_template_file if self.document_template_file.blank?
    self.parameters             = self.default_parameters             if self.parameters.blank?

    # Fix document_template_file path by removing /Letter/ path prefix if present: (It is superfluous for letter document_types)
    if self.document_type_id == DocumentType::LETTER || self.document_type_id == DocumentType::BROCHURE
      self.document_template_file = self.document_template_file.sub(/^(\\|\/)?Letters(\\|\/)?/i, '')
    end
    
  end
  
  
  # Trigger the doc file generation after saving details of a new document:
  after :create do

    # Generate doc file too if specified:
    if self.generate_doc_later
      Document.logger.info "Document record #{self.id} created (but skipping doc gen because generate_doc_later is set)"
    elsif self.generate_doc_after_create
      Document.logger.info "Starting generate_doc automatically (because generate_doc_after_create is true)"
      self.generate_doc
    else
      Document.logger.info "Document record #{self.id} created (but skipping doc gen because generate_doc_after_create not set)"
    end
    
  end
  
  before :destroy do
    Document.logger.info "Deleting document #{ self.id }..."
  end

  
  # Delete associated files after destroying the document record:
  # Note: Documents are actually MOVED to the /Documents/Deleted folder and not deleted! :o)
  after :destroy do
      
    self.delete_file! :pdf
    self.delete_file! :doc
    Document.logger.info "All trace of document #{ self.id } gone forever!"
    
  end
  
  
  
  
  # Eg: "Itinerary: Document"
  def display_name
    return "#{ cached(:document_types_hash)[self.document_type_id] }: #{ self.file_name.split(/(\\|\/)/).pop }"
  end
  
  
  
  
  # Helper to tell us whether document was created by this app or the old 'legacy' database:
  # (The 'parameters' field is only used by this new database)
  def created_by_legacy_crm
    return self.parameters.blank?
  end
  
  
  
  def folder
    
    if self.created_by_legacy_crm 
      return Document.legacy_folder
      
      # Ensure the new folder structure exists:
    else
      
      #
      #      folder  = Document.folder / year / company
      #
      #      # Try to ensure the new folder structure exists: (without creating folders willy nilly!)
      #      FileUtils.mkdir_p( folder, :verbose => true ) unless Document.folder.blank?
      
      return Document.folder
      
    end
    
  end
  
  
  # Helper to return the sub-folders path below Document.folder where the document will be stored:
  # Eg: /Documents/YEAR/COMPANY/INVOICE/
  # When 'create' is specified, we try to ensure the docs sub-folder structure actually exists:
  # Important: This ensures the database can try to cope by itself when each new year starts or when new companies and doc-types are defined.
  def sub_folder( options = { :create => false } )
    
    year        = Date.today.year.to_s
    company     = ( self.company || self.default_company || Company.first( :is_active => true ) ).initials
    doc_type    = self.document_type.name
    folder      = Document.folder
    sub_folder  = year / company / doc_type
    
    begin
      
      if options[:create] && !self.created_by_legacy_crm && !folder.blank? && File.exist?(folder)
        
        FileUtils.mkdir(folder / year)                       unless File.exist?(folder / year)
        FileUtils.mkdir(folder / year / company)             unless File.exist?(folder / year / company)
        FileUtils.mkdir(folder / year / company / doc_type)  unless File.exist?(folder / year / company / doc_type)
        
        # The commands above are necessary because mkpath() seems to fail on Windows!
        # FileUtils.mkpath(full_path)      # For 'mode' settings see http://ss64.com/bash/chmod.html or google for "chmod mode"
        
      end
      
    rescue Exception => error_details
      puts "ERROR while creating document sub-folders path: #{ error_details } (#{ folder / sub_folder })"
    end
    
    return sub_folder
    
  end
  
  
  def doc_path
    return self.folder / self.file_name
  end
  alias file_path doc_path
  
  # PDF file path is the same as doc_path but with different extension:
  def pdf_path
    return @pdf_path ||= "#{ self.doc_path.sub( /\.(doc|docx)$/, '' ) }.pdf"
  end


  # Helper for deriving the network file location of the document:
  def doc_url
    "file:///#{ URI.escape( self.doc_path.gsub('/','\\') ) }"
  end



  def generate_pdf( report, pdf_path = nil )
    return Document.doc_to_pdf( self.doc_path, self.pdf_path, report )
  end
  
  
  # Returns file size (or nil if size is zero or file does not exist)
  def doc_size
    
    # Return 'cached' value if available to reduce unecessary file accesses:
    return @doc_size if defined?(@doc_size) && @doc_size
    
    begin
      return @doc_size = File.size?( self.doc_path )
    rescue
      return nil
    end
    
  end

  def doc_exist?
    return !!self.doc_size
  end
  
  alias file_size    doc_size  #
  alias file_exist?  doc_exist?  # <-- Best to use this alias to be consistent with ruby File.exist?()
  alias file_exists? doc_exist?  # <-- TODO: Depricate this?
  
  
  # Delete the physical file: (Returns true if successful)
  # to be extra safe this assumes we want to delete the PDF unless :doc or file_path is specified)
  # Important: Documents are actually MOVED to the /Documents/Deleted folder and not deleted! :o)
  def delete_file!( type = :pdf, file_path = nil )
    
    file_path ||= ( type == :doc ) ? self.doc_path : self.pdf_path
    @doc_size = @pdf_size = nil

    return Document.delete_file!( file_path, self.id )
    
  end
  
  
  # Delete the physical file: (Returns true if successful)
  # Important: Documents are actually MOVED to the /Documents/Deleted folder and not deleted! :o)
  # The document_id argument is not required but helps debugging.      
  def self.delete_file!(file_path, document_id = nil)

    begin

      Document.logger.info "Deleting document #{ document_id } file: #{ file_path }"
      
      # If there's no file then I reckon we've succeeded already!
      if !file_path.blank? && !File.exist?(file_path)

        Document.logger.info " File does not exist so nothing to delete"
        return true
      
      else

        to_folder          = Document.deleted_folder
        file_utils_options = { :force => true, :verbose => true }

        # Do what we can to ensure the 'documents deleted' folder is available for use:
        FileUtils.mkdir(to_folder) unless to_folder.blank? || File.exist?(to_folder)

        # Some quick belt-and-braces checks to help with troubleshooting:
        raise IOError, "No documents-deleted folder was specified"                    if to_folder.blank?
        raise IOError, "The documents-deleted folder does not exist #{to_folder}"     unless File.exist?(to_folder)
        raise IOError, "The documents-deleted folder is not a directory #{to_folder}" unless File.directory?(to_folder)
        
        if !to_folder.blank? && File.exist?(to_folder) && File.directory?(to_folder)
          
          FileUtils.move( file_path, to_folder, file_utils_options )
          new_path = to_folder / File.basename(file_path)
          
          # Delete original file if it still exists *and* it was copied successfully:
          # This could happen when moving between different servers or partitions.
          if File.exist?(new_path)
            Document.logger.info " (File has been moved to #{ new_path } just in case!)" 
            File.delete(file_path) if File.exist?(file_path)
          end

        end

        # Return true if the file really has gone:
        Document.logger.info " Document file delete completed successfully"
        return !File.exist?(file_path)
      
      end
      
    rescue Exception => reason
      Document.logger.error " Unable to delete file #{ file_path } (because #{ reason })"
      return false
    end
    
  end
  
  
  
  # Helper to derive a default company for this document using whatever properties we have:
  def default_company()
    
    return self.company || 
    ( self.trip && self.trip.company ) || 
    ( self.trip && self.trip.user && self.trip.user.company ) || 
    ( self.user && self.user.company )
    
  end
  
  
  # Helper to derive this document's template file: (Eg: 'SE' + 'Itinerary.doc' => 'SE_Itinerary.doc')
  def default_document_template_file
    
    if self.document_type && !self.document_type.template_file_name.blank?
      
      initials = ( self.company || self.default_company || Company.first( :is_active => true ) ).initials
      
      return "#{ initials }_#{ self.document_type.template_file_name }"
      
    end
    
  end
  
  
  # Helper to derive default parameters formatted ready for the doc-generation process:
  # Parameters are provided in xml for the Steppes Document Builder to use when querying for data.
  def default_parameters( alternative = {} )
    
    # Do what we can to derive missing parameters:
    trip    = self.trip                             || Trip.get(alternative[:trip_id])
    user    = self.user    || ( trip && trip.user ) || User.get(alternative[:user_id])
    company = self.company || self.default_company  || Company.get(alternative[:company_id])
    
    doc_builder_settings = {
      :trip_id              => trip && trip.id,
      :user_id              => user && user.id,
      :company_id           => company && company.id,
      :client_id            => self.client_id           || alternative[:client_id],
      :invoice_id           => self.invoice_id          || alternative[:invoice_id],          # This extra property not persisted in a corresponding db field.
      :voucher_id           => self.voucher_id          || alternative[:voucher_id],          # This extra property not persisted in a corresponding db field.
      :brochure_request_id  => self.brochure_request_id || alternative[:brochure_request_id]  # This extra property not persisted in a corresponding db field.
    }

    return Document.parameters_for(doc_builder_settings)
    
  end
  
  
  
  
  # Generate a Word document using the parameters provided:
  def generate_doc
    
    output = []
    an_exception_was_raised = nil
    
    # If necessary, assume company & derive document template file name:
    self.company              ||= self.default_company || Company.first( :is_active => true )
    self.file_name              = self.default_file_name                if self.file_name.blank?
    self.document_template_file = self.default_document_template_file   if self.document_template_file.blank?
    
    # Prepare parameters for the doc builder script if there are none already:
    self.parameters = self.default_parameters                           if self.parameters.blank?
    

    #  if self.generate_doc_later
    #    Document.logger.info "Not running generate_doc right now because generate_doc_later is true"
    #    # doc = self
    #    # Does not work: Nice idea though :)
    #    #  Document.run_later do
    #    #    doc.generate_doc_later = false 
    #    #    doc.generate_doc
    #    #    doc = nil
    #    #  end
    #    self.generate_doc_later = false
    #    return 0
    #  end


    begin
      
      # Try to ensure the documents sub-folder structure exists, and doc-builder has an INI file:
      self.sub_folder( :create => true )
      Document.create_doc_builder_settings_file()
      
      raise ArgumentError, 'The document details need to be saved before a Word doc can be generated' if self.new?
      raise IOError, "The Document.doc_builder_commands_folder_path does not exist (#{ Document.doc_builder_commands_folder_path })"  unless File.exist?( Document.doc_builder_commands_folder_path )
      raise IOError, "The Document.doc_builder_script_path does not exist (#{ Document.doc_builder_script_path })"                    unless File.exist?( Document.doc_builder_script_path )
      raise IOError, "The Document.doc_builder_settings_path does not exist (#{ Document.doc_builder_settings_path })"                unless File.exist?( Document.doc_builder_settings_path )
      raise IOError, "The Document.folder does not exist (#{ Document.folder })"                                                      unless File.exist?( Document.folder )
      raise IOError, "The Document sub-folder does not exist (#{ self.sub_folder })"                                                  unless File.exist?( Document.folder / self.sub_folder )
      
      shell_command = "#{ Document.doc_builder_shell_command } #{ self.id }"

      message = "Starting shell command #{ Time.now.formatted(:db) }: #{ shell_command }"
      output << message
      Document.logger.info message
      
      # This did not seem to update the row. No idea why! Had to resort to direct update instead:
      #self.doc_builder_output = output.join("\n")
      #self.save!
      doc = Document.get(self.id)
      doc.doc_builder_output = output.join("\n")
      doc.save!
  		# sql_statement = "EXEC sp_document_update_job_status ?, ?, ?"
      # repository.adapter.execute( sql_statement, self.id, nil, "\n#{ output.join("\n") }" )
      self.reload
      

      IO.popen(shell_command) do |readme|
        readme.each do |line|
          
          Document.logger.info! line
          
          # Exception when script path is incomplete: (Eg: it outputs: "Input Error: Unknown option /scripts/documents/doc_builder/sdb.vbs specified.")
          raise ScriptError, 'Problem with the shell command' if line =~ /Input Error:/i 
          raise IOError,     'Unable to open INI file'        if line =~ /ERROR.*Unable to open INI file/i 
          raise IOError,     'Unable to update job status'    if line =~ /ERROR.*Unable to update job status/i 
          
          # Important: If we decide to update the doc_builder_output as we go then we'll need to keep
          #            reloading it because the external script process is updating the database row:
          # self.reload
          # self.doc_builder_output << line
          # self.save!
          
        end
      end

      #  # This alternative technique does it all in one go:
      #  f = IO.popen(shell_command)
      #  lines =  f.readlines
      #  output << lines
      #  Document.logger.info! lines      
      
    rescue Exception => error_details
      
      an_exception_was_raised = "ERROR: #{ error_details }\nTerminating shell command because of errors."
      Document.logger.error an_exception_was_raised
      
    ensure
      
      # Note we must RELOAD the object because the db row has been updated by the separate script process:
      #self.reload
      
      if an_exception_was_raised
        message = an_exception_was_raised
        Document.logger.error 'Saving doc_builder_output for debugging'
        self.document_status_id = FAILED
      else
        message = "Completed shell command."
        Document.logger.info message
      end

      # # This did not seem to update the row. No idea why! Had to resort to direct update instead:
      self.doc_builder_output << message
      self.save!
      # repository.adapter.execute( sql_statement, self.id, nil, "\n#{ message }" )
      self.reload
      
      # Return true if doc generation succeeded:
      return ( self.document_status_id == SUCCEEDED )
      
    end
    
  end
  
  
  
  def document_status_message
    
    name = self.document_type && self.document_type.name || ''
    
    case self.document_status_id
    when 1 then "Your #{ name } document is being created."
    when 2 then "Whoops, your #{ name } document could not be created. See the documents page for more details."
    when 3 then "Your new #{ name } document has been created successfully."
    else   nil
    end
    
  end
  
  
  
  
  # Helper for converting documents to PDF using Microsoft Word 2007 on the server:
  # Returns true if pdf is generated successfully.
  # File paths and failure details are returned in the report hash {}
  # Usage: Document.doc_to_pdf( doc_path, pdf_path, report )
  # REQUIRES Microsoft Office 2007 Word with the "Save as PDF" add-on must be installed on the server!
  # REQUIRES DCOM permissions on server so Word can run as admin regardless of database user.
  #   See: Control Panel > Admin Tools > Component Services > +DCOM Config > Microsoft Office Word 97-2003 Document > Properties > Set adequate permissions in Security and Identity tabs.
  #		- In Word's DCOM Permissions allow both 'Local' and 'Remote' access for 'Everyone'. (See security tab below)
  #		- Tab settings:
  #			- General  > Authentication Level: Default.
  #			- Location > Run application on the computer where the data is located: Tick, Run application on this computer: Tick.
  #			- Security > Launch and activation permissions > Customise > Everyone: Local and Remote access, Access permissions > Customise > Everyone: Local and Remote access, Configuration permissions > Use default.
  #			- Identity > This User: STEPPESEAST\Administrator.
  #
  # More info:
  #	- http://rubyonwindows.blogspot.com/2010/01/saving-microsoft-office-documents-as.html
  #
	def self.doc_to_pdf( doc_path, pdf_path, report )
    
    require 'win32ole'	# More info: http://github.com/bpmcd/win32ole
    
		success_status	= false
		error_message		= ''
		error_details		= ''
    debug_info      = []
    
		# MS Word 'constants'
		wdDoNotSaveChanges					= 0
		wdOpenFormatAuto						= 0
    wdFormatPDF                 = 17
		wdExportFormatPDF						= 17
		wdExportOptimizeForOnScreen	= 1
		wdExportAllDocument					= 0
		wdExportDocumentContent			= 0
		wdExportCreateNoBookmarks		= 0
		msoEncodingAutoDetect				= 50001
		wdLeftToRight								= 0
		wdOriginalDocumentFormat		= 1
    wdCRLF                      = 0
		
		begin
			
			#temp_doc_path = doc_path.sub( /.doc$/, '.temp.doc' )
			#FileUtils.copy doc_path, temp_doc_path
			
      debug_info << 'Begin doc_to_pdf()'
      
			# Make sure the document is suitable for Word and that the file exists!
      raise Exception unless defined?(WIN32OLE)                           ;debug_info << 'WIN32OLE is installed and available'      
			raise TypeError unless doc_path =~ /\.(doc|docx|dot|dotx|rtf|txt)$/ ;debug_info << 'Document extension looks valid'
			raise IOError   unless File.exist?(doc_path)                        ;debug_info << 'Document file exists'
			
			word = WIN32OLE.new("Word.Application")                             ;debug_info << 'Created word object'
			
			# Older versions of Word cannot convert to PDF: (Word 2007 is version 12)
			raise NotImplementedError, 'Wrong version of Microsoft Word' if word.Version.to_i < 12    ;debug_info << 'Verified compatible version of Word'
			
      if File.exist?(pdf_path)
        File.delete(pdf_path)                                             ;debug_info << 'Old pdf file found and deleted'
      end
      
			# So far so good: We've managed to open Word so now attempt to open the document:
			# Note the use of the readonly argument to avoid error when document is already open/locked.
			# Method arguments according to WORD: Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles, PasswordDocument, PasswordTemplate, Revert, WritePasswordDocument, WritePasswordTemplate, Format, Encoding, Visible, OpenAndRepair, DocumentDirection, NoEncodingDialog, XMLTransform* )	# Including the final XMLTransform argument causes error even when testing in word vba!
			# Method arguments according to MSDN: Open(FileName, ConfirmConversions, ReadOnly, AddToRecentFiles, PasswordDocument, PasswordTemplate, Revert, WritePasswordDocument, WritePasswordTemplate, Format, Encoding, Visible, OpenConflictDocument, OpenAndRepair, DocumentDirection, NoEncodingDialog)
			# http://msdn.microsoft.com/en-us/library/aa220317%28office.11%29.aspx
			# When degugging try testing with no extra params at all, eg: word.Documents.Open(doc_path)
			# With all arguments this same call would be:
			# doc = word.Documents.Open( doc_path, false, true, true, '', '', true, '', '', wdOpenFormatAuto, msoEncodingAutoDetect, false, false, wdLeftToRight, true, nil )
			doc = word.Documents.Open( doc_path, false, true )                   ;debug_info << 'Opened document'
      
			# Hooray, we managed to open the document. Now save it as PDF:
			# Method arguments: document.SaveAs(FileName, FileFormat, LockComments, Password, AddToRecentFiles, WritePassword, ReadOnlyRecommended, EmbedTrueTypeFonts, SaveNativePictureFormat, SaveFormsData, SaveAsAOCELetter, Encoding, InsertLineBreaks, AllowSubstitutions, LineEnding, AddBiDiMarks)
			# Method arguments: document.ExportAsFixedFormat(OutputFileName, ExportFormat, OpenAfterExport, OptimizeFor, Range, From, To, Item, IncludeDocProps, KeepIRM, CreateBookmarks, DocStructureTags, BitmapMissingFonts, UseISO19005_1, FixedFormatExtClassPtr)
			# More info about ExportAsFixedFormat method: http://msdn.microsoft.com/en-us/library/bb256835.aspx
      # More info about SaveAs method: http://msdn.microsoft.com/en-us/library/bb221597%28v=office.12%29.aspx
      # doc.SaveAs pdf_path, wdFormatPDF, false, '', false, '', false, false, false, false, false, msoEncodingAutoDetect, false, false, wdCRLF, false
			doc.ExportAsFixedFormat pdf_path, wdExportFormatPDF, false, wdExportOptimizeForOnScreen, wdExportAllDocument, 1, 1, wdExportDocumentContent, false, true, wdExportCreateNoBookmarks, true, true, false    ;debug_info << 'Exported document to pdf'
      
      
		rescue TypeError => error_details
			
			ext = doc_path.split('.').pop()
			ext = ext.blank? || ext.length > 4 ? 'unkown' : ".#{ ext }"
			
			error_message = "Unable to convert document to PDF because we cannot open a document with #{ ext } extension"
      debug_info << "Error: #{ error_message }"
      
		rescue IOError => error_details
			
			error_message = "Unable to convert document to PDF because it could not be found at #{ doc_path }"
      debug_info << "Error: #{ error_message }"
			
		rescue NotImplementedError => error_details
			
			error_message = "Unable to convert documents to PDF because the server is installed with a pre-2007 version of Microsoft Word (v12)"
      debug_info << "Error: #{ error_message }"
			
		rescue NoMethodError => error_details
			
			# IMPORTANT! Just about ANY ERROR on a word method seems to raise a NoMethodError! Not very helpful :(
			# Typical error_details are "No method `Open'" regardless of the cause!
			error_message = case error_details.to_s
        
      when /Open/									then "Failed to open the document to convert it to PDF (Could not open the document)"
      when /Documents/						then "Failed to open the document to convert it to PDF (Could not open the Microsoft Word 'Documents' collection)"
      when /SaveAs/   						then "Opened the document successfully but 'SaveAs' failed while converting it to PDF (Perhaps the PDF Converter for Microsft Word is not installed?)"
      when /ExportAsFixedFormat/	then "Opened the document successfully but 'Export' failed while converting it to PDF (Perhaps the PDF Converter for Microsft Word is not installed?)"
        
			end
      debug_info << "Error: #{ error_message }"
			
		rescue Exception => error_details
      
      if defined?(WIN32OLE)
        
			  error_message = case error_details.to_s
          
        when /Open/									then "Failed to open the document to convert it to PDF"
        when /SaveAs/   						then "Opened the document successfully but 'SaveAs' failed while converting it to PDF"
        when /ExportAsFixedFormat/	then "Opened the document successfully but 'Export' failed while converting it to PDF"
        else                             "Unable to convert the document to PDF. No idea why. Aren't computers silly?!"
          
			  end
        
      else
        error_message = "Unable to convert documents to PDF because the WIN32OLE library is not loaded or not installed on the server"
      end
      
      debug_info << "Error: #{ error_message }"
			
		else
			
			# SUCCESS!
			success_status = true
      debug_info << "SUCCESS!"
			
      
      # TIDY UP after ourselves!
		ensure
      
      debug_info << ' Begin housekeeping...'
			
			# Close Document: (And allow for when word.Documents.Open() failed and doc object was not created)
			begin
        doc.Close unless doc.nil?
        debug_info << '  Closed document successfully'
      rescue
        # Ignore it
      ensure
        doc = nil
      end  
      
			# Close Word: (And allow for when WIN32OLE.new("Word.Application") failed and word object was not created)
			begin
        word.Quit(wdDoNotSaveChanges) unless word.nil?
        debug_info << '  Quit Word successfully'
      rescue
        # Ignore it
      ensure
        word = nil
      end
      
      debug_info << ' Finished housekeeping'
			
      
		end
		
    
    debug_info << 'Preparing report hash'
    
		
		# Return error details by-ref in the report hash:
		report.merge!(
      
			:status		  => success_status,
			:message	  => error_message,
			:details	  => error_details.to_s,
      :debug_info => debug_info,
      :doc_path   => doc_path,
      :pdf_path   => pdf_path
      
		) if report.is_a? Hash
    
    debug_info << 'Finished doc_to_pdf()'
    puts "\n PDF GENERATION ERROR details: \n #{ debug_info.join("\n") } \n" unless error_details.blank?
    
		return success_status
    
	end
	
  
  
  # Helper for generating new file_name:
  # Itinerary-Audette-L28421-Kate Burnell.03.02.2010 16.11.20.doc
  def default_file_name( args = {} )
    
    type    = args[:document_type_name] || self.document_type.name
    client  = args[:client_name]        || self.client && self.client.name         || ''
    ref     = args[:booking_ref]        || self.trip   && self.trip.booking_ref    || ''
    user    = args[:user_name]          || self.user   && self.user.preferred_name || ''
    date    = args[:date]               || Time.now.formatted(:filedatetime)

    # Special naming convention for letters:
    if self.document_type.id == DocumentType::LETTER && args[:document_type_name].blank? && !self.document_template_file.blank?
      type = self.document_template_file.split(/\/|\\/).pop.slice(/(.*)(.doc)/, 1)
    end

    file_name = "#{ type }-#{ client }#{ "-#{ref}" unless ref.blank? }-#{ user }-#{ date }.doc"
    
    return self.sub_folder / file_name
    
  end
  
  
  
  # Helper to prepare XML parameters to drive the doc builder script:
  def self.parameters_for( params )
    
    xml = ''
    params.each{ |key,val| xml << "<#{ key }>#{ val }</#{ key }>" unless val.nil? }
    return "<job>#{ xml }</job>"
    
  end
  
  
  # Helper to return the TARGET FOLDER for document generation:
  def self.folder
    return CRM[:doc_folder_path]        || '\\\\selfs\\documents'
  end
  
  # Helper to return the TARGET FOLDER for document generation:
  def self.legacy_folder
    return CRM[:legacy_doc_folder_path] || '\\\\selsvr01\\documents'
  end
  
  # Helper to return the folder for DELETED documents:
  def self.deleted_folder
    return Document.folder / 'Deleted'
  end
  
  # Helper to provide the TEMPLATES FOLDER for document generation:
  def self.doc_builder_templates_path
    return CRM[:doc_templates_path]
  end
  
  # Helper to provide the LETTER TEMPLATES FOLDER for document generation:
	# Note: Letter templates are always in the /Templates/Letters subfolder.
  def self.doc_builder_letter_templates_path
    return Document.doc_builder_templates_path / 'Letters'
  end
  
  # Helper to return the root folder of the shell commands:
  def self.doc_builder_commands_folder_path
    return CRM[:shell_commands_folder_path]
  end
  
  # Helper to return the shell SCRIPT FILE for the document generator:
  def self.doc_builder_script_path
    return Document.doc_builder_commands_folder_path / CRM[:doc_builder_script_file]
  end
  
  # Helper to return the shell script INI FILE for the document generator script:
  def self.doc_builder_settings_path
    return Document.doc_builder_commands_folder_path / CRM[:doc_builder_settings_file]
  end
  
  # Helper to return the full syntax of the SHELL SCRIPT COMMAND for the document generator:
  # All it needs is a document id appended to the end, so the script knows which document to work on.
  # Note: Dir.getwd returns the current working directory of this app.
  def self.doc_builder_shell_command
    return "CScript.exe \"#{ Dir.getwd / Document.doc_builder_script_path }\""
  end
  
  
  # Helper to fetch an array of all the letter template file names:
  # Specify :prefix => 'SE' argument to filter by company initials, eg: 'SE'.
  # All other arguments are ignored when pattern is provided.
  def self.doc_builder_letter_templates( attrs = {} )
    
    defaults = {
      :type     => '*',           # Eg: Specify 'Trip' for 'SE_TripLetter_xyz.doc'.
      :prefix   => '[a-z][a-z]',  # Default to any company prefix.
      :ext      => :doc,          # Default to files with .doc extensions only.
      :pattern  => nil            # Override all of the above with your own pattern matching ideas.
    }
    
    attrs = defaults.merge(attrs)
    
    letter_type = attrs[:type]    || '*'
    letter_type = letter_type.to_s.gsub( /General|Letter/i, '' )
    
    prefix      = attrs[:prefix]  || '[a-z][a-z]'
    ext         = attrs[:ext]     || :doc
    pattern     = attrs[:pattern] || "#{ prefix }_#{ letter_type }Letter_*.#{ ext.to_s }"
    folder      = Document.doc_builder_letter_templates_path.gsub('\\','/')
    
    return Dir[ folder / pattern ].map{ |path| File.basename(path) }.sort()
  	
  end
  
  
  
  
  
  # Create the INI file used by the doc builder script:
  # It will be saved to Document.doc_builder_settings_path.
  # Content will be like this:
  #  [Steppes Travel Document Builder]
  #  ConnectionString=Provider=SQLOLEDB;Data Source=seldb;Initial Catalog=Steppes2test;User Id=SteppesCRM;Password=password;
  #  TemplatePath=C:\SteppesCRM\steppes2dev\scripts\documents\doc_builder\(Sample Templates)
  #  DocumentPath=C:\SteppesCRM\steppes2dev\scripts\documents\doc_builder\(Sample Documents)
  #  ImagePath=C:\temp\Steppes Doc Gen prototype\Images
  #  SignaturePath=C:\temp\Steppes Doc Gen prototype\Signatures
  #  PortraitPath=C:\temp\Steppes Doc Gen prototype\Portraits
  def self.create_doc_builder_settings_file
    
    # Note we ensure all forward slashes are stored in the INI as backslahes:
    
    database = case Merb.environment
    when 'production'   then 'Steppes2live'
    when 'usertesting'  then 'Steppes2uat'
    when 'test'         then 'Steppes2test'
    else                     'Steppes2dev'
    end
    
    # TODO: Get config from DataMapper settings!
    config = {
      :host     => 'seldb',
      :database => database,
      :username => 'SteppesCRM',
      :password => 'password'
    }
    
    Document.logger.info "Preparing ini file from these app_settings: #{ CRM.inspect }"

    settings = "[Steppes Travel Document Builder settings for the '#{ Merb.environment }' database]" +
      "\r\nConnectionString=Provider=SQLOLEDB;Data Source=#{ config[:host] };Initial Catalog=#{ config[:database] };User Id=#{ config[:username] };Password=#{ config[:password] };" +
      "\r\nTemplatePath=#{ CRM[:doc_templates_path].gsub('/','\\') }" +
      "\r\nLetterTemplatePath=#{ CRM[:letter_templates_path].gsub('/','\\') }" +
      "\r\nDocumentPath=#{ CRM[:doc_folder_path].gsub('/','\\') }" +
      "\r\nImagePath=#{ CRM[:images_folder_path].gsub('/','\\') }" +
      "\r\nSignaturePath=#{ CRM[:signatures_folder_path].gsub('/','\\') }" +
      "\r\nPortraitPath=#{ CRM[:portraits_folder_path].gsub('/','\\') }" +
      "\r\n"
    
    ini_path = Document.doc_builder_settings_path
    
    # Recreate INI file if it does not exist or does not match expected settings:
    begin

      unless File.exist?(ini_path) && File.read(ini_path) == settings
        
		    File.open( ini_path, 'w' ){ |file| file.write settings } 
        puts "Recreated doc builder ini file for #{ Merb.environment } environment: #{ ini_path }"
        Document.logger.error "Recreated doc builder ini file for #{ Merb.environment } environment: #{ ini_path }"
        
      end
      
    rescue Exception => error_details
      
      Merb.logger.error     "Failed while recreating doc-builder INI file: #{ error_details } #{ ini_path }"
      Document.logger.error "Failed while recreating doc-builder INI file: #{ error_details } #{ ini_path }"
      
    end
    
  end


	def self.logger
    
		unless defined?(@@doc_log)
			@@doc_log = Merb::Logger.new File.new( Merb.root / "log" / "documents.log", 'a' ), :info
		end
		
		return @@doc_log
		
	end	


#  # Depricated. Could nto get it to work.
#  # Our own version of the run_later method normally only available to controllers and views:
#  # Yes, yes I know it's a controller/view thing, but this seemed like a good idea at the time!
#  # See http://yardoc.com/docs/namelessjon-merb/Merb.run_later
#  def self.run_later(&blk)
#    Merb::Dispatcher.work_queue << blk
#  end
  
end
