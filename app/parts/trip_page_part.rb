class TripPagePart < Merb::PartController

  def index
    @trip = Trip
    @trips = Trips
    render
  end

end
