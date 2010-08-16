class Postcodes < Application
  # provides :xml, :yaml, :js

  def index
    only_provides :html, :json

    q = params[:q] || params[:postcode]

    @postcodes = Postcode.all(   :limit => 100, :order => [:address1, :address2, :address3], :repository => :postcodes )
    @postcodes = @postcodes.all( :limit => params[:limit].to_i )  if params[:limit].to_i > 0
    @postcodes = @postcodes.all( :postcode.like => "#{ q }%" )    if q

    display @postcodes, :layout => false

  end

#  def show(id)
#    @postcode = Postcode.get(id)
#    raise NotFound unless @postcode
#    display @postcode
#  end
#
#  def new
#    only_provides :html
#    @postcode = Postcode.new
#    display @postcode
#  end
#
#  def edit(id)
#    only_provides :html
#    @postcode = Postcode.get(id)
#    raise NotFound unless @postcode
#    display @postcode
#  end
#
#  def create(postcode)
#    @postcode = Postcode.new(postcode)
#    if @postcode.save
#      redirect resource(@postcode), :message => {:notice => "Postcode was successfully created"}
#    else
#      message[:error] = "Postcode failed to be created"
#      render :new
#    end
#  end
#
#  def update(id, postcode)
#    @postcode = Postcode.get(id)
#    raise NotFound unless @postcode
#    if @postcode.update(postcode)
#       redirect resource(@postcode)
#    else
#      display @postcode, :edit
#    end
#  end
#
#  def destroy(id)
#    @postcode = Postcode.get(id)
#    raise NotFound unless @postcode
#    if @postcode.destroy
#      redirect resource(:postcodes)
#    else
#      raise InternalServerError
#    end
#  end

end # Postcodes
