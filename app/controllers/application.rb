class Application < Merb::Controller
  # Flag used for daily ExchangeRate updates
  
  # Assume alternative layout for ajax or full page requests:
  before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  before :run_updates
  
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