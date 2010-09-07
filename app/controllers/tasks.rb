class Tasks < Application
  # provides :xml, :yaml, :js

  def index
    @tasks = Task.all
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
    @task = Task.new(task)
    if @task.save
      redirect resource(@task), :message => {:notice => "Task was successfully created"}
    else
      message[:error] = "Task failed to be created"
      render :new
    end
  end

  def update(id, task)
    @task = Task.get(id)
    raise NotFound unless @task
    if @task.update(task)
       redirect resource(@task)
    else
      display @task, :edit
    end
  end

  def destroy(id)
    @task = Task.get(id)
    raise NotFound unless @task
    if @task.destroy
      redirect resource(:tasks)
    else
      raise InternalServerError
    end
  end

end # Tasks
