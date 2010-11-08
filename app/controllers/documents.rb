class Documents < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index

    @documents = get_filtered_documents()
    
    display @documents

  end

#  def download()
#    only_provides :doc, :pdf
#
#    id        = params[:id]
#    file_name = params[:name]
#
#    # Locate and download the document that matches id:
#    if id.to_i > 0
#
#      @document = Document.get(id)
#      raise NotFound unless @document
#      display @document, :layout => false
#      
#      if params[:format] && params[:format].to_sym == :pdf
#      
#        output_details = {}
#
#        if @document.generate_pdf( output_details )
#
#          download_name = "Copy of #{ @document.pdf_path }"
#          send_file( @document.pdf_path, :filename => download_name, :kind => 'application/pdf', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'
#          
#          # Delete the pdf file so we don't litter the file system with unnecessary docs:
#          #@document.delete_file! :pdf
#
#        else
#
#          output_details = "generate_pdf failed: #{ output_details.inspect }"
#          puts output_details
#          Merb.logger.error output_details
#
#        end
#
#      else  #if params[:format] && params[:format].to_sym == :doc
#
#        download_name = "Copy of #{ @document.doc_path }"
#
#        send_file( @document.doc_path, :filename => download_name, :kind => 'application/msword', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'
#      
#      end
#
#
#    # Download a specified file_name from the temp folder:
#    elsif file_name
#
#      only_provides :doc
#      
#      params[:format] ||= :doc
#      doc_path          = CRM[:doc_folder_path] / temp / file_name
#      download_name     = "Copy of #{ file_name }"
#
#      send_file( doc_path, :filename => download_name, :kind => 'application/msword', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'
#
#    end
#
#  end


  def show(id)
    only_provides :doc, :pdf, :html

    @document = Document.get(id)
    raise NotFound unless @document
    display @document, :layout => false
    
    if params[:format] && params[:format].to_sym == :pdf
    
      output_details = {}

      if @document.generate_pdf( output_details )

        download_name = "Copy of #{ @document.pdf_path }"
        send_file( @document.pdf_path, :filename => download_name, :kind => 'application/pdf', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'
        
        # Delete the pdf file so we don't litter the file system with unnecessary docs:
        #@document.delete_file! :pdf

      else

        output_details = "generate_pdf failed: #{ output_details.inspect }"
        puts output_details
        Merb.logger.error output_details

      end

    elsif params[:format] && params[:format].to_sym == :doc

      download_name = "Copy of #{ @document.doc_path }"

      send_file( @document.doc_path, :filename => download_name, :kind => 'application/msword', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'

    else # :html

      display @document
    
    end
      
  end

  def new
    only_provides :html
    @document = Document.new
    display @document
  end

  def edit(id)
    only_provides :html
    @document = Document.get(id)
    raise NotFound unless @document
    display @document
  end

  def create(document)

    @document = Document.new(document)
    @document.created_by = session.user.preferred_name if @document.created_by.blank?

    # Prevent immediate doc generation if specified:
    @document.generate_doc_after_create = false if @document.generate_doc_later

    next_page = params[:redirect_to] || :show


    # Important: Doc file builder will be triggered now if @document.generate_doc_after_create is true.
    if @document.save

      if @document.generate_doc_later

        run_later do
          @document.generate_doc
        end

        # document_status_id: 0=Pending, 1=Running, 2=Failed, 3=Succeeded:
        @document.document_status_id = 1

      end

      # document_status_id: 0=Pending, 1=Running, 2=Failed, 3=Succeeded:
      message[:notice] = @document.document_status_message || 'Document details were saved successfully.'

      if request.ajax?
        redirect next_page, :message => message, :ajax? => true
      else
        redirect next_page, :message => message
      end
      
    else

      message[:error] = "Document details could not be saved: #{ @document.errors.full_messages.join("\n") }"
      puts message.inspect
      #render :new

      if request.ajax?
        redirect next_page, :message => message, :ajax? => true
      else
        redirect next_page, :message => message
      end

    end

  end


  # UNUSED?
  def update(id, document)

    @document = Document.get(id)
    raise NotFound unless @document

    @client   = @document.client || Client.first(params[client_id])

    if @document.update(document)
      @documents = get_filtered_documents()
      render :index
    else
      display @document, :edit
    end

  end

  def delete(id)

    @document = Document.get(id)
    raise NotFound unless @document

    @client    = @document.client || Client.first(params[client_id])
    @documents = get_filtered_documents()

    if @document.destroy
      @documents.reload()
      message[:notice] = "The document has been deleted"
      render :index
      #redirect resource( @client, :documents )
    else
      message[:error] = "The document could not be deleted #{ error_message_for @document }"
      render :index
      #redirect resource( @client, :documents )
      #raise InternalServerError
    end

  end

  #  def destroy(id)
  #    @document = Document.get(id)
  #    raise NotFound unless @document
  #    @client   = @document.client || Client.first(params[client_id])
  #    if @document.destroy
  #      redirect resource( @client, :documents )
  #    else
  #      raise InternalServerError
  #    end
  #  end



private

  def get_filtered_documents

    documents = Document.all( :limit => 1000, :order => [ :trip_id, :created_at.desc ] )
    documents = documents.all( :trip_id => params[:trip_id] ) if params[:trip_id]
    
    # Maybe this could be done in one query but I'm not sure how:
    if params[:client_id] && @client = Client.get(params[:client_id])
		
		  trips_ids = @client.trips_ids || []

		  documents         = documents.all( :client_id => @client.id )
      related_documents = documents.all( :trip_id => trips_ids )

      documents.concat related_documents

		end

    return documents

  end

end # Documents
