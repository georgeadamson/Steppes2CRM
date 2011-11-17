class DocumentJobs < Application
  # provides :xml, :yaml, :js

  def index
    @document_jobs = DocumentJob.all
    display @document_jobs
  end

  def show(id)
    @document_job = DocumentJob.get(id)
    raise NotFound unless @document_job
    display @document_job
  end

  def new
    only_provides :html
    @document_job = DocumentJob.new
    display @document_job
  end

  def edit(id)
    only_provides :html
    @document_job = DocumentJob.get(id)
    raise NotFound unless @document_job
    display @document_job
  end

  def create(document_job)
    @document_job = DocumentJob.new(document_job)
    if @document_job.save
      redirect resource(@document_job), :message => {:notice => "DocumentJob was successfully created"}
    else
      message[:error] = "DocumentJob failed to be created"
      render :new
    end
  end

  def update(id, document_job)
    @document_job = DocumentJob.get(id)
    raise NotFound unless @document_job
    if @document_job.update(document_job)
       redirect resource(@document_job)
    else
      display @document_job, :edit
    end
  end

  def destroy(id)
    @document_job = DocumentJob.get(id)
    raise NotFound unless @document_job
    if @document_job.destroy
      redirect resource(:document_jobs)
    else
      raise InternalServerError
    end
  end

end # DocumentJobs
