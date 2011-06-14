class Application < Merb::Controller
  # Flag used for daily ExchangeRate updates
  
  # Assume alternative layout for ajax or full page requests:
  before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  #before Proc.new{ self.cache_recent_params }
  before :cache_recent_params
  before :run_updates
  

  # Make a note of the latest index_filter and type_id filters found in the url params:
  def cache_recent_params

#	  session[:most_recent] ||= {}
#	  session[:recent_supplier_type_id] = params[:type_id]      if params[:type_id]
#	  session[:recent_index_filter]     = params[:index_filter] if params[:index_filter]
#	  session[:recent_index_filter]   ||= 'A'                   # Default to items beginning with A.
#
#    # Hack: For some reason the session[:most_recent] does not get remembered unless we do this: WTF?!
#    session[:recent_supplier_type_id] = session[:recent_supplier_type_id]
#    session[:recent_index_filter]     = session[:recent_index_filter]
    
    # Beware! Storing a hash is troublesome if you only update part of it. Eg: session[:recent][:index_filter] did not work well!
  
	  session[:recent_supplier_type_id] = params[:type_id]      if params[:type_id]
	  session[:recent_index_filter]     = params[:index_filter] if params[:index_filter]
	  session[:recent_index_filter]   ||= 'A'                   # Default to items beginning with A.

  end


  # Run exchange rate updates
  def run_updates
    @@updates_run ||= Date.today - 1
    if @@updates_run < Date.today
      rates = ExchangeRate.all(:new_rate_on_date.lte => Date.today)
      rates.each do |rate|
        rate.update!( :rate => rate.new_rate )
      end
      @@updates_run = Date.today
    end
  end

end