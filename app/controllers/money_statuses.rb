class MoneyStatuses < Application
  # provides :xml, :yaml, :js

  def index
    @money_statuses = MoneyStatus.all
    display @money_statuses
  end

  def show(id)
    @money_status = MoneyStatus.get(id)
    raise NotFound unless @money_status
    display @money_status
  end

  def new
    only_provides :html
    @money_status = MoneyStatus.new
    display @money_status
  end

  def edit(id)
    only_provides :html
    @money_status = MoneyStatus.get(id)
    raise NotFound unless @money_status
    display @money_status
  end

  def create(money_status)
    @money_status = MoneyStatus.new(money_status)
    if @money_status.save
      redirect resource(@money_status), :message => {:notice => "MoneyStatus was successfully created"}
    else
      message[:error] = "MoneyStatus failed to be created"
      render :new
    end
  end

  def update(id, money_status)
    @money_status = MoneyStatus.get(id)
    raise NotFound unless @money_status
    if @money_status.update(money_status)
       redirect resource(@money_status)
    else
      display @money_status, :edit
    end
  end

  def destroy(id)
    @money_status = MoneyStatus.get(id)
    raise NotFound unless @money_status
    if @money_status.destroy
      redirect resource(:money_statuses)
    else
      raise InternalServerError
    end
  end

end # MoneyStatuses
