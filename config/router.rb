# Merb::Router is the request routing mapper for the merb framework.
#
# You can route a specific URL to a controller / action pair:
#
#   match("/contact").
#     to(:controller => "info", :action => "contact")
#
# You can define placeholder parts of the url with the :symbol notation. These
# placeholders will be available in the params hash of your controllers. For example:
#
#   match("/books/:book_id/:action").
#     to(:controller => "books")
#   
# Or, use placeholders in the "to" results for more complicated routing, e.g.:
#
#   match("/admin/:module/:controller/:action/:id").
#     to(:controller => ":module/:controller")
#
# You can specify conditions on the placeholder by passing a hash as the second
# argument of "match"
#
#   match("/registration/:course_name", :course_name => /^[a-z]{3,5}-\d{5}$/).
#     to(:controller => "registration")
#
# You can also use regular expressions, deferred routes, and many other options.
# See merb/specs/merb/router.rb for a fairly complete usage sample.

Merb.logger.info("Compiling routes...")

Merb::Router.prepare do
  resources :task_types
  resources :tasks
  resources :trip_client_statuses
  resources :tours

  resources :postcodes
  resources :money_statuses
  resources :web_request_types
  resources :web_request_statuses
  resources :web_requests
  resources :document_types
  resources :money_outs
  resources :money_ins
  resources :document_template_types
  resources :document_templates
  resources :document_jobs
  resources :titles
  resources :pnrs
  resources :app_settings
  resources :company_countries
  resources :airports
    
  #  authenticate do
  #		  match('/').to(:controller => 'clients', :action => 'index' )
  #	end
  
  # For the dynamically generated trip_elements timeline css:
  # TODO: Find out why merb reports an error during app boot "Could not find resource model TimelineStyle"
  resources :timeline_styles

  resources :notes
  resources :company_suppliers
  resources :addresses
  resources :touchdowns
  resources :country_users
  resources :client_types
  resources :client_sources
  resources :client_interests
  resources :client_marketings
  resources :users

  resources :trips do |trip|
    #trip.resources :elements, :controller => :trip_elements
    trip.resources :trip_elements                              # TODO: Depricate this!
    match('/summary').to(:controller => 'trips', :action => 'summary' )
  end
  
  # /clients/
  resources :clients do |client|
    client.resources :notes
    client.resources :tasks
    client.resources :brochure_requests
    client.resources :documents
    client.resources :addresses
    client.resources :trips do |trip|
      trip.resources :money_ins
      trip.resources :money_outs
      trip.resources :trip_elements
      # match('/summary').to(:controller => 'trips', :action => 'summary')
      # Could not get this to work so used match('/clients/:client_id/trips/:id/summary') instead. See below.
    end
  end
  #match('/clients/:client_id/trips/:trip_id/trip_elements/:id/delete').to(:controller => 'trip_elements', :action => 'destroy' )

  
  # /tours/
  resources :tours do |tour|
    tour.resources :documents         # TODO?
    tour.resources :trips do |trip|
      trip.resources :trip_elements
      trip.resources :money_outs
    end
  end
 

	# Routes for deriving filter options for a report:
	match('/reports/filters').to( :controller => 'reports', :action => 'filters' )
  resources :reports
  

	# Routes for fetching list of <option> items:
	match('/airports/list').to( :controller => 'airports', :action => 'index', :list => :option )

	match('/suppliers/list').to( :controller => 'suppliers', :action => 'index', :list => :option )
	match('/shared/list').to( :controller => 'shared', :action => 'list', :list => :option )

  # Routes for Brochure Merge and Clear Merge:
  match('/brochure_requests/merge').to( :controller => 'brochure_requests', :action => 'merge' )
  resources :brochure_requests
  
  match('/documents/download').to( :controller => 'documents', :action => 'download' )
  resources :documents
  
  #match('/images/:action/:id' ).to( :controller => 'images', :action => :action, :id => id )

  resources :photos
  resources :image_files
  resources :images
  resources :articles
  resources :exchange_rates
  resources :companies
  resources :excursions
  resources :suppliers
  resources :trip_clients
  resources :trip_countries
  resources :trip_elements
  #resources :elements, :controller => :trip_elements
  resources :trip_types
  resources :trip_packages
  resources :trip_element_excursions
  resources :trip_element_misc_types
  resources :trip_element_types
  resources :mailing_zones
  resources :countries do
    resources :photos
  end
  resources :world_regions

  # RESTful routes
  # resources :posts



  match('/').to(:controller => 'clients', :action => 'index' )

  # Client search:
  match('/search').to(:controller => 'clients', :action => 'search' )
  match('/clients/:id/summary'    ).to(:controller => 'clients',   :action => 'summary' )
  match('/clients/:id/select'     ).to(:controller => 'clients',   :action => 'select_tab' )
  match('/clients/:id/close'      ).to(:controller => 'clients',   :action => 'close_tab' )
  match('/clients/:client_id/documents'  ).to(:controller => 'documents', :action => 'index' )	# action expects client_id in params.
  
  # Route for CLIENT TRIP summary and builder etc: (Could not get nested route to work. See above!)
  match('/clients/:client_id/trips/:id/summary').to(:controller => 'trips', :action => 'summary' )
  match('/clients/:client_id/trips/:id/builder').to(:controller => 'trips', :action => 'builder' )
  match('/clients/:client_id/trips/:id/itinerary').to(:controller => 'trips', :action => 'itinerary' )
  match('/clients/:client_id/trips/:id/costings').to(:controller => 'trips', :action => 'costings' )
  match('/clients/:client_id/trips/:id/documents').to(:controller => 'trips', :action => 'documents' )
  match('/clients/:client_id/trips/:id/accounting').to(:controller => 'trips', :action => 'accounting' )
  match('/clients/:client_id/trips/:id/copy').to(:controller => 'trips', :action => 'copy' )
  
  # Route for TOUR TRIP summary and builder etc: (Could not get nested route to work. See above!)
  match('/tours/:tour_id/trips/:id/summary').to(:controller => 'trips', :action => 'summary' )
  match('/tours/:tour_id/trips/:id/builder').to(:controller => 'trips', :action => 'builder' )
  match('/tours/:tour_id/trips/:id/itinerary').to(:controller => 'trips', :action => 'itinerary' )
  match('/tours/:tour_id/trips/:id/costings').to(:controller => 'trips', :action => 'costings' )
  match('/tours/:tour_id/trips/:id/documents').to(:controller => 'trips', :action => 'documents' )
  match('/tours/:tour_id/trips/:id/accounting').to(:controller => 'trips', :action => 'accounting' )
  match('/tours/:tour_id/trips/:id/copy').to(:controller => 'trips', :action => 'copy' )
  
  # Articles for a Country:
  match('/countries/:country_id/articles/:id/edit').to(:controller => 'articles', :action => 'edit' )
  match('/countries/:country_id/articles/new').to( :controller => 'articles', :action => 'new' )

  # List Image files or folders:
  match('/photos/test/').to(:controller => 'photos', :action => 'test' )
  match('/photos/folders/').to(:controller => 'photos', :action => 'folders' )


	# Eg: Bookeing ref: /2138578920/SE/94155
	#match('/:client_id/:company_code/:trip_id').to(:controller => 'clients', :action => 'index' )
	match('/:client_id/:company_code/:trip_id').redirect( '/clients' )
		

  #match('/imageLibrary').to( :url => 'smb://selfs01/images/Discovery/_Photos\NEPAL' )

  # Generate image thumbails on the fly:
  #match('*.jpg?thumb').to(:controller => 'thumbnails', :action => 'show', :imagePath => ??? )

    # Adds the required routes for merb-auth using the password slice
  slice(:merb_auth_slice_password, :name_prefix => nil, :path_prefix => "")

  # This is the default route for /:controller/:action/:id
  # This is fine for most cases.  If you're heavily using resource-based
  # routes, you may want to comment/remove this line to prevent
  # clients from calling your create or destroy actions with a GET
  default_routes

  # Home page:
  #match('/').to(:controller => 'users', :action =>'index')

end