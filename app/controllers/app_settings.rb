class AppSettings < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @app_settings = AppSetting.all
    display @app_settings
  end

  def show(id)
    @app_setting = AppSetting.get(id)
    raise NotFound unless @app_setting
    display @app_setting
  end

  def new
    only_provides :html
    @app_setting = AppSetting.new
    display @app_setting
  end

  def edit(id)
    only_provides :html
    @app_setting = AppSetting.get(id)
    raise NotFound unless @app_setting
    display @app_setting
  end

  def create(app_setting)
    generic_action_create( app_setting, AppSetting )
  end

  def update(id, app_setting)
    generic_action_update( id, app_setting, AppSetting )
  end

  def destroy(id)
    generic_action_destroy( id, AppSetting )
  end

end # AppSettings
