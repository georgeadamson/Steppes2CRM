class Notes < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
	# Append success/failure messages onto ajax responses:
	after  Proc.new{

		if request.ajax?
			self.body += '<div class="errorMessage hidden">'  + message[:error]  + '</div>' unless message[:error].nil?
			self.body += '<div class="noticeMessage hidden">' + message[:notice] + '</div>' unless message[:notice].nil?
		end
	}

  def index
    @client = Client.get(params[:client_id])
    @notes  = ( @client.notes || Note).all
    display @notes #, request.ajax? ? { :layout=>false } : nil
  end

  def show(id)
		client_id = params[:client_id]
		@client = Client.get(client_id)
		if id == '0'
			@note   = Note.new( :id => 0, :client_id => client_id )
		else
			@note = Note.get(id)
			raise NotFound unless @note
		end
		display @note #, request.ajax? ? { :layout=>false } : nil
  end

  def new
		only_provides :html
		@client = Client.get(params[:client_id])
    @note   = Note.new( :client_id => params[:client_id] )
    display @note #, request.ajax? ? { :layout=>false } : nil
  end

  def edit(id)
    only_provides :html
		@client = Client.get(params[:client_id])
    @note = Note.get(id)
    raise NotFound unless @note
    display @note #, request.ajax? ? { :layout=>false } : nil
  end

  def create(note)
    @note = Note.new(note)
	  @client = Client.get(params[:client_id])
    if @note.save
 
      #redirect resource(@note), :message => {:notice => "Note was successfully created"}
      message[:notice] = "Note was created successfully"
      
      @only_just_created = true
      @notes = @note.client.notes

      if request.ajax?
        #render(:index, :layout=>false )
        #layout = false
        render :index #, :layout => false
      else
        redirect nested_resource( @note.client, @note ), :message => { :notice => message[:notice] }
      end
 
    else
      message[:error] = "Note failed to be created"
      render :new
    end
  end

  def update(id, note)
    @note   = Note.get(id)
    @client = @note.client
    raise NotFound unless @note
    if @note.update(note)

      #redirect resource(@note)
      message[:notice] = "Note was created successfully"
			
      if request.ajax?
        render :index #, :layout=>false
      else
        redirect nested_resource( @note.client, @note ), :message => { :notice => message[:notice] }
      end
 
    else
      display @note, :edit
    end
  end

  def destroy(id)
    @note = Note.get(id)
    raise NotFound unless @note
    if @note.destroy
      redirect resource(:notes)
    else
      raise InternalServerError
    end
  end

end # Notes
