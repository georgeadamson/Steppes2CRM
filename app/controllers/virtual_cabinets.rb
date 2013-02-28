class VirtualCabinets < Application
  # provides :xml, :yaml, :js
  
	before :ensure_authenticated
  
  # /users/:id/virtual_cabinets/create?client_id=xxx
  def open(client_id)
    
    user_id     = params[:user_id] || current_user.id
    client_id ||= params[:client_id]
    trip_id     = params[:trip_id]
    
    puts user_id.inspect, client_id.inspect, trip_id.inspect
    
    raise NotFound if client_id.nil?
    
    return VirtualCabinet.create user_id, client_id, trip_id
    
  end
  
end