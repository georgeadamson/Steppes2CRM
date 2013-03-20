class VirtualCabinets < Application
  # provides :xml, :yaml, :js

	before :ensure_authenticated

  # /users/:id/virtual_cabinets/create?client_or_tour_id=xxx
  def open()

    user_id             = params[:user_id]
    tour_id             = params[:tour_id]
    client_id           = params[:client_id]
    trip_id             = params[:trip_id]

    user                = ( user_id && User.get(user_id) ) || current_user
    client_or_tour      = tour_id.nil? ? Client.get(client_id) : Tour.get(tour_id)
    client_or_tour_name = client_or_tour.nil? ? '' : "for #{ client_or_tour.fullname }"

    raise NotFound if client_or_tour.nil?

    info = "Generating Virtual Cabinet Command File for user_id #{ user.id.inspect }, #{ tour_id.nil? ? 'client_id' : 'tour_id' } #{ client_or_tour.id.inspect }, trip_id #{ trip_id.inspect } (#{ client_or_tour_name })"
    puts info
    Merb.logger.info info

    result =  VirtualCabinet.create user, client_or_tour, trip_id
    message[:notice] = "I've politely asked Virtual Cabinet to open docs #{ client_or_tour_name } <br> <small>(Geeky stuff: #{ result.to_s })</small>"

    render :show

  end

end