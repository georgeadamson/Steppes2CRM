
# Shared methods and customisations...


# Set up a custom GLOBAL CACHE hash for storing common lookup tables etc:
# Warning: Try to use these for lists that do not change much!
# Note: DataMapper will not actually populate these until they're called for the first time.
$cached = {
	:trip_states			    => TripState.all( :order=>[:id] ),
	:trip_client_statuses => TripClientStatus.all( :order=>[:id] ),
	:world_regions		    => WorldRegion.all( :order=>[:name] ),
	:mailing_zones		    => MailingZone.all( :order=>[:order_by] ),
	:exchange_rates	      => ExchangeRate.all( :order=>[:name] ),
	:airports					    => Airport.all( :order=>[:name] ),
	:countries				    => Country.all( :order=>[:name] ),
	:suppliers				    => Supplier.all( :order=>[:name] ),
	:document_types		    => DocumentType.all( :order=>[:id] ),
	:users						    => User.all( :order=>[:name] ),
	:web_request_statuses	=> WebRequestStatus.all( :order=>[:id] ),
	:companies          	=> Company.all( :is_active => true, :order=>[:name] )
}


#$cached[:airlines]= $cached[:suppliers].all( :type_id => 1 )
#$cached[:agents]	= $cached[:suppliers].all( :type_id => 2 )
#$cached[:accomms]	= $cached[:suppliers].all( :type_id => 4 )
#$cached[:grounds] = $cached[:suppliers].all( :type_id => 5 )
#$cached[:miscs]		= $cached[:suppliers].all( :type_id => 8 )


# This utility repopulates cached hashes of lookup tables: (Eg: generates $cached[:trips_states_hash] from $cached[:trips_states] )
def refresh_cached_hash_of(list_name)
	
	# Trim the '_hash' suffix off list_name if nesessary:
	# Derive hash_name by appending '_hash' string to list_name if necessary:
	list_name = list_name.to_s.split('_hash').shift.to_sym
	hash_name = list_name.to_s.concat('_hash').to_sym
	
	# Clear and repopulate the hash:
	$cached[hash_name] = {}
	$cached[list_name].reload().each{ |item|
		# $cached[hash_name][item.id] = ( item.respond_to?(:display_name) ? item.display_name : item.name )
		$cached[hash_name][item.id] = item.name
	}

	print " Finished running: refresh_cached_hash_of(#{ list_name }) \n"
	
	return $cached[hash_name]
	
end


# Helper for accessing our cached data: (Populates $cached[list_hash] if necessary)
def cached(list_name)
	
	# If list_name ends with '_hash' then ensure the hash is in the cache before we proceed:
	refresh_cached_hash_of(list_name) if list_name.to_s.split('_').pop == 'hash' && !$cached[list_name]
	
	return $cached[list_name]
	
end




# Shorthand helper for escaping text for a url: (Rather like h() the html escape method)
def u(text)
	return CGI::escape(text)
end





# Custom DATE formats: (Usage: @date.formatted(:uidate) => "27-11-2010")
# Date.add_format(:example, "%H:%M:%S %Y-%m-%d") => @date.formatted(:example).should == "00:00:00 2007-11-02"
Date.add_format(:uitime,			'%H:%M')					# "hh:mm"
Date.add_format(:uidate,			'%d/%m/%Y')				# "dd/mm/yyyy"
Date.add_format(:uidatelong,	'%d %b %Y')		    # "11 December 2012"
Date.add_format(:uidatetime,	'%d/%m/%Y %H:%M')	# "dd/mm/yyyy hh:mm"
Date.add_format(:uidisplay,		'%a %d %b %Y')		# "Mon 11 Dec 2012"
Date.add_format(:filedatetime,'%d-%m-%Y_%H-%M')	# "dd-mm-yyyy_hh-mm"


# Custom CURRENCY format:
# Eg: 100.to_currency(:generic) => '100.00'

  new_currency_format = {
		:generic => {
			:number => {
				:precision	=> 2,
				:delimiter	=> '',			# No thousands comma
				:separator	=> '.'
			},
			:currency => {
				:precision	=> 2,
				:delimiter	=> ',',
				:separator	=> '.',
				:unit				=> '',			# No currency symbol
				:format			=> '%n %u'
			}
		}
	}
	
	Numeric::Transformer.add_format(new_currency_format)
  


# Helper object used for adding a fake 'prompt' item at the top of a bound pick list:
# Use this when you need a prompt with an actual value (default value is 0)
# Sample usage: supplier_prompt = FakeListItem.new('-- Please choose')
#               select :collection => suppliers.all.unshift(supplier_prompt), ...
class FakeListItem

  attr_accessor :id
  attr_accessor :name

  # Mimic methods that the select helper's :text_method may try to access:
  alias :value                  :id
  alias :display_name           :name
  alias :fullname               :name
  alias :code_and_name          :name
  alias :name_and_code          :name
  alias :name_and_currency      :name
  alias :name_code_and_currency :name
  
  # Fake some other methods that the select helper may try to access:
  attr_accessor :saved?
  attr_accessor :readonly?
  attr_accessor :attributes
  attr_accessor :collection
  def map; return [yield(self)]; end

  def initialize( name = '- Please choose', id = 0 )
    @id   = id
    @name = name
  end

end