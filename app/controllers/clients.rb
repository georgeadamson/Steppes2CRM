class Clients < Application
  # provides :xml, :yaml, :js

	before :ensure_authenticated
  #before :something_cool
    
	# Apply simpler layout template to ajax requests:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

	after Proc.new{
		if request.ajax?
			#layout = :ajax
			#self.body += '<h2 class="noticeMessage">' + message[:notice] + '</h2>' if message[:notice]
			#self.body += '<h2 class="errorMessage">'  + message[:error]  + '</h2>' if message[:error]
		end
	}

  def index

    @clients = Client.all(:limit => 10)
		
		#@clients = session.user.clients.all( :order => [ Client.user_clients.updated_at ], :limit => 10 ) if params[:recent]
		@clients = session.user.clients.all( :limit => 10 ) if params[:recent]
	
		#@clients = @clients.all( UserClient.user.id => session.user.id ) #if params[:recent]

    display @clients

  end


	# Perform fast client search when keywords are typed into the in the client-search box.
  def search
    #only_provides :json
    #provides :json

    # Eg: /search?q=Smith GL7 1AB&limit=20
    limit		= params[:limit].to_i.zero? ? 20 : params[:limit].to_i		# Max rows to return.
    words		= params[:q].to_s.strip.split(/\s+/)														# Words are separated by whitespace.
    prev_word	= nil

		# If the user provided any '*' wildcards then swap them for valid sql '%' wildcards:
		phrase = ( params[:q].to_s.strip.gsub(/\*/, '%') + ' ' ) || ''
		# Insert sql '%' wildcard after each word: (unless user provided their own wildcards)
		#phrase.gsub!( /\b /, '% ' ).strip! unless phrase.include? '%'

		# Prepare custom sql statement: (We rely on datamapper to handle escaping of dodgy charaters such as ')
		sql_statement = "EXEC usp_client_search ?, ?, ?"
		puts "Client search: #{ sql_statement }, #{ phrase }, #{ limit }, #{ session.user.id } (#{ session.user.id }=#{ session.user.preferred_name })"

		@clients = repository(:default).adapter.select( sql_statement, phrase, limit, session.user.id )

		display @clients, :layout => false

  end


  def summary(id)
    # Client summary page (AKA Client details!)
    @client = Client.get(id)
    raise NotFound unless @client
    #display partial('clients/summary', :client => @client), request.ajax? ? { :layout=>false } : nil
    display @client
  end

  def summary_marketing(id)
    # Client marketing panel in summary page
    @client = Client.get(id)
    raise NotFound unless @client
    display @client
  end
  
  def show(id)

    # Entire Client page with tabs for Details / Documents / Payments / Trips
    @client = Client.get(id)
    raise NotFound unless @client

    session.user ||= User.first
  
    # Move this client to the top of the current User's list of recently worked-on clients:
    if session.user
			session.user.clients << @client
			session.user.save
    end

    if @client.created_today?
      message[:notice] ||= ''
      message[:notice] << "Be sure to set this client's Original Source today. You won't be allowed to tomorrow!"
    end

    display @client

  end

	# Called when user selects a client tab: (Simply records the user's current visible client)
	def select_tab(id)
    only_provides :json

		session.user ||= User.first
		
    # Add new user_client record if it's not already there:
    session.user.user_clients.first_or_create( :client_id => id )

    # Update tracking flags for all affected user_client rows:
		session.user.user_clients.each do |user_client|

      # Set selected flag for current client id only:
			is_selected	= ( user_client.client_id == id.to_i )
      is_open     = is_selected ? true : user_client.is_open

      # Only update row if we've changed it: (We do this manually so that updated_at will be set)
      unless is_selected == user_client.is_selected && is_open == user_client.is_open
        user_client.update!(
          :is_open      => is_open,
          :is_selected  => is_selected,
          :updated_at   => DateTime.now # Explicity set date because hook will not be triggered by update!()
        )
      end

		end

    #	# Add client to the list if not already there:
    #	unless @user_client.nil?
    #		session.user.clients << @user_client.client
    #		@user_client.is_open     = true
    #		@user_client.is_selected = true
    #		session.user.save!
    #	end

    #@user_client.update!( :is_open => true, :is_selected => true ) unless @user_client.is_open && @user_client.is_selected
    
		return session.user.user_clients.count

	end

	# Called when user closes a client tab: (Simply records when client is no longer being worked on by the user)
	def close_tab(id)
    only_provides :json

		session.user ||= User.first

		# # In theory this should only update one row:
    #	session.user.user_clients.all( :client_id => id ).each do |user_client|
    #		user_client.is_open     = false
    #		user_client.is_selected = false
    #		user_client.save
    #		@user_client						= user_client
    #	end
      
    #	# Add client to the list if not already there:
    #	unless @user_client
    #		session.user.clients << @user_client.client
    #		@user_client.is_open     = false
    #		@user_client.is_selected = false
    #		session.user.save
    #    
    #	end

    user_client = session.user.user_clients.first_or_create( { :client_id => id } )
    user_client.update!( :is_open => false, :is_selected => false, :updated_at => DateTime.now )

		return session.user.user_clients.count

	end

  def new
    only_provides :html

    @client                    = Client.new
    @client.type             ||= ClientType.first # <-- TODO: This workaround should not be necessary!
    @client.original_company ||= session.user.company
    @client.companies        <<  @client.original_company

    display @client
  end

  def edit(id)
    only_provides :html
    @client = Client.get(id)
    raise NotFound unless @client
    display @client
  end


  def create(client)

		accept_valid_date_fields_for client, [ :birth_date, :passport_issue_date, :passport_expiry_date ]

		# Disregard the set of "new" address fields if they appear to be blank: (ie no new address provided)
		accept_new_address_unless_blank( client[:addresses_attributes] )

    @client = Client.new(client)
    #@client.address_client = nil #unless @client.addressClient

    @client.original_company_id ||= session.user.company_id
    @client.created_by          ||= session.user.fullname
    @client.updated_by          ||= session.user.fullname

    # For some reason, when copied from another client, addresses are not being saved so we have to create client_addresses association ourselves:
    if @client.addresses.length != client[:addresses_attributes].length
      client[:addresses_attributes].each do |idx,addr|
        is_primary = ( addr[:id] == client[:primary_address_id] )
        @client.client_addresses.new( :address_id => addr[:id], :is_active => is_primary )
      end
    end

    # Prevent the search keywords table from being updated right now:
    @client.auto_refresh_search_keywords_after_save = false

    if @client.save

      puts @client.addresses.length, client[:addresses_attributes].length

      # Now that new row has an id, make sure we self-reference the client's address if none specified:

      message[:notice] = "Client was added successfully"

      # Ensure search keywords table will be updated after responding to this request:
      run_later do
        @client.refresh_search_keywords() unless @client.auto_refresh_search_keywords_after_save
      end

      if request.ajax?
        render :show
      else
        redirect resource(@client), :message => message
      end

    else
      collect_error_messages_for @client, :countries
      message[:error] = "Client failed to be created <br/>" + @client.errors.full_messages.join('<br/>')
      render :new
    end

  end

  def update(id, client)
 
    @client = Client.get(id)
    raise NotFound unless @client

    # Validate date fields and
		# Discard the set of "new" address fields if they appear to be blank: (ie no new address provided)
		accept_valid_date_fields_for client, :birth_date, :passport_issue_date, :passport_expiry_date
		accept_new_address_unless_blank( client[:addresses_attributes] )
    primary_address_id_before_save  = @client.primary_address.id
    addresses_ids_before_save       = @client.addresses_ids
    message[:notice]              ||= ''
      
    # Look out for user setting a primary address and trying to delete it at the same time!
    # Solve the conflict by removing the _delete field and notifying the user:
    client[:addresses_attributes].each do |addr|

      # addr will be something like [ "1" => { :id => 123456, :address1 => ...etc }]
      addr = addr.last

      if addr[:_delete] && addr[:id] == client[:primary_address_id]
        addr.delete(:_delete)
        message[:notice] << "Oh good grief, you can't set a primary address and delete it at the same time. Muppet.\n"
      end

    end 
    
    # Prevent the search keywords table from being updated right now: (We'll use run_later instead)
    client[:auto_refresh_search_keywords_after_save] = false

    # Manually set attributes instead of relying on update(). (See saved_ok below)
    @client.attributes = client
    
    # Unsuccessful attempt to overcome overzealous deep validation errors by doing things manually:
    # Temporary fix. Kinda works but cannot handle address _delete.
    saved_ok = @client.valid? &&
              @client.client_interests.select{|obj| !obj.valid? }.empty? &&
              @client.client_addresses.select{|obj| !obj.valid? }.empty? &&
              @client.client_addresses.addresses.select{|obj| !obj.valid? }.empty? &&
              @client.client_interests.save! &&
              @client.client_addresses.save! &&
              @client.interests.save! &&
              @client.addresses.save! &&
              @client.save!

    puts "saved_ok #{ saved_ok } #{ message[:notice] }"

    #if @client.update(client)
    if saved_ok       

      
      @client.reload
      number_of_addresses_added   = ( @client.addresses_ids - addresses_ids_before_save ).length
      number_of_addresses_removed = ( addresses_ids_before_save - @client.addresses_ids ).length
      
      message[:notice] << "Client details were updated successfully"
      message[:notice] << "\n The primary address has been changed to \"#{ @client.primary_address.name }\""  if primary_address_id_before_save != @client.primary_address.id
      message[:notice] << "\n and #{ number_of_addresses_added   } new address has been added"                if number_of_addresses_added   > 0
      message[:notice] << "\n and #{ number_of_addresses_removed } address has been deleted"                  if number_of_addresses_removed > 0
      message[:notice] << "\n While you're here, why not choose a country for the primary address?"           if @client.country.id.to_i == 0

      collect_error_messages_for @client, :addresses
      collect_error_messages_for @client, :client_addresses
      message[:error] = "But #{ @client.errors.full_messages.join("\n") }" unless @client.errors.empty?

      # Ensure search keywords table will be updated after responding to this request:
      unless @client.auto_refresh_search_keywords_after_save
        run_later do
          @client.refresh_search_keywords()
        end
      end

      if request.ajax?
        render :summary
      else
        redirect resource(@client), :message => message
      end
      
    else
      collect_error_messages_for @client
      collect_error_messages_for @client, :countries # AKA interests
      collect_error_messages_for @client, :client_interests
      collect_error_messages_for @client, :addresses
      collect_error_messages_for @client, :client_addresses
      collect_error_messages_for @client, :client_marketing_divisions
      message[:error] = "Uh oh, could not update client details because \n" + @client.errors.full_messages.join('\n')
      display @client, :edit
    end
  end


  # ARCHIVE the client (by flagging it as deleted instead of actually destroying it)
  def destroy(id)

    @client = Client.get(id)
    raise NotFound unless @client

    @client.deleted_by = session.user.fullname
    
    if @client.archive
      message[:notice] = "#{ @client.fullname } has been deleted"
    end
    redirect "#{ resource(@client) }/summary", :message => message

  end





private


	# Disregard the set of "new" address fields if they all appear to be blank: (ie no new address provided)
	# Eg: Test for presence of field name="client[addresses_attributes][new][postcode]"
	# return: => The address
	# arg: addresses => Object
	def accept_new_address_unless_blank( addresses )
		
		if ( new_addr = addresses[:new] )

			fields = %w[address2 address3 address4 address5 postcode tel_home fax_home]

      # Discard the address if all these fields are blank:
			addresses.delete(:new) if fields.reject{ |field| new_addr[field].blank?	}.empty?
	
		end
		
	end


# Depricated in favour of faster dedicated stored procedure to handle client search:
#	def build_search_query_for(word, limit = 20)
#
#	  limit = 50000 if limit.zero?
#
#	  # Search word contains an '@' so we only need to match on EMAIL:
#    if word =~ /@/
#
#        word = '%' + word
#        print "Client search by email address: #{word}\n"
#        search = Client.all( :email1.like => word, :limit => limit ) |
#                 Client.all( :email2.like => word, :limit => limit )
#
#	  elsif word.sub('%','').length == 1
#
#        print "Client search by forename initial: #{word}\n"
#        search = Client.all( :forename.like => word, :limit => limit )
#
#    # Otherwise search name and postal ADDRESS fields:
#    else
#
#      print "Client search by address1-5: #{word}\n"
#      search = Client.all( Client.client_addresses.is_active => true, Client.addresses.address1.like => word, :limit => limit ) |
#               Client.all( Client.client_addresses.is_active => true, Client.addresses.address2.like => word, :limit => limit ) |
#               Client.all( Client.client_addresses.is_active => true, Client.addresses.address3.like => word, :limit => limit ) |
#               Client.all( Client.client_addresses.is_active => true, Client.addresses.address4.like => word, :limit => limit ) |
#               Client.all( Client.client_addresses.is_active => true, Client.addresses.address5.like => word, :limit => limit )
#
#			# Search word contains letter(s) followed by a number, or several digits in a row, so match on POSTCODE:
#			if word =~ /^[A-Za-z]{1,3}[0-9]/ or word =~ /^[0-9]{3,}$/
#
#				print "Client search by postcode: " + word + "\n"
#				search = search | Client.all( Client.client_addresses.is_active => true, Client.addresses.postcode.like => word, :limit => limit )
#
#			# Otherwise match on surname unless search words contains digits:
#			else
#
#        print "Client search by surname: #{word}\n"
#        search = search | Client.all( :name.like => word, :limit => limit ) unless word =~ /[0-9]/
#
#      end
#
#			return search
#
#    end
#
#	
#	end


end # Clients
