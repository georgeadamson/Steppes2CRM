# This is a default user class used to activate merb-auth.  Feel free to change from a User to 
# Some other class, or to remove it altogether.  If removed, merb-auth may not work by default.
#
# Don't forget that by default the salted_user mixin is used from merb-more
# You'll need to setup your db as per the salted_user mixin, and you'll need
# To use :password, and :password_confirmation when creating a user
#
# see merb/merb-auth/setup.rb to see how to disable the salted_user mixin
# 
# You will need to setup your database and create a user.
class User
  include DataMapper::Resource
  
  property :id,							Serial
  property :forename,				String, :required => true, :default => 'New user'
  property :name,						String, :required => true, :default => 'New user'  # AKA surname
  property :login,					String,	:required => true, :default => 'username', :unique => true  # AKA UserId
  property :is_active,			Boolean,:required => true, :default => true

  property :preferred_name,	String, :required => true, :default => 'New user'
  property :email,					String, :lazy => [:slow], :default => 'user@steppestravel.co.uk'
  property :profile,				String, :lazy => [:slow], :default => '', :length => 500, :unique => true
  property :signature_file,	String, :lazy => [:slow], :default => 'signature.jpg'
  property :portrait_file,	String, :lazy => [:slow], :default => 'portrait.jpg'

  belongs_to :company   # Formerly known as Consultant.PrimaryCompanyId
  
  # userGroup / privelages?

  has n, :trips         # Trip handler / Prepared by
  has n, :documents
  has n, :money_ins     # AKA Client Invoices
  has n, :money_outs    # Formerly known as SupplierPayment requests
  has n, :brochure_requests
  
  has n, :country_users  # Countries assigned to Consultants.
  has n, :countries, :through => :country_users

  # This is just a record of each User's clients recently worked on:
  has n, :user_clients, :order => [ :updated_at.desc ]
  has n, :clients, :through => :user_clients
  
  before :valid? do
    self.password ||= "password"
    self.password_confirmation ||= "password"
  end

  # Various ways of displaying names:
  def fullname; return "#{ self.forename } #{ self.name }"; end               # Eg: "James Armitage"
  def shortname; return "#{ self.forename } #{ self.name.slice(0,1) }"; end   # Eg: "James A"

	def name_and_is_active
		return "#{ self.fullname }#{ ' [Inactive]' unless self.is_active }"
	end

  alias surname name
	alias display_name name_and_is_active

  # Helper to return last n (most recent) OPEN clients from userClients table:
  def open_clients( limit = 50 )
    return self.user_clients.all( :is_open => true, :order => [ :is_selected.desc, :updated_at.desc ], :limit => limit ).clients
  end
  
  # Helper to return last n (most recent) OPENED clients from userClients table:
  # TODO: How can we sort by most recent first? The solution below seems to work but
  # the results cannot be filtered without causing sql error. A limitation of this DM version.
  def recent_clients( limit = 50 )
    #return self.clients.all( :limit => limit )
    return self.user_clients.all( :order => [ :is_selected.desc, :is_open.desc, :updated_at.desc ], :limit => limit ).clients
  end

  # Helper to return the current (or most recent) client from user_clients table:
  def most_recent_client
    #return self.clients.first( :order => [ :is_selected.desc, :is_open.desc, :updated_at.desc ] )
    #return self.recent_clients.first
    most_recent = self.user_clients.first( :order => [ :is_selected.desc, :is_open.desc, :updated_at.desc ] )
    return most_recent && most_recent.client || nil
  end
  alias recent_client most_recent_client

end
