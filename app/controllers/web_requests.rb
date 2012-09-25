class WebRequests < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @web_requests = WebRequest.all
    display @web_requests
  end

  def show(id)
    @web_request = WebRequest.get(id)
    raise NotFound unless @web_request
    display @web_request
  end

  def new
    only_provides :html
    @web_request = WebRequest.new
    display @web_request
  end

  def edit(id)
    only_provides :html
    @web_request = WebRequest.get(id)
    raise NotFound unless @web_request
    display @web_request
  end

  def create(web_request)

    @web_request = WebRequest.new(web_request)

    if @web_request.save
      redirect resource(@web_request), :message => {:notice => "WebRequest was successfully created"}
    else
      message[:error] = "WebRequest failed to be created"
      render :new
    end

  end

  def update(id, web_request)

    @web_request = WebRequest.get(id)
    raise NotFound unless @web_request

    # Prepare helper flags to make the rest of the code more readable:
    is_new_client = web_request[:client_attributes] && web_request[:client_attributes][:id].blank?
    is_old_client = web_request[:client_attributes] && !web_request[:client_attributes][:id].blank?
    # Bit of a hack but I couldn't find a better way to track this:
    @web_request.status_id_before_save = @web_request.status_id
    
    # The following checks are necessary because we're trying to handle more than one possible action here:
    # Scenario 1: The Web Request is beng assigned to a new client so we need to create a new client record.
    # Scenario 2: The Web Request is beng assigned to an existing client so we need to just set the client_id.
    # Scenario 3: The Web Request is beng allocated to a company so we just set the company_id.
    # Scenario 4: The Web Request is beng discarded so all we're doing is setting the status_id.
    
    # Ensure the correct status is being set when assigning a new or existing client:
    # web_request[:status_id] = WebRequestStatus::PROCESSED if web_request[:status_id] == WebRequestStatus::ALLOCATED && is_old_client    # Process (assign to) client
    # web_request[:status_id] = WebRequestStatus::ALLOCATED if web_request[:status_id] == WebRequestStatus::PROCESSED && is_new_client    # Import client
    
    # (Scenario 1) The mere presence of the client id attribute will prevent NEW CLIENT from saving: (even if id is an empty string)
    web_request[:client_attributes].delete(:id) if is_new_client
    
    # (Scenario 2) We don't want to overwrite attributes of an EXISTING CLIENT, so delete them and assign client_id instead!
    new_client_attrs = web_request[:client_attributes]
    web_request[:client_id] = web_request.delete(:client_attributes)[:id] if is_old_client
    
    # (Scenario 1 & 2) Remember whether the @web_request was assigned to a client before this update:
    was_not_assigned_to_client = !@web_request.client
    
    # Feeble attempt to assume a default source when absolutely necessary:
    if web_request[:client_attributes]
      web_request[:client_attributes][:source_id]          = ClientSource.first(:name => 'Web request').id || ClientSource.first(:name => 'Unknown').id || ClientSource.first(:name => 'Google').id if web_request[:client_attributes][:source_id].blank?
      web_request[:client_attributes][:original_source_id] = web_request[:client_attributes][:source_id] if web_request[:client_attributes][:original_source_id].blank?
    end
    
    
    # Workaround for odd symptoms when saving webrequest with new client: (See bug #537)
    client_attributes = web_request.delete(:client_attributes)
    
    
    if @web_request.update(web_request)
      
      # Workaround for odd symptoms when saving webrequest with new client: (See bug #537)
      # DM seemed to get confused about saving new client using nested attributes. Failed to discover cause.
      if client_attributes
        
        if is_new_client
          client = Client.new(client_attributes)
        else
          client = Client.get(client_attributes[:id])
        end
        
        @web_request.client = client
        
      end
      
      # (Scenario 1) Explicitly save nested associations: (because they may be too nested to have been saved automatically)
      if client
        
        #client.addresses.save if client.addresses.first && client.addresses.first.new?
        #client.client_interests.save if client.client_interests
        client.source_id = new_client_attrs[:source_id] if new_client_attrs[:source_id]
        
        client.original_company_id ||= @web_request.company_id || session.user.company_id
        client.created_by            = session.user.fullname if client.new? && client.created_by.blank?
        client.updated_by            = session.user.fullname
        if client.save!
          # Client created successfully!
        else
          puts "FAILED to create client: valid? #{client.valid?} errors #{client.errors.inspect}"
        end
        
        @web_request.save if is_new_client
        
      end
      
      # (Scenario 1 & 2) Pass special params to next page instructing client-side script to open a client tab:
      is_now_assigned_to_client = !!@web_request.client
      args = was_not_assigned_to_client && is_now_assigned_to_client ? { :open_client_id => @web_request.client.id } : {}
      
      # Generic default message:
      message[:notice] = 'The web request has been updated'
      
      # Or provide a more specific message if possible:
      if @web_request.status_id != @web_request.status_id_before_save
        case @web_request.status_id
          when WebRequestStatus::PROCESSED then message[:notice] = "The web request has been processed for #{ @web_request.client.fullname }\n#{ 'The new client has been added to the system' if is_new_client }"
          when WebRequestStatus::ALLOCATED then message[:notice] = "The web request has been allocated to #{ @web_request.company.name }"
          when WebRequestStatus::REJECTED  then message[:notice] = 'The web request has been rejected'
        end
      end

      if @web_request.brochure_request
       consultant = @web_request.brochure_request.user
       message[:notice] << "\n A Brochure Request has been created automatically"
       message[:notice] << " and assigned to #{ consultant.preferred_name }" if consultant
       message[:notice] << '.'
      end

      # Note: args may include "open_client_id=1234" to instruct ui to open a client:
      redirect resource( :web_requests, args ), :message => message

    else
      collect_child_error_messages_for @web_request, @web_request.client
      collect_error_messages_for @web_request.client, :addresses
      message[:error] = "The web request could not be updated because #{ error_messages_for @web_request }"
      display @web_request, :edit
    end

  end


  def destroy(id)
    @web_request = WebRequest.get(id)
    raise NotFound unless @web_request
    if @web_request.destroy
      redirect resource(:web_requests)
    else
      raise InternalServerError
    end
  end

end # WebRequests
