class BrochureRequests < Application
  # provides :xml, :yaml, :js

  def index

    # Handle depricated filter params:
    params[:not_status_id] = BrochureRequest::CLEARED if params[:pending] || params[:brochure_merge]
    
    # Start with default limits and order then override later where parameters provided:
    @brochure_requests = BrochureRequest.all(    :limit => 500, :order => [ :requested_date.desc ] )
    @brochure_requests = @brochure_requests.all( :limit => params[:limit] ) if params[:limit].to_i > 0

    # Apply common filters where specified:
    @brochure_requests = @brochure_requests.all( :client_id     => params[:client_id]     ) if params[:client_id].to_i  > 0
    @brochure_requests = @brochure_requests.all( :company_id    => params[:company_id]    ) if params[:company_id].to_i > 0
    @brochure_requests = @brochure_requests.all( :user_id       => params[:user_id]       ) if params[:user_id].to_i    > 0
		@brochure_requests = @brochure_requests.all( :status_id     => params[:status_id]     ) if params[:status_id]
		@brochure_requests = @brochure_requests.all( :status_id.not => params[:not_status_id] ) if params[:not_status_id]
    
    display @brochure_requests

  end


  # This action expects an array of brochure_request_ids to be submitted to it: 
  def merge()

    provides :doc, :html

    if params[:brochure_request_ids] && !params[:brochure_request_ids].blank?

      @brochure_requests = BrochureRequest.all( :id => params[:brochure_request_ids] )

      # WARNING! This text must match button label: (TODO: Find a better way to distinguish Run and Clear!)
      if params[:submit] =~ /Run.*merge/

        only_provides :doc
        
        # TODO: Use more unique file name to avoid clashes!
        merge_path = 'c:\temp\merge_docs_tmp.doc'
        succeeded  = BrochureRequest.run_merge_for( @brochure_requests, merge_path, session.user )

        message[:notice] = "Brochure Merge has been run for #{ succeeded } brochure requests"

        download_name = "BrochureMerge.docx"
        return send_file( merge_path, :filename => download_name, :type => 'application/msword', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'
        
      else # params[:submit] =~ /Clear merge/

        if !@brochure_requests.empty? && result = BrochureRequest.clear_merge_for( @brochure_requests )
          message[:notice] = "Cleared #{ result } brochure requests"
        end

      end

    end

    redirect resource( :brochure_requests, params ) ##.merge( :message => message ||= nil ) )

  end


  def show(id)
    provides :doc

    @brochure_request = BrochureRequest.get(id)
    raise NotFound unless @brochure_request

    #  # For downloading a copy:
    #  if params[:format] && params[:format].to_sym == :doc
    #
    #    document      = @brochure_request.document
    #    download_name = "Copy of #{ document.doc_path }"
    #
    #    send_file( document.doc_path, :filename => download_name, :type => 'application/msword', :disposition => 'attachment' )	# :disposition => 'attachment'(default) or 'inline'
    #
    #  end

    if params[:generate_doc_now]

      if @brochure_request.generate_doc() && @brochure_request.doc_file_exist?

        message[:notice] = "Brochure request letter has been created"
        doc = @brochure_request.document
        return "#{ icon :document } #{ link_to File.basename(doc.doc_path), doc.doc_url }"  # Or to download a copy: resource(@brochure_request.document, :format => :doc )

      else
        message[:error]  = "Could not generate brochure letter" #because #{ @brochure_request.inspect }"
        return message[:error]
      end


    elsif @brochure_request.generate_doc_later

      run_later do
        @brochure_request.generate_doc()
      end
      message[:notice] = "Brochure request letter is being created"

    end

    display @brochure_request

  end


  def new
    only_provides :html
    @brochure_request         = BrochureRequest.new
    @brochure_request.user  ||= session.user
    display @brochure_request
  end


  def edit(id)
    only_provides :html
    @brochure_request = BrochureRequest.get(id)
    raise NotFound unless @brochure_request
    display @brochure_request
  end


  def create(brochure_request)

    @brochure_request = BrochureRequest.new(brochure_request)

    if @brochure_request.save

      client    = @brochure_request.client
      next_page = client ? resource(client, :brochure_requests) : resource(:brochure_requests)

      redirect next_page, :message => {:notice => "Brochure request was added successfully"}

    else
      message[:error] = "BrochureRequest failed to be created"
      render :new
    end

  end


  def update(id, brochure_request)

    @brochure_request = BrochureRequest.get(id)
    raise NotFound unless @brochure_request

    if @brochure_request.update(brochure_request)

      client    = @brochure_request.client
      next_page = params[:return_to] || ( client ? resource(client, :brochure_requests) : resource(:brochure_requests) )

      message[:notice] = "Brochure request was updated successfully"

      redirect next_page, :message => message

    else
      display @brochure_request, :edit
    end
    
  end


  def destroy(id)
    @brochure_request = BrochureRequest.get(id)
    raise NotFound unless @brochure_request
    if @brochure_request.destroy
      redirect resource(:brochure_requests)
    else
      raise InternalServerError
    end
  end

end # BrochureRequests
