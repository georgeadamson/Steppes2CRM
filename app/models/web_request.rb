class WebRequest
  include DataMapper::Resource
  
  property :id, Serial
  property :name,                 String,   :required => true,  :length => 50, :default => 'Web request'
  property :type_id,              Integer,  :required => true,  :default => lambda{ |w,prop| WebRequestType.first.id }
  property :status_id,            Integer,  :required => true,  :default => 1   # 1=Pending, 2=Processed, 3=Imported, 4=Rejected
  property :company_id,           Integer,  :required => false  # Only required when web request is being processed
  property :requested_date,       DateTime, :required => true,  :default => lambda{ |w,prop| DateTime.now }   # Used for legacy WebRequests only.
  property :received_date,        DateTime, :required => true,  :default => Time.now
  property :processed_date,       DateTime, :required => false
  property :xml_text,             Text                          # See conditional validation below,  :lazy => :raw_data  # Only required for NEW web requests, not legacy ones.
  property :email_text,           Text,     :required => false  #s, :lazy => :raw_data  # Used for LEGACY WebRequests only.
  property :user_id,              Integer,  :required => false
  property :client_id,            Integer,  :required => false
  property :country_name,         String,   :required => false, :length => 255  # Formerly CountryString
  property :referrer,             String,   :required => false, :length => 255
  property :keywords,             String,   :required => false, :length => 255
  property :first_page,           String,   :required => false, :length => 255
  property :where_from,           String,   :required => false, :length => 255
  property :origin_web_request_id,Integer,  :required => false

  belongs_to :type,   :model => "WebRequestType",   :child_key => [:type_id]
  belongs_to :status, :model => "WebRequestStatus", :child_key => [:status_id]
  belongs_to :client
  belongs_to :company

	accepts_nested_attributes_for :client
  
  # Only validate new web_requests: (Otherwise we get error when saving old clients etc)
  validates_present :xml_text, :if => :new?
  
  # Bit of a hack! The controller#update action sets this before updating the webrequest:
  attr_accessor :status_id_before_save
  
  before :save do
    self.status_id_before_save ||= self.original_attributes[:status_id]
    #puts "BEFORE SAVE: status_id=#{ self.status_id_before_save } #{ self.original_attributes[:status_id] } #{ self.status_id }"
  end
  
  before :update do
    # Assume 'Pending' web request has been 'Processed' if a client_id has been assigned:
    self.status_id_before_save ||= self.original_attributes[:status_id] || self.status_id
    self.status_id = WebRequestStatus::PENDING if ( self.processed? || self.imported? ) && !self.client
    self.status_id = WebRequestStatus::PROCESSED if self.pending? && self.client && !self.client.new?
    self.status_id = WebRequestStatus::ALLOCATED if self.pending? && self.client && self.client.new?
    #puts "BEFORE UPDATE: status_id=#{ @status_id_before_save.inspect } > #{ self.status_id }"
  end
  
  after :update do
    #puts "AFTER UPDATE: status_id=#{ @status_id_before_save.inspect } > #{ self.status_id }, processed?=#{ self.processed? }, imported?=#{ self.imported? }"
    if @status_id_before_save == WebRequestStatus::PENDING && ( self.processed? || self.imported? )
      brochure = self.generate_brochure_request!
    end
  end

  # Web Service API settings:
  @@username			= 'george'
	@@password			= 'george371'
	@@recent_paths	= []          # Useful for noting which Web Service API calls have been made so far.
  @@servers		  = [
    {
      :host => 'http://www.steppestravel.co.uk',
      :path => 'services/DataAccess.asmx/GetForms',
      :username => 'george',
      :password => 'george371',
      :forms => ['Steppes Contact Form', 'Steppes Newsletter Signup', 'Steppes Brochure Request', 'Discovery Contact Form', 'Discovery Newsletter Signup', 'Discovery Brochure Request']
	  },
    {
      :host => 'http://www.the-traveller.co.uk',
      :path => 'Cms/ReportXml',
      :username => 'george',
      :password => 'george371',
      :forms => ['Traveller Enquiry', 'Enquiry']  # The 'Enquiry' form is due to be renamed 'Traveller Enquiry' and can be removed from here.
    }
  ]
  
  # brochure_request (instance variable) is only available immediately after processing a web_request:
  attr_reader :brochure_request
  
  def pending?;   self.status_id == WebRequestStatus::PENDING; end
  def processed?; self.status_id == WebRequestStatus::PROCESSED; end
  def imported?;  self.status_id == WebRequestStatus::ALLOCATED; end
  def rejected?;  self.status_id == WebRequestStatus::REJECTED; end
  
  # Helpers for handling old and new types of request: (Only old requests will have email_text, migrated from old database Sep 2010)
  def legacy?;    !self.email_text.blank?; end
  def raw_text;   !self.email_text.blank? ? self.email_text : self.xml_text; end
  
  def client_name
    return "#{ self.field(:FirstName) } #{ self.field(:Surname) }"
  end
  
  
  # Helper to read meta data from the web service response xml FormEntry nodes:
	# Eg: <ArrayOfFormEntry><FormEntry><ID>123</ID>
	def parse_meta( field_name, xml_node = nil )
		return parse_node( "//FormEntry[ID][Fields]/#{ field_name }']", xml_node )
	end
  
	
  # Helper to read a field value from the web service response xml FormEntry/Fields nodes:
	# Eg: <ArrayOfFormEntry><FormEntry><Fields><FormField><Field>Email</Field><Value>a@b.com</Value>...
  # See views/webs_requests/edit.html.erb for code that uses this to populate client attributes.
	def parse_field( field_name, xml_node = nil )
		return parse_node( "//FormEntry[ID][Fields]/Fields/FormField[Field='#{ field_name }']/Value", xml_node )
	end
  alias field parse_field
  
  
  # Helper to derive properties from the raw xml:
  def set_attributes_from_xml()
    
    if self.xml_text.blank?
      
      return false
      
    else
      
      self.attributes = {
        :origin_web_request_id	=> self.parse_meta(:ID),
        :name										=> self.parse_meta(:Name),
        :requested_date					=> self.parse_meta(:Date),
        :referrer								=> self.parse_meta(:Referrer),
        :keywords								=> self.parse_meta(:Keywords),
        :first_page							=> self.parse_meta(:FirstPage),
        :where_from							=> self.parse_meta(:WhereFrom)
      }
      
      # Attempt to derive the web_request_type_id from the web form name:
      web_request_type = WebRequestType.first( :form_name => self.name )
      self.type_id = web_request_type.id unless web_request_type.nil?
      
    end
    
  end
  
  
  
  # Helper for creating a new web_request object from the xml returned by a web-service:
  def self.first_or_new_from_xml(xml)
    
    # Make a new web_request object and set it's raw xml so other properties can then be derived:
    new_req = WebRequest.new( :xml_text => xml.to_s )
    new_req.set_attributes_from_xml()
    
    old_req = WebRequest.first( :origin_web_request_id => new_req.origin_web_request_id )
    puts "origin_web_request_id #{ new_req.origin_web_request_id }, Old: #{ old_req.id if old_req } #{ old_req.requested_date.to_s if old_req } #{ old_req.name if old_req }, New: #{ new_req.id } #{ new_req.requested_date.to_s } #{ new_req.name }"
    
    return old_req || new_req
    
  end
  
	# Call remote web services to fetch web_requests. Return an array of WebRequest objects:
	# By default all :old web_requests will be filtered out (ie those already in the database).
	# form_name can be :all or one of the names defined in the @@servers array.
	def self.fetch_latest_web_requests( options = {} )
    
    web_requests = []
    
    @@servers.each do |server|
        web_requests.concat self.fetch_latest_web_requests_from_server(server, options)
    end
    
    return web_requests
    
  end
  
  
	# Call remote web services to fetch web_requests from specified server. Return an array of WebRequest objects:
	# By default all :old web_requests will be filtered out (ie those already in the database).
	# form_name can be :all or one of the names defined in the @@servers array.
	def self.fetch_latest_web_requests_from_server( server, options = {} )

    # Details of the web service address:
    # TODO: Move these to app_settings instead of hard coding them?
		host	        = server[:host]
		path	        = server[:path]
    forms         = server[:forms]
    username      = server[:username]
    password      = server[:password]
		limit					= 200
    
    options     ||= {}
		web_requests	= [] # Will be the results
		form_name		  = options[:form_name] || :all
		filter			  = options[:filter]    || :new
		#from_date		= options[:from_date] || WebRequest.max(:requested_date) || 1.month.ago # See below. Now derived on a per-form basis.
		to_date			  = options[:to_date]   || 1.day.from_now

		if form_name == :all

      @@recent_paths = []
      from_date = options[:from_date] || nil
      
      # Call this method recursively for each type of form:
			forms.each do |specific_form|
        opts = options.merge( :form_name => specific_form )
				web_requests.concat( fetch_latest_web_requests_from_server(server,opts) ) unless specific_form == :all  # The unless-condition should help avoid recursive loops of death!
			end
	
		else
			
      #puts server, options.inspect
      form_name ||= forms.first
      from_date = options[:from_date] || 1.month.ago || WebRequest.max(:requested_date, :name => form_name ) || 1.month.ago
      puts "Deriving from_date for #{ form_name }: #{ from_date } = #{ options[:from_date] || 'nil' } || #{ WebRequest.max(:requested_date, :name => form_name ) } || #{ 1.month.ago }"
      
      # Set up the url parameters required by the web service:
      params = {
        :formName => form_name,
        :username => username,
        :password => password,
        :fromDate => from_date.formatted(:date),
        :toDate   => to_date.formatted(:date),
        :type     => 0
      }.to_query


			# Assemble the parts of the web-service url:
      uri           = URI.parse( host / "#{ path }?#{ params }" )
			node_count		= 0

      # Info for debugging:
			@recent_path	= uri
			@@recent_paths << @recent_path
			
			WebRequest.logger.info "Downloading WebRequests #{ Time.now }: '#{ form_name }' from url #{ uri }"
      
		  # Start by calling the web-service:
      begin

			  #response	= Net::HTTP.start(url.host, url.port) {|http| http.get(path) }
        response  = Net::HTTP.get_response(uri)

      # Handle download ERROR:
      rescue Exception => reason

          puts "Error: Could not download web requests. See WebRequests.log"
          WebRequest.logger.error!  "Error: Could not fetch web requests: \n Url: #{ uri } \n Reason: #{ reason }"

      # Otherwise CONTINUE if all is well:
      else

        begin

          # At time or writing, The Traveller data had wrong xml headers, so replace them to be same as Steppes data:
          raw_xml = response.body.sub(
            '<?xml version="1.0" encoding="utf-16"?>',
            '<?xml version="1.0" encoding="utf-8"?>'
          ).sub(
            '<ArrayOfFormEntry>',
            '<ArrayOfFormEntry xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.the-traveller.co.uk/">'
          )
          
			    @xml = REXML::Document.new(raw_xml)

			  rescue Exception => reason

          puts "Error: Could not download web requests. See WebRequests.log"
          WebRequest.logger.error! "Error: Could not parse response.body xml: \n Url: #{ uri } \n Reason: #{ reason } \n Details: #{ response.inspect }"

        else
          
          #puts "Received #{ @xml.elements.each("//FormEntry").length } request in the xml"
          
			    # Create a new web_request object for every <FormEntry> in the xml response:
			    @xml.elements.each("//FormEntry[position() <= #{ limit }]") do |xml|

				    web_requests << WebRequest.first_or_new_from_xml(xml)
				    node_count   += 1

			    end
        
        end

      end

			WebRequest.logger.info! "Downloaded #{ node_count } WebRequests: '#{ form_name }' from url #{ uri }"
		
		  # Discard web_requests that do not match our filter:
		  web_requests.delete_if{|req|  req.new? } if filter == :old
		  web_requests.delete_if{|req| !req.new? } if filter == :new
  		
    puts "Downloaded #{ node_count } Imported #{ web_requests.length } new requests from #{ server.inspect } params: #{ params.inspect }"
			
		end
    
		return web_requests
		
	end



  # Populate database with new web_requests:
  # The options are same as for WebRequest.fetch_latest_web_requests(options)
  def self.import_latest_web_requests( options = {} )
		
    WebRequest.logger.info "WebRequest.import_latest_web_requests(#{ options.inspect })"
    
    new_ones_only = options.merge( :filter => :new )
    
    web_requests = WebRequest.fetch_latest_web_requests( new_ones_only )
    web_requests.each{ |req| req.save if req.new? }

    return web_requests
    
  end




  def self.recent_paths
    return @@recent_paths
  end



  def self.logger
    
    unless defined?(@@webrequests_log)
      @@webrequests_log = Merb::Logger.new File.new( Merb.root / "log" / "webrequests.log", 'a' ), :info
    end
    
    return @@webrequests_log
    
  end	
	
  
  # Helper to build a new brochure request using the details in the current web_request:
  # Note this is only possible since we added a mandatory consultent picklist when processing a web request.
  def generate_brochure_request(notes = nil)
    
    @brochure_request = nil
      
    case
      when !self.valid? then
        WebRequest.logger.error! "Unable to generate brochure_request from web_request #{ self.id } because it is not valid"
      when self.user_id.blank? then
        WebRequest.logger.error! "Unable to generate brochure_request from web_request #{ self.id } because user is blank"
      when self.company_id.blank? then
        WebRequest.logger.error! "Unable to generate brochure_request from web_request #{ self.id } because company is blank"
      when self.client_id.blank? then
        WebRequest.logger.error! "Unable to generate brochure_request from web_request #{ self.id } because client is blank"
      else
        
        @brochure_request = BrochureRequest.new(
          :notes => notes ||= 'Generated automatically when web request was processed',
          :user_id    => self.user_id,
          :client_id  => self.client.id,
          :company_id => self.company.id 
          # :document_template_file is also required but it will assume default for company if we don't set it.
        )

    end
    
    return @brochure_request
    
  end

  # As above but this also saves the generated brochure_request:
  def generate_brochure_request!(notes = nil)
    brochure = self.generate_brochure_request(notes)
    brochure.save unless brochure.nil?
  end

private

  # Generic helper to read a node value from the web service response xml:
	# Eg: <ArrayOfFormEntry><FormEntry><ID>123</ID>...<Fields><FormField><Field>Email</Field><Value>abc</Value>...
	def parse_node( query, xml_node = nil )

    xml_node ||= self.xml_text
    @xml_doc ||= REXML::Document.new(xml_node)
    
		node = @xml_doc.elements[query]
		
		return node ? node.text : ''
		
	end
  

#  # Helper to read a field value from the web service response xml:
#	def parse_field( field_name, from_xml )
#
#    doc = REXML::Document.new(from_xml)
#
#		# Eg: <ArrayOfFormEntry><FormEntry><ID>123</ID>... <Fields><FormField><Field>Email</Field> & <Value>abc</Value>...
#		query = "*/FormEntry[ID='#{ web_request_id }']/Fields/FormField[Field='#{ field_name }']/Value"
#		node  = doc.elements[query]
#		
#		return node ? node.text : nil
#		
#	end
  
end


# WebRequest.auto_migrate!		# Warning: Running this will clear the table!