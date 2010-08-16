class MailingZones < Application
  # provides :xml, :yaml, :js

	# Assume ajax requests should respond without layout:
	#before Proc.new{ self.class.layout( request.ajax? ? :ajax : :application) }

  def index
    @mailing_zones = MailingZone.all
    display @mailing_zones
  end

  def show(id)
    @mailing_zone = MailingZone.get(id)
    raise NotFound unless @mailing_zone
    display @mailing_zone
  end

  def new
    only_provides :html
    @mailing_zone = MailingZone.new
    display @mailing_zone
  end

  def edit(id)
    only_provides :html
    @mailing_zone = MailingZone.get(id)
    raise NotFound unless @mailing_zone
    display @mailing_zone
  end

  def create(mailing_zone)
    generic_action_create( mailing_zone, MailingZone )
  end

  def update(id, mailing_zone)
    generic_action_update( id, mailing_zone, MailingZone )
  end

  def destroy(id)
    generic_action_destroy( id, MailingZone )
  end

end # MailingZones
