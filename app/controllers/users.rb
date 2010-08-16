class Users < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }


  # Important: See \app\views\exceptions\unauthenticated.html.erb for the login form.
  # Important: See \JRuby\jruby-1.4.0\lib\ruby\gems\1.8\gems\merb-auth-* for the auth code.
  

  def index
    @users = User.all
    display @users
  end

  def show(id)
    @user = User.get(id)
    raise NotFound unless @user
    display @user
  end

  def new
    only_provides :html
    @user = User.new
    display @user
  end

  def edit(id)
    only_provides :html
    @user = User.get(id)
    raise NotFound unless @user
    display @user
  end

  def create(user)
    generic_action_create( user, User )
  end

  def update(id, user)
    generic_action_update( id, user, User )
  end

  def destroy(id)
    generic_action_destroy( id, User )
  end

end # Users
