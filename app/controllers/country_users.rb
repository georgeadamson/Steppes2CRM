class CountryUsers < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }
  
  def index
    @country_users = CountryUser.all
    display @country_users
  end

  def show(id)
    @country_user = CountryUser.get(id)
    raise NotFound unless @country_user
    display @country_user
  end

  def new
    only_provides :html
    @country_user = CountryUser.new
    display @country_user
  end

  def edit(id)
    only_provides :html
    @country_user = CountryUser.get(id)
    raise NotFound unless @country_user
    display @country_user
  end

  def create(country_user)
    @country_user = CountryUser.new(country_user)
    if @country_user.save
      redirect resource(@country_user), :message => {:notice => "CountryUser was successfully created"}
    else
      message[:error] = "CountryUser failed to be created"
      render :new
    end
  end

  def update(id, country_user)
    @country_user = CountryUser.get(id)
    raise NotFound unless @country_user
    if @country_user.update_attributes(country_user)
       redirect resource(@country_user)
    else
      display @country_user, :edit
    end
  end

  def destroy(id)
    @country_user = CountryUser.get(id)
    raise NotFound unless @country_user
    if @country_user.destroy
      redirect resource(:country_users)
    else
      raise InternalServerError
    end
  end

end # CountryUsers
