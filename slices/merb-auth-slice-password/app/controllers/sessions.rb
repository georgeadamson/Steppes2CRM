class MerbAuthSlicePassword::Sessions < MerbAuthSlicePassword::Application

  after :redirect_after_login,  :only => :update, :if => lambda{ !(300..399).include?(status) }
  after :redirect_after_logout, :only => :destroy

  # Nov 2010: Removed the message after login to tidy up the ugly url that it caused.
  # More info: http://groups.google.com/group/merb/browse_thread/thread/bf3d66ba709ce7e3/e0cc38c3105cddfa?lnk=gst&q=merb-auth+url#e0cc38c3105cddfa

  private   
  # @overwritable
  def redirect_after_login
    message[:notice] = "Authenticated Successfully"
    #redirect_back_or "/", :message => message, :ignore => [slice_url(:login), slice_url(:logout)]
    redirect_back_or "/", :ignore => [slice_url(:login), slice_url(:logout)]
  end
  
  # @overwritable
  def redirect_after_logout
    message[:notice] = "Logged Out"
    redirect "/", :message => message
  end
  
end