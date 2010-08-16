class MoneyOuts < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @money_outs = MoneyOut.all( :order => [:supplier_id, :id], :limit => 500 )
    @money_outs = @money_outs.all( :trip_id => params[:trip_id] ) if params[:trip_id].to_i > 0
    display @money_outs
  end

  def show(id)
    @money_out = MoneyOut.get(id)
    raise NotFound unless @money_out
    display @money_out
  end

  def new

    only_provides :html
    @money_out = MoneyOut.new

    @user     = @money_out.user      = session.user
    @trip     = @money_out.trip      = Trip.get(params[:trip_id])
    @supplier = @money_out.supplier  = Supplier.get(params[:supplier_id])
    @currency = @money_out.currency  = @money_out.supplier && @money_out.supplier.currency || ExchangeRate.get(params[:currency_id]) || ExchangeRate.get(1) # Finally default to GBP if necessary
    
    display @money_out

  end

  def edit(id)
    only_provides :html
    @money_out = MoneyOut.get(id)
    raise NotFound unless @money_out
    display @money_out
  end

  def create(money_out)
    @money_out = MoneyOut.new(money_out)
    if @money_out.save
      redirect nested_resource(@money_out.trip,:money_outs), :message => {:notice => "Your payment request was created successfully"}
    else
      message[:error] = "MoneyOut failed to be created because #{ error_messages_for @money_out }"
      render :new
    end
  end

  def update(id, money_out)
    @money_out = MoneyOut.get(id)
    raise NotFound unless @money_out
    if @money_out.update(money_out)
       redirect resource(@money_out)
    else
      display @money_out, :edit
    end
  end

  def destroy(id)
    @money_out = MoneyOut.get(id)
    raise NotFound unless @money_out
    if @money_out.destroy
      redirect resource(:money_outs)
    else
      raise InternalServerError
    end
  end

end # MoneyOuts
