
# DocUtils::merge_docs()

module DocUtils

	# MS Word 'constants'
	WDDoNotSaveChanges					= 0
	WDOpenFormatAuto						= 0
  WDFormatPDF                 = 17
	WDExportFormatPDF						= 17
	WDExportOptimizeForOnScreen	= 1
	WDExportAllDocument					= 0
	WDExportDocumentContent			= 0
	WDExportCreateNoBookmarks		= 0
	MSoEncodingAutoDetect				= 50001
	WDLeftToRight								= 0
	WDOriginalDocumentFormat		= 1
  WDNewBlankDocument          = 0
  WDFormatDocument97          = 0
  WDPageBreak                 = 7
  WDCRLF                      = 0

  # Helper for merging several documents into one long one:
  def DocUtils.merge_docs( merge_path, source_doc_paths = [] )
    
    require 'fileutils'    
    require 'win32ole'	# More info: http://github.com/bpmcd/win32ole
    
    # Variable for the merge-document object:
    doc             = nil
    debug_info      = []
    success_count   = 0
    succeeded       = false

    # MSWord expects doc_path to use back-slashes so lets swap any forward-slashes just to be on the safe side:
    merge_path = merge_path.gsub('/','\\')
    Merb.logger.info "Document merge: Starting to insert #{ source_doc_paths.length } documents into #{ merge_path }"
    
    begin
      
      raise Exception unless defined?(WIN32OLE)                                         ;debug_info << 'WIN32OLE is installed and available'      
      raise TypeError unless merge_path =~ /\.(doc|docx)$/                              ;debug_info << 'Merge file extension looks valid'
      raise IOError   unless File.exist?( File.dirname( merge_path.gsub(/\\/,'/') ) )   ;debug_info << 'Merge file folder exists'
      #raise IOError   unless File.exist?(merge_path)       ;debug_info << 'Document file exists'
      
      # Prepare a reference to MSWord:
      word = WIN32OLE.new("Word.Application")               ;debug_info << 'Created word object'
      word.Visible = ( Merb.environment == 'development' )
      word.Options.Pagination = false   # For tiny performance benefit.
      
      # Create a new empty document:
      #doc = word.Documents.Add ( :Template => 'Normal', :NewTemplate => false, :DocumentType => WDNewBlankDocument )
      doc = word.Documents.Add( 'Normal', false ) # For some reason the final DocumentType arg causes error.
      

      # INSERT EACH DOCUMENT into our merge doc:
      source_doc_paths.each_with_index do |doc_path,i|

        # MSWord expects doc_path to use back-slashes so lets swap any forward-slashes just to be on the safe side:
        doc_path = doc_path.gsub('/','\\')
        Merb.logger.info "Document merge: Adding #{ i+1 } of #{ source_doc_paths.length }: #{ doc_path }"

        # Add a PAGE BREAK before each document:
        # (The InsertBreak() method should accept a type argument but for some reason it fails. Luckily for us the WDPageBreak is the default type)
        begin
          word.Selection.InsertBreak unless i == 0 # WDPageBreak
        rescue
          Merb.logger.error ' Failed to insert a PageBreak before #{ doc_path }.'
        end

        # Insert the file after checking that it exists:
        begin

          raise IOError unless File.exist?(doc_path)
          # word.Selection.InsertFile :FileName => doc_path, :Range => '', :ConfirmConversions => false, :Link => false, :Attachment => false
          #word.Selection.InsertFile( doc_path, '', false, false, false)
          word.Selection.InsertFile( doc_path )
          debug_info << "Inserted file #{ doc_path }"
          success_count += 1

        rescue IOError => reason

          message = "Document merge: Unable to insert document because it does not exist at \"#{ doc_path }\" (#{ reason })"
          Merb.logger.error message

          # Try to be helpful by reporting the problem in the merged document:
          begin
            word.Selection.TypeText message
          rescue
            Merb.logger.error ' Could not even add a helpful error message into the document.'
          end

        rescue Exception => reason

          puts "Document merge: Failed to insert document from file #{ doc_path } (#{ reason }) Trace: #{ debug_info.inspect }"

        end
      
      end

      debug_info << "Finished inserting files (#{ success_count } of #{ source_doc_paths.length })"

      # Finally, SAVE THE MERGE DOC: (Overwrite existing file if any)
      begin
        debug_info << "Saving merge file as #{ merge_path }"
        doc.SaveAs(merge_path)  # Warning: Including the FileFormat option causes error. Eg: doc.SaveAs(merge_path,WDFormatDocument97)
        succeeded = true
        debug_info << "Saved successfully"
      rescue Exception => reason
        debug_info << "Failed while saving merge file"
        Merb.logger.error "Document merge: Unable to save merged document to #{ merge_path }.(#{ reason }) Trace: #{ debug_info.inspect }"
      end
      
    rescue TypeError => reason
      
      Merb.logger.error "Document merge: The merge document extension does not look valid: #{ merge_path } (#{ reason }). Trace: #{ debug_info.inspect }"
      
    rescue IOError => reason
      
      Merb.logger.error "Document merge: The merge document path does not exist or is invalid: #{ merge_path } (#{ reason }). Trace: #{ debug_info.inspect }"
      
    rescue Exception => reason
      
      Merb.logger.error "Document merge: Failed while preparing Word or the merge document: #{ merge_path } (#{ reason }). Trace: #{ debug_info.inspect }"
      
    ensure
      
      debug_info << ' Begin housekeeping...'
      
      # Close Document: (And allow for when word.Documents.Open() failed and doc object was not created)
      begin
        doc.Close(WDDoNotSaveChanges) unless doc.nil?
        debug_info << '  Closed document successfully'
      rescue
        debug_info << "  Ignoring error during doc.Close (#{ reason })"
      ensure
        doc = nil
      end  
      
      # Close Word: (And allow for when WIN32OLE.new("Word.Application") failed and word object was not created)
      begin
        word.Quit(WDDoNotSaveChanges) unless word.nil?
        debug_info << '  Quit Word successfully'
      rescue Exception => reason
        debug_info << "  Ignoring error during word.Quit (#{ reason })"
      ensure
        word = nil
      end
      
      debug_info << ' Finished housekeeping'
      
    end

    message = "Document merge: Finished. Inserted #{ success_count } of #{ source_doc_paths.length } documents into #{ merge_path }"
    puts message
    Merb.logger.info message

    # Return success_count if we managed to get as far as saving the merge file:
    return succeeded ? success_count : false

  end

end


#  docs = [
#    "\\\\selfs\\Documents\\2010\\SV\\Letter\\Letter-Clear-95084-Sue Grimwood-08-06-2010_09-58.doc",
#    "\\\\selfs\\Documents\\2010\\SV\\Letter\\Letter-de Lance-Holmes-93286-Sally Walters-14-05-2010_12-13.doc",
#    "\\\\selfs\\Documents\\2010\\SV\\Letter\\Letter-Jacobs-94673-Alex Mudd-18-06-2010_15-56.doc"
#  ]
#
#  DocUtils::merge_docs 'c:\temp\merg_docs_test.doc', docs