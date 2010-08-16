class ExchangeRates < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @exchange_rates = ExchangeRate.all
    display @exchange_rates
  end

  def show(id)
    @exchange_rate = ExchangeRate.get(id)
    raise NotFound unless @exchange_rate
    display @exchange_rate
  end

  def new
    only_provides :html
    @exchange_rate = ExchangeRate.new
    display @exchange_rate
  end

  def edit(id)
    only_provides :html
    @exchange_rate = ExchangeRate.get(id)
    raise NotFound unless @exchange_rate
    display @exchange_rate
  end

  def create(exchange_rate)
		generic_action_create( exchange_rate, ExchangeRate )
  end

  def update(id, exchange_rate)
		generic_action_update( id, exchange_rate, ExchangeRate )
  end

  def destroy(id)
		generic_action_destroy( id, ExchangeRate )
  end

end # exchange_rates
