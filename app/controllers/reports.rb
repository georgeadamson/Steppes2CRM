class Reports < Application
  provides :html, :csv

  # reports index is same as new.
  # TODO: Find a way to 'redirect to' or render new in ajax.
  def index
    only_provides :html
    @report = Report.new
    display @report, :new
  end

  def show(id)

    only_provides :html, :csv
    @report = Report.get(id)
    raise NotFound unless @report

    display @report, :show

  end

  def new
    only_provides :html
    @report = Report.new
    display @report
  end

  def edit(id)
    only_provides :html
    @report = Report.get(id)
    raise NotFound unless @report
    display @report
  end

  def filters()
    
    id ||= ( params[:report] && params[:report][:id] ) || params[:report_id]
    @report = id ? Report.get(id) : Report.new

    display @report

  end



  def create(report)

    @report = Report.new(report)

    # Render new report form if user has changed source:
    if @report.source != params[:old_report_source]
      render :new

    # Run report if the "run" submit button was pressed:
    elsif params[:run_report]
      @report.report_fields << ReportField.new( :name => :name ) if @report.report_fields.empty?
      render :show

    # Save report if the "save" submit button was pressed:
    elsif params[:save_report]

      if @report.save
        redirect resource(@report,:edit), :message => {:notice => "New report saved successfully"}
      else
        message[:error] = "Report failed to be saved"
        render :new
      end

    # Otherwise I've no idea what's going on so just render new report form:
    else
      render :new
    end

  end

  def update(id, report)

    @report = Report.get(id)
    raise NotFound unless @report
    @report.attributes = report

    # Render new report form if user has changed source:
    if report[:source] && report[:source] != @report.source
      display @report, :edit

    # Run report if the "run" submit button was pressed:
    elsif params[:run_report]
      render :show

    # Save report if the "save" submit button was pressed:
    elsif params[:save_report]

      if @report.save
        message[:notice] = "Report saved successfully"
        display @report, :edit
      else
        message[:error] = "Report failed to be saved"
        display @report, :edit
      end

    # Otherwise I've no idea what's going on so just render new report form:
    else
      display @report, :edit
    end

  end


  def destroy(id)
    @report = Report.get(id)
    raise NotFound unless @report
    if @report.destroy
      redirect resource(:reports)
    else
      raise InternalServerError
    end
  end


  def delete(id)

    @report = Report.get(id)
    #raise NotFound unless @report

    if !@report || @report.destroy
      message[:notice] = "The report has been deleted"
      if request.ajax?
        display Report.new, :new
      else
        redirect resource(:reports, :new), :message => message
      end
    else
      message[:error] = "Failed to delete report"
      display @report, :edit
    end

  end

end # Reports
