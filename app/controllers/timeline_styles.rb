class TimelineStyles < Application

  #cache!

  def index
    provides :css
    render :layout => false
  end
  
end
