class Dashboards < Application
  # provides :xml, :yaml, :js
  provides :html, :json
  
	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
 
  
  def show(dashboard)
    @dashboard = dashboard
    display @dashboard
    end
  
  def monthly_bookings
    @dashboard = 'monthly_bookings'
    display @dashboard
  end
  
  
end
