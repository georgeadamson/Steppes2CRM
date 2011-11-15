class Application < Merb::Controller
  # Flag used for daily ExchangeRate updates
  
  # Assume alternative layout for ajax or full page requests:
  before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  before :determine_client_or_tour
  before :cache_recent_params
  before :update_exchange_rates
  before :update_todays_completed_trips
  before :update_todays_abandonned_trips
  

  # Helper to set @client_or_tour in every request if possible/relevant:
  def determine_client_or_tour
    tour   = params[:tour_id]   && Tour.get( params[:tour_id] )
    client = params[:client_id] && Client.get( params[:client_id] )
    @client_or_tour = tour || client || ( session.user && session.user.most_recent_client )
  end


  # Make a note of the latest index_filter and type_id filters found in the url params:
  def cache_recent_params
    
    # Beware! Storing a hash is troublesome if you only update part of it. Eg: session[:recent][:index_filter] did not work well!
  
	  session[:recent_supplier_type_id] = params[:type_id]      if params[:type_id]
	  session[:recent_index_filter]     = params[:index_filter] if params[:index_filter]
	  session[:recent_index_filter]   ||= 'A'                   # Default to items beginning with A.

  end


  # Run exchange rate updates:
  def update_exchange_rates

    @@exchange_rates_updated_date ||= Date.today - 1

    if @@exchange_rates_updated_date < Date.today

      # We only want to update rates that have not been updated yet today: (TODO: How do you match new_rate==rate in the query?)
      rates = ExchangeRate.all( :new_rate_on_date.lte => Date.today ).reject{|r| r.new_rate == r.rate }

      rates.each do |rate|
        old_rate = rate.rate
        rate.update!( :rate => rate.new_rate, :updated_at => DateTime.now )
        puts "Updated Exchange Rate '#{ rate.name }' from #{ old_rate } to #{ rate.new_rate } #{ DateTime.now.formatted(:uidatetime) }"
      end

      puts "Updated #{ rates.length } Exchange Rates #{ Time.now.formatted(:uidatetime) }"
      @@exchange_rates_updated_date = Date.today

    end

  end


  # Flag all the confirmed trips that ended yesterday, as COMPLETED:
  def update_todays_completed_trips

    @@completed_trips_updated_date ||= Date.today - 1

    if @@completed_trips_updated_date < Date.today

      trips = Trip.all_ready_to_complete
      trips.update! :status_id => TripState::COMPLETED, :updated_at => DateTime.now, :updated_by => 'Changed to COMPLETED automatically'

      puts "Updated #{ trips.length } Trips to 'Completed' #{ DateTime.now.formatted(:uidatetime) }"
      @@completed_trips_updated_date = Date.today

    end

  end

  
  # Flag all the unconfirmed trips that [would have] started yesterday, as ABANDONED:
  def update_todays_abandonned_trips

    @@abandoned_trips_updated_date ||= Date.today - 1
    
    if @@abandoned_trips_updated_date < Date.today
      
      trips = Trip.all_ready_to_abandon
      trips.update! :status_id => TripState::ABANDONED, :updated_at => DateTime.now, :updated_by => 'Changed to ABANDONED automatically'

      puts "Updated #{ trips.length } Trips to 'Abandoned' #{ DateTime.now.formatted(:uidatetime) }"
      @@abandoned_trips_updated_date = Date.today
      
    end

  end



end