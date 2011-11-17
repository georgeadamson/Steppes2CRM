class Tasks < Application
  # provides :xml, :yaml, :js

  def index
    only_provides :html, :json

    @client   = Client.get(params[:client_id])        if params[:client_id].to_i > 0
    @user     = User.get(params[:user_id])            if params[:user_id].to_i > 0
    @user   ||= session.user                          unless @client

    @tasks  = Task.all
    @tasks  = @tasks.all( :user   => @user   )        if @user
    @tasks  = @tasks.all( :client => @client )        if @client
    @tasks  = @tasks.all( :limit  => params[:limit] ) if params[:limit].to_i > 0

    display @tasks

  end

  def show(id)
    @task = Task.get(id)
    raise NotFound unless @task
    display @task
  end

  def new
    only_provides :html
    @task = Task.new
    display @task
  end

  def edit(id)
    only_provides :html
    @task = Task.get(id)
    raise NotFound unless @task
    display @task
  end

  def create(task)
  
    accept_valid_date_fields_for task, [ :due_date, :closed_date ]
    @task = Task.new(task)

    if @task.save
      redirect resource(@task), :message => {:notice => "Followup was created successfully"}
    else
      message[:error] = error_messages_for( @task, :header => 'Followup failed to be created because' )
      render :new
    end
  end

  def update(id, task)

    @task = Task.get(id)
    raise NotFound unless @task
    accept_valid_date_fields_for task, [ :due_date, :closed_date ]

    if @task.update(task)
       redirect resource(@task), :message => {:notice => "Followup was updated successfully"}
    else
      message[:error] = error_messages_for( @task, :header => 'Followup failed to be updated because' )
      display @task, :edit
    end

  end

  def destroy(id)
    @task = Task.get(id)
    raise NotFound unless @task
    if @task.destroy
      redirect resource(:tasks), :message => {:notice => "Followup was deleted successfully"}
    else
      message[:error] = error_messages_for( @task, :header => 'Followup could not be deleted because' )
      #raise InternalServerError
    end
  end

end # Tasks
