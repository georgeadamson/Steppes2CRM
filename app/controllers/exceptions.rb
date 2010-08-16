class Exceptions < Merb::Controller
  provides :html, :json

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  # handle NotAuthorized exceptions (403)
  def not_authorized
    return standard_error #if request.ajax?
    render
  end
  
  # handle NotFound exceptions (404)
  def not_found
    return standard_error #if request.ajax?
    render
  end

  # handle NotAcceptable exceptions (406)
  def not_acceptable
    return standard_error #if request.ajax?
    render
  end


  def standard_error

    # When rendering non-ajax html we re-raise the error so we see full Merb error page:
    raise request.exceptions.first unless request.ajax? # content_type == :html

    @exceptions   = request.exceptions
    @show_details = Merb::Config[:exception_details]

    render :standard_error

  end

end