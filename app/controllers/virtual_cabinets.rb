class VirtualCabinets < Application
  # provides :xml, :yaml, :js
  
	before :ensure_authenticated
  
  # /users/:id/virtual_cabinets/create?client_id=xxx
  def open(client_id)
    
    user_id     = params[:user_id] || current_user.id
    client_id ||= params[:client_id]
    trip_id     = params[:trip_id]
    
    info = "Generating Virtual Cabinet Command File for user_id #{ user_id.inspect }, client_id #{ client_id.inspect}, trip_id #{ trip_id.inspect }"
    puts info
    Merb.logger.info info
    
    raise NotFound if client_id.nil?
    
    result =  VirtualCabinet.create user_id, client_id, trip_id
    
    client = Client.get(client_id)
    message[:notice] = "I've politely asked Virtual Cabinet to open docs #{ client.nil? ? '' : "for #{client.fullname}" } <br> <small>(Geeky stuff: #{result.to_s})</small>"
    
    render :show
    
  end
  
end