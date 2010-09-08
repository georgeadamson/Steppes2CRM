class TaskTypes < Application
  # provides :xml, :yaml, :js

  def index
    @task_types = TaskType.all
    display @task_types
  end

  def show(id)
    @task_type = TaskType.get(id)
    raise NotFound unless @task_type
    display @task_type
  end

  def new
    only_provides :html
    @task_type = TaskType.new
    display @task_type
  end

  def edit(id)
    only_provides :html
    @task_type = TaskType.get(id)
    raise NotFound unless @task_type
    display @task_type
  end

  def create(task_type)
    generic_action_create( task_type, TaskType )
  end

  def update(id, task_type)
    generic_action_update( id, task_type, TaskType )
  end
  
  def destroy(id)
    generic_action_destroy( id, TaskType )
  end

end # TaskTypes
