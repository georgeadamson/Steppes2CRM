// Common JavaScript code applies across all pages

// Tabs:
// Level 1 tags are those accross the top of the page.
// Level 2 tabs are those down the left hand side (LHS).
// Level 3 tabs are those separating the facets of a trip.

// Note: The check for FIREFOX happens in the parent html page. (So it can run even when this script is not compatible with browser)

// Prevent debug messages from balking when firebug not installed:
if( !window.console ){ var console = {} }
if( !console.log    ){ console.log = function(){} };


(function($){

	// Define the jQuery delay() method if not present in this version of jQuery: http://api.jquery.com/delay
	if( !$.fn.delay ){

		$.fn.delay = function(time, type){
			time = $.fx && $.fx.speeds && $.fx.speeds[time] || parseInt(time) || 600;
			type = type || "fx";
			return this.queue(type, function() {
				var elem = this;
				setTimeout(function(){ $.dequeue( elem, type ) }, time);
			});
		};

	}

})(jQuery);



jQuery(function($) {

	// Javascript is running so enable alternative styles:
	$('BODY').removeClass('nojs').addClass('js');


	var guid = 0,											// Used by the jQuery.fn.id() method.
		undefined,											// Speeds up test for undefined variables.
		spinnerTimeoutId,									// Timeout that will hide the ajax spinner image.
		messageTimeoutID,									// Timeout that will hide the server-response messages.

		// These IDs must match those in the database: 		// TODO: Find a data-driven way of settings these!
		UK_COUNTRY_ID					= 6,
		FIXED_DEPARTURE					= 4,
		DOCUMENT_TYPE_ID_FOR_LETTERS	= 8,
		TASK_STATUS_OPEN				= 0,
		LOOKUP_TRIP_ELEMENT_TYPE		= { 1:'flight', 2:'flightagent', 4:'accomm', 5:'ground', 8:'misc' },

		// Text for labelling and identifying special tabs:
		SYSTEM_ADMIN_LABEL				= 'System admin',
		WEB_REQUESTS_ADMIN_LABEL		= 'Web requests',
		BROCHURE_REQUESTS_ADMIN_LABEL	= 'Brochure merge',
		REPORTS_PAGE_LABEL				= 'Reports',
		DOWNLOADABLE_EXT				= { doc:true, pdf:true, xls:true, csv:true },
		ELEMENT_URL_ATTR				= 'data-ajax-url',

		// Global ajax timeout:
		AJAX_TIMEOUT					= 60000,			// Milliseconds.

		// Settings for client-search:
		CLIENT_SEARCH_MAX_ROWS			= 20,				// Will be sent as &limit=n parameter when searching for clients via ajax.
		CLIENT_SEARCH_DELAY_BEFORE_AJAX	= 500,				// Milliseconds delay before searching for the keywords being typed in client search box.

		// Settings for postcode-lookup:
		POSTCODE_LOOKUP_MAX_ROWS			= 20,			// Will be sent as &limit=n url parameter when searching for postcodes via ajax.
		POSTCODE_LOOKUP_DELAY_BEFORE_AJAX	= 200,			// Slight delay before searching for the keywords being typed in postcode search box.
		POSTCODE_LOOKUP_MIN_CHARS			= 5,			// The longer this is the faster the search is likely to be. (Shortest postcode in DB is 6 chars)

		// Delay before generating the overview just below the timeline when the Trip Builder tab is opened:
		TIMELINE_DELAY_BEFORE_GENERATE_OVERVIEW	= 2000,

		// Regexes for parsing content from ajax html responses:
		FIND_DATA_CONTENT				= /<!--<DATA>-->([\s\S]*)<!--<\/DATA>-->/,
		FIND_MESSAGE_CONTENT			= /<!--<MESSAGES>-->([\s\S]*)<!--<\/MESSAGES>-->/,

		// Test for "Access to restricted URI denied" (NS_ERROR_DOM_BAD_URI) in error text: (Only Mozilla raises the error. Opera and Chrome just ignore restricted link completely)
		IS_BROWSER_DOC_LINK_SECURITY_ERROR	= /NS_ERROR_DOM_BAD_URI/,

		// Horizontal line displayed in some javascript alert() boxes etc:
		MESSAGE_BOX_HR					= new Array(81).join('_'),

		// Settings for displaying notices and error messages:
		DELAY_BEFORE_MESSAGE_SHOW		= 1000,				// Wait before showing messages from server.
		DELAY_BEFORE_MESSAGE_HIDE		= 3000,				// Wait before hiding messages from server, after showing them.
		DURATION_OF_MESSAGE_SHOW		= 250,				// Animation speed when showing messages.
		DURATION_OF_MESSAGE_HIDE		= 2000,				// Animation speed when hiding messages.

		$messages						= $('H2.noticeMessage, H2.errorMessage, H2.warningMessage'),	// See showMessage() function.

		// Constants to help make code more readable: ( Eg: if( event.button == BUTTON.LEFT )... )
		BUTTON							= { LEFT:0, MIDDLE:1, RIGHT:2 },
		COMMA							= ",",
		KEY								= {
			digits			: /[0-9]|[\x60-\x69]/,						// Allows for number-pad digits too.
			integer			: /[0-9]|[\x60-\x69]|[\x6D]/,				// Same as digits but allow minus (-) too.
			'decimal'		: /[0-9]|[\x60-\x69]|[\x6D]|[\xBE\x6E]/,	// Same as digits but allow minus (-) and dot (.) too.
			dot				: /[\xBE\x6E]/,								// Allows for number-pad dot too (AKA period, full-stop).
			comma			: 188,
			minus			: 109,
			tab				: 9,
			enter			: 13,
			backspace		: 8,
			'delete'		: /[\x2E\x90]/,								// Allows for number-pad delete too.
			pageUpDown		: /[\x21-\x22]/,
			pageUp			: 33,
			pageDown		: 34,
			arrows			: /[\x25-\x28]/,							// Arrow keys.
			arrowLeft		: 37,
			arrowUp			: 38,
			arrowRight		: 39,
			arrowDown		: 40,
			end				: 35,
			home			: 36,
			homeEnd			: /[\x23-\x24]/,
			navigation		: /[\x25-\x28]|[\x21-\x22]|[\x23-\x24]/,	// Arrows or PageUp/Down or Home/End
			fkeys			: /[\x70-\x7C]/								// Function keys F1-F13
		};



	// Alias to workaround a typo in callout plugin where it tries to call "corners" plugin instead of "corner":
	$.fn.corners = $.fn.corner;




// ***** Experimental event-driven code. Work in progress, being introduced gradually:
// ***** For more info, google for "building evented single page applications".

	var Layout = {

		// Experimental new router matching syntax: (To replace livePath & eventually liveForm)
		// Eg: Layout.match(/clients\/new/).on('success').to(Client.openNew)
		match : function(path){

			var undefined,
				methods = { on: status, to: callback }, 
				route   = $.isPlainObject(path) ? path : { path:path, status:undefined, callback:undefined };

			// Return the methods hash to begin chaining:
			return bindRoute();

			// Handler for the 'on' method:
			function status(arg){
				return bindRoute({ status:arg });
			}

			// Handler for the 'to' method:
			function callback(arg){
				return bindRoute({ callback:arg });
			}

			// Helper to initialise the route listener if we have all the route settings we need:
			function bindRoute(args){

				// Merge the next route configuration argument to build up our route hash:
				$.extend( route, args );

				if( route.callback && route.status && route.path ){
					Layout.livePath( route.status, route.path, route.callback );
				}

				// Return the methods hash to maintain chaining:
				return methods;

			}

		},


		init	: function(){

			// Bind custom 'hashchange' event:
			$(document).bind('hashchange', Layout.reload);

			Layout.initLinksHandler();
			Layout.initFormsHandler();

			// Top tip: Be wary of false positives, eg: 'clients/trips/trip_elements' would also trigger /clients\/trips/
			// Regex preference? Is this syntax clearer? Using RegExp avoids the need to explicitly escape the slashes in the url.
			// TODO: Refactor liveForm to alternate syntax: Layout.liveForm('update:success', 'clients', Client.initForm ) & maybe combine with livePath()
			//       Or like a resource:	Layout.match(/clients\/new/).on('success').to(Client.openNew)

			// Layout.match(':destroy').on('click').to( function(){alert('are you sure?!')} );
			Layout.liveForm('submit', 'clients:destroy',	function(){alert('are you sure?!')} );

			// Clients:
			Layout.livePath('click',   new RegExp('clients/new'),						Client.openNew );
			Layout.livePath('success', new RegExp('clients/new'),						Client.initForm );
			Layout.livePath('success', new RegExp('clients/([0-9]+)$'),					Client.initShow );
			Layout.livePath('success', new RegExp('clients/([0-9]+)/edit'),				Client.initForm );
			Layout.livePath('success', new RegExp('clients/([0-9]+)/summary'),			Client.initForm, BoundFields.update );
			Layout.livePath('success', new RegExp('clients/([0-9]+)/trips$'),			Client.initForm );	// When user clicks to see all trips on client summary page.
			Layout.livePath('success', /[\?\&]open_client_id=([0-9]+)/,					Client.openShow );	// Eg: web_requests?open_client_id=2138587702
			Layout.liveForm('success', 'clients:create',								Client.openShow );	// After creating a new client.
			Layout.liveForm('success', 'clients:update',								Client.initForm, BoundFields.update );
			Layout.liveForm('success', 'clients:destroy',								Client.initForm, BoundFields.update );

			// Tours: (aka Groups)
			Layout.livePath('success', /tours$/,										Tour.openIndex );	//open tours index
			Layout.livePath('click',   /tours\/([0-9]+)$/,								Tour.openShow );	//openTourTab
			Layout.livePath('success', /tours\/([0-9]+)$/,								Tour.initShow );
			Layout.livePath('success', /tours\/([0-9]+)\/trips\/([0-9]+)$/,				Trip.initShow );
			Layout.livePath('success', /tours\/([0-9]+)\/trips\/new/,					Trip.initForm );
			Layout.livePath('success', /tours\/([0-9]+)\/trips\/([0-9]+)\/edit/,		Trip.initForm );
			Layout.liveForm('success', 'tours:create',									Tour.closeNew, Tour.onCreateSuccess );
			Layout.liveForm('success', 'tours:update',									Tour.onCreateSuccess );
			Layout.liveForm('success', 'tours:destroy',									Tour.closeShow, Tour.openIndex );

			// Trips:
			$("A[href $= '#costing_copy_gross']").live('click', Trip.copyGrossPrice);										// Handle 'Set gross' helper button on Costings Sheet.
			// The following have been refactored to use the new Layout.match syntax below!
			//Layout.livePath('click',   /clients\/([0-9]+)\/trips\/new\?.*version_of_trip_id=([0-9]+)/,	Trip.openShow );	// Create new version.
			//Layout.livePath('success', /clients\/([0-9]+)\/trips\/new\?.*version_of_trip_id=([0-9]+)/,	Trip.initShow );	// Created new version.
			//Layout.livePath('success', /clients\/([0-9]+)\/trips\/new/,									Trip.initForm );
			//Layout.livePath('success', /clients\/([0-9]+)\/trips\/([0-9]+)$/,								Trip.initShow );
			//Layout.livePath('success', /clients\/([0-9]+)\/trips\/([0-9]+)\/edit/,						Trip.initForm );
			//Layout.livePath('success', /clients\/([0-9]+)\/trips\/([0-9]+)\/builder/,						Trip.initTimeline );
			//Layout.livePath('click',   /clients\/([0-9]+)\/trips\/([0-9]+)\/copy/,						Trip.showSearch );
			//Layout.livePath('success', /clients\/([0-9]+)\/trips\/([0-9]+)\/copy.*search/,				Trip.showSearchResults );
			Layout.liveForm('success', 'trips:create',													Trip.onCreateSuccess );
			Layout.liveForm('success', 'trips:update',													Trip.onUpdateSuccess );
			Layout.liveForm('success', 'trips:destroy',													Trip.onDestroySuccess );
			
			// The following are refactored alternatives to the original livePath definitions above:
			Layout.match(/clients\/([0-9]+)\/trips\/new\?.*version_of_trip_id=([0-9]+)/)	.on('click'  ).to(Trip.openShow);
			Layout.match(/clients\/([0-9]+)\/trips\/new\?.*version_of_trip_id=([0-9]+)/)	.on('success').to(Trip.initShow);
			Layout.match(/clients\/([0-9]+)\/trips\/new/)									.on('success').to(Trip.initForm);
			Layout.match(/clients\/([0-9]+)\/trips\/([0-9]+)$/)								.on('success').to(Trip.initShow);
			Layout.match(/clients\/([0-9]+)\/trips\/([0-9]+)\/edit/)						.on('success').to(Trip.initForm);
			Layout.match(/clients\/([0-9]+)\/trips\/([0-9]+)\/builder/)						.on('success').to(Trip.initTimeline);
			Layout.match(/clients\/([0-9]+)\/trips\/([0-9]+)\/copy/)						.on('click'  ).to(Trip.showSearch);
			Layout.match(/clients\/([0-9]+)\/trips\/([0-9]+)\/copy.*search/)				.on('success').to(Trip.showSearchResults);

			// TripElements:
			Layout.livePath('click',   new RegExp('trips/([0-9]+)/trip_elements/grid'),				TripElement.openGrid );
			Layout.livePath('click',   new RegExp('trips/([0-9]+)/trip_elements/new'),				TripElement.hideForm );
			Layout.livePath('click',   new RegExp('trips/([0-9]+)/trip_elements/([0-9]+)/edit'),	TripElement.hideForm );
			Layout.livePath('success', new RegExp('trips/([0-9]+)/trip_elements/([0-9]+)/edit'),	TripElement.showForm, TripElement.initForm );
			Layout.livePath('success', new RegExp('trips/([0-9]+)/trip_elements/grid'),				TripElement.initGrid );
			Layout.livePath('success', new RegExp('trips/([0-9]+)/trip_elements/new'),				TripElement.showForm, TripElement.initForm );
			Layout.liveForm('success', 'trip_elements:create',										TripElement.initForm, Trip.initTimeline );
			Layout.liveForm('success', 'trip_elements:update',										TripElement.initForm, Trip.initTimeline );
			Layout.liveForm('success', 'trip_elements:destroy',										Trip.initTimeline );

			// MoneyIn (Invoice)
			Layout.livePath('success', new RegExp('money_ins/new'),									MoneyIn.initForm );
			Layout.liveForm('success', 'money_ins:create',											MoneyIn.initForm, BoundFields.update );
			Layout.liveForm('success', 'money_ins:update',											MoneyIn.initForm, BoundFields.update );

			// Reports:
			Layout.livePath('success', new RegExp('reports$'),							Report.initForm );
			Layout.livePath('success', new RegExp('reports/new'),						Report.initForm );
			Layout.livePath('success', new RegExp('reports/([0-9]+)/edit'),				Report.initForm );
			Layout.livePath('success', new RegExp('reports/([0-9]+)/delete'),			Report.initForm );
			Layout.liveForm('success', 'reports:create',								Report.initForm );
			Layout.liveForm('success', 'reports:update',								Report.initForm );

			// WebRequests:
			//Layout.livePath('click', new RegExp('web_requests/([0-9]+)\\?raw'),			WebRequest.openShow );
			Layout.livePath('click', new RegExp('web_requests/([0-9]+)(\\?.*)?$'),			WebRequest.openShow );
			Layout.liveForm('success', 'web_requests:update',							Client.openShow ); // TODO!

			// SysAdmin:
			Layout.livePath('success', new RegExp('/system$'),							SysAdmin.initShow );
			Layout.match(/exchange_rates/)												.on('success').to(initSpinboxes);
			Layout.match(/companies\/([0-9]+)\/edit/)									.on('success').to(initSpinboxes);
			Layout.match(/^\/?(.*)\/?\?.*index_filter=(.+)/)							.on('success').to(SysAdmin.refreshIndex);

			// Tasks: (AKA Followups / Reminders)
			Layout.livePath('click',	new RegExp('/tasks/([0-9]+)/edit'),				Task.openEdit );
			Layout.livePath('click',    new RegExp('/tasks/new'),						Task.openNew );
			Layout.livePath('success',	new RegExp('/tasks/([0-9]+)/edit'),				Task.initForm, initDatepickers );
			Layout.livePath('success',  new RegExp('/tasks/new'),						Task.initForm, initDatepickers );
			Layout.livePath('success',  new RegExp('/tasks/?$'),						Task.initIndex );	// Refresh list of tasks.
			Layout.liveForm('success',  'tasks:create',									Task.onCreateSuccess );
			Layout.liveForm('success',  'tasks:update',									Task.onCreateSuccess );

			// AutoText:
			Layout.livePath('success', /\/countries\?autotext/,							Autotext.showCountries );	// Eg: '/countries?autotext&company_id={value}&list=option'
			Layout.livePath('success', /\/autotexts\?autotext/,							Autotext.showAutotexts );	// Eg: '/autotexts?autotext&country_id={value}&list=option'

			// Documents:
			Layout.match(/clients\/([0-9]+)\/documents.*list=option/).on('success').to(Document.list);	// For listing template filenames


			// Depricated in favour of Layout.liveForm:
			//$('FORM.edit-client').live('form:success', Client.onEditSuccess)
			//$('FORM.create-tour').live('form:success', Tour.onCreateSuccess)

		},

		// Trigger ajax and handlers for the specified path:
		// Note: When triggered by tabs, the options will be a tabs.ui hash.
		load	: function(path, options){

			if(path){

				path    = path.replace(/^#/, '');
				options = options || {};

				// Notify url-specific event handlers:
				console.log( 'path:loading...', path );
				$(document).trigger('path:loading', [path]);
				$(document).trigger('path:loading:' + path);

				// Do ajax call: (unless options.ui.tab)
				if( path && !( options.tab || options.ui && options.ui.tab ) ){

					Layout.xhr = $.ajax({
					
						url		: path,
						cache	: false,
						dataType: options.dataType || 'html',
						
						success: function(data, status, xhr){

							if ( Layout.getMessagesFrom(data).is('.errorMessage') ) {

								// For the benefit of the error handler, ensure the xhr.responseText still contains the response:
								if( !xhr.responseText && data ){ xhr.responseText = data }
								$(document).trigger('path:error', [xhr, status, 'custom']);

							} else {
								
								Layout.onSuccess(data, status, xhr, options);
								$(document).trigger('path:success', [data, status, xhr]);

							}

						},

						error: function(xhr, status, error) {console.log(xhr, status, error);alert(status)
							$(document).trigger('path:error', [xhr, status, error]);
						},

						complete: function(xhr, status) {
						  $(document).trigger('path:complete', [xhr, status]);
						}
					
					});

				}

			}

		},

		// Trigger for loading the url stored in the current hash:
		reload	: function(e,options){
			Layout.load(window.location.hash, options);
		},

		// Helper for registering the many url-specific live event handlers:
		livePath: function(type, path, callback) {

			// Handle multiple callbacks by creating a function to run each in turn:
			callback = Layout.wrapCallbacks( Array.prototype.slice.call(arguments,2) );

			if( typeof(path) === 'string' ){
				$(document).bind('path:' + type + ':' + path, callback);
			}else{
				Layout.livePathPattern[type].push([path, callback]);
			}

		},

		// Helper for registering the many form-specific live event handlers:
		// Expects controller_action formatted like "clients:create".
		liveForm: function(type, action, callback){

			// Handle multiple callbacks by creating a function to run each in turn:
			callback = Layout.wrapCallbacks( Array.prototype.slice.call(arguments,2) );

			Layout.liveFormPattern[type].push([action, callback]);

		},

		// Collection of regexes or patterns for parsing and triggering url-specific event handlers: (Populated by calls to Layout.livePath)
		livePathPattern : { loading:[], success:[], click:[] },
		liveFormPattern : { loading:[], success:[], submit:[] },

		// Generic handler for all successful ajax calls:
		onSuccess: function(data,status,xhr,options,e){

			// Actual order of arguments will vary depending on how this was called!
			// When called by a uiTabs event, the xhr argument will be undefined, options will be a ui object.
			var ui = options = ( options || xhr );
			if( xhr && xhr !== options ){ options.xhr = xhr };
			if( ui.tab && !ui.url ){ ui.url = $.data(ui.tab,'load.tabs'); }	// Derive url from ui.tab when apprioriate.
			var path = options.url;
			options.event = e;
			console.log('onSuccess', path);

			// Load the response into the target element unless options.success() callback explicitly prevents it:
			// TODO: When would options.success ever be specified?
			//if( !options.success || options.success() !== false ){
				if( options.target && /^#/.test(options.target) ){
					$(options.target).html(data)
					.find('A,SELECT,INPUT,TEXTAREA').filter(':visible:first').focus();
				}
			//}

			// Display any error/notice messages found in the response:
			//showMessage( Layout.getMessagesFrom( xhr.responseText || data ) );

			// Update the location hash and trigger matching livePath handlers: (but do not trigger the hashchange event)
			if(path){
				Layout.setHash( path, options, false );
				Layout.triggerLivePath( 'success', path, options, data );
			}				

		},

		// Helper for triggering all the livePath handlers that match path: (type expects 'success' or 'error')
		triggerLivePath : function(type, path, options, data){

			options.data  = options.data || data;

			$.each( Layout.livePathPattern[type], function(i,handler){

				var regex = handler[0], callback = handler[1], m = path.match(regex);

				// Trigger the callback passing a pimped-up copy of the options hash or tabs ui object:
				if( m && $.isFunction(callback) ){
					var args = $.extend( {}, options, { type:type, matches:m, pattern:regex } );
					console.log('Triggering livePath:', type, args, path, regex, callback );
					callback(args);
				}

			});

		},

		// Helper for triggering all the liveForm handlers that match the form.controller and form.action:
		triggerLiveForm : function(type, form, options, data, e){

			$.each( Layout.liveFormPattern[type], function(i,handler){

				var pattern = handler[0], callback = handler[1], p = pattern.split(':'), controller = p[0], action = p[1];

				// Trigger the callback passing a pimped-up copy of the options hash:
				if( form.controller == controller && form.action == action && $.isFunction(callback) ){
					console.log('Triggering liveForm:', type, form.path, pattern, callback, 'with options:', options );
					var args = $.extend( {}, options, { form:form, pattern:pattern, data:data, type:type, event:e } );
					callback(args);
				}

			});

		},


		// Initialise LINK CLICK handlers:
		initLinksHandler : function(){

			// Initialise handler for auto-linking picklists:
			$('SELECT[data-href], SELECT:has(OPTION[data-href]:selected), SELECT[href]').live('change keydown', function(e){										// Note: "href" is depricated.

				// Ignore ALL key strokes except <Enter> key: (to select an item in the list)
				if( e.type == 'keydown' && e.keyCode != KEY.enter ){ return }

				// Ignore event if the list is expected to submit it's value using form post:
				if( $(this).is('SELECT[data-method]') ){ return }	// See initFormsHandler instead.

				var $list  = $(this), $item = $list.find('OPTION:selected'),
				    target = Layout.getTargetOf($list),
					href   = $item.attr('data-href') || $list.attr('data-href') || $list.attr('href') || $list.val();	// Note: "href" is depricated.
					href   = href.replace( '{value}', $item.val() ).replace( '{text}', $item.text() );

				// TODO: Trigger the handler directly on the list instead of this dodgy on-the-fly element:
				$('<a>').attr({ href: href, 'data-target': target }).trigger('click',this);

			});

			// Trigger custom 'hashchange' event whenever a link is clicked:
			$('A:not( .noajax, .scrollTo, [href ^= mailto] )').live('click', function(e, source){

				var $link	= $(this),	// TODO: $link = $(source || this) to handle auto-linking lists.
				    path	= $link.attr('href').replace(/^#\/?/,''),
				    ext		= path.split('.')[1],	// Filename extension
				    target	= Layout.getTargetOf($link),
				    options	= { url:path, target:target, event:e },
				    triggerHashChange = true;

				// Bail out now if we've accidentally intercepted a click on a tab etc:
				// If FILE DOWNLOAD, skip the clever stuff and let the browser do it's thing:
				if( $link.parents('UL').is('.ui-tabs-nav, .ui-datepicker') ){ return }
				if( DOWNLOADABLE_EXT[ext] || $link.is('.download') || $(this).is('.ajaxDownload') ){ return }
				if( $link.is("[class *= 'datepicker']") ||  $link.parent().is("[class *= 'datepicker']") ){ return }

				// Derive a {resource}_id property for each resource in the path: (Eg: "clients/1/trips/2" => {client_id:1, trip_id:2}
				$.extend( options, Layout.getResourceIDsFrom(path) );

				// Trigger generic CLICK handlers:
				Layout.triggerLivePath('click', path, options, '');
				Layout.setHash( path, options, !e.isImmediatePropagationStopped() );	// Allow for e.stopImmediatePropagation()
				e.preventDefault();

			});

		},


		// Initialise FORM SUBMIT handlers:
		initFormsHandler : function(){

			// Initialise handler for auto-submitting PICKLISTS:
			$('SELECT.auto-submit, :checkbox.auto-submit, FORM.auto-submit SELECT, FORM.auto-submit :checkbox').live('change keydown', function(e){

				// Ignore ALL key strokes except <Enter> key: (to select an item in the list)
				if( e.type == 'keydown' && e.keyCode != KEY.enter ){ return }
				$(this).closest('FORM').trigger('submit',this);

			})

			// Initialise handler for auto-linking PICKLISTS that need to be posted like a form:
			$('SELECT[data-method]').live('change keydown', function(e){

				// Ignore ALL key strokes except <Enter> key: (to select an item in the list)
				if( e.type == 'keydown' && e.keyCode != KEY.enter ){ return }

				// Bail out if selected list item has no value: (It's probably just a prompt)
				if( !$(this).val() ){ return }

				var $list  = $(this), $item = $list.find('OPTION:selected'),
					method = $list.attr('data-method'),													// POST, GET, PUT or DELETE
				    target = Layout.getTargetOf($list),
					href   = $item.attr('data-href') || $list.attr('data-href') || $list.val();			// Read custom url from item or list element.
					href   = href.replace( '{value}', $item.val() ).replace( '{text}', $item.text() ),	// Interpolate {placeholders} with values.
					http_method = {'post':'post','get':'get'}[method.toLowerCase()] || 'post',			// Ensure we use an http-friendly method.
					rest_method = $('<input type="text" name="_method"/>').val(method);					// Allow for get|post|put|delete.

				// TODO: Trigger the handler directly on the list instead of this dodgy on-the-fly element:
				$('<form>').attr({ action:href, method:http_method, 'data-target':target })
					.append(rest_method)
					.trigger('submit',this);

			})

			// Initialise common FORM handler:
			$('FORM:not(.noajax)').live('submit', function(e, source){

				// The source argument will only be present when triggered by SELECT.auto-submit:
				var $form		= $(this),
					$button		= $(source || e.originalEvent && e.originalEvent.explicitOriginalTarget);

					// When a <label> is clicked, explicitOriginalTarget will be the text node within the label:
					if( $button.parent().is('LABEL') ){
						$button = $button.parent()
					}

					// When a <label> is clicked, derive the actual submit button from the "for" attribute:
					if( $button.is('LABEL') && $button.is('[for]') ){
						var buttonID = $button.attr('for');
						$button = $( '#' + buttonID );
					}

				var	url			= $form.attr('action').replace(/^#/, ''),
					dataType	= $form.attr('data-type')   || 'html',
					target		= $form.attr('data-target') || Layout.getTargetOf($button),
					ext			= url.split('.')[1],	// Filename extension				
					form		= Layout.getActionOf($form),
					options		= { url:url, target:target, form:form },
					buttonData	= {},
					promptToConfirm	    = $button.attr('data-confirm');

					options.form.target = target;
					options.form.button = $button.id();

				//if( $button.parent().is('LABEL') )

				// When using a live event the ajaxSubmit() method will not include name/value of the submit button so add it:
				if( $button.is(':submit') && $button.attr('name') ){ buttonData[ $button.attr('name') ] = $button.val() }
				
				// Stop interfering right now if form is generating a file to download:
				if( DOWNLOADABLE_EXT[ext] || $button.is('.download, .ajaxDownload') || $form.is('.download, .ajaxDownload') ){ return }


				if( !promptToConfirm || confirm(promptToConfirm) ){

					// By setting up the AJAX SUBMIT here, each of the callbacks can refer to the $form using a closure:
					$form.ajaxSubmit({

						url       : url,
						dataType  : dataType,
						data      : $.extend( {}, form.params, buttonData ),	// Also submit url params as fields.

						beforeSubmit: function(data, form, options){
							$form.trigger('form:beforeSubmit', [data, form, options]);
						},

						beforeSend: function(xhr){
							$form.trigger('form:beforeSend', [xhr]);
						},

						success: function(data, status, xhr){

							// For the benefit of the error handler, ensure the xhr.responseText still contains the response:
							if( !xhr.responseText && data ){ xhr.responseText = data }

							// After creating a new object we may be able to read it's new id from the response: (Eg: form.trip_id = 123)
							var resource = options.form && options.form.resource, attr = resource+'_id';
							if( resource && !options.form[attr] ){ options.form[attr] = $(data).find('#'+attr).val(); options.form.resource_id = options.form[attr] }

							if ( Layout.getMessagesFrom(data).is('.errorMessage') ) {
								$form.trigger('form:error', [xhr, status, 'custom']);
							} else {
								Layout.onSuccess(data, status, xhr, options, e);
								Layout.triggerLiveForm('success', options.form, options, data, e);
								$form.trigger('form:success', [data, status, xhr]);
							}

						},

						error: function(xhr, status, error) {
							$form.trigger('form:error', [xhr, status, error]);
						},

						complete: function(xhr, status) {
						  $form.trigger('form:complete', [xhr, status]);
						}

					});

				}

				e.preventDefault();

			})

			// Bind generic FORM SUCCESS handler:
			.live('form:success', function(e, data, status, xhr) {
				// Unused.
			})

			// Bind generic FORM ERROR handler:
			.live('form:error', function(e, xhr, status, error) {
				// Unused.
			})

			// Bind generic FORM COMPLETE handler:
			.live('form:complete', function(e, xhr, status) {

				// Display any error/notice messages found in the response:
				showMessage( Layout.getMessagesFrom(xhr.responseText) );

			});

		},

		// Read the current hash href:
		getHash: function() {
			return window.location.hash;
		},

		// Set the current location hash and optionally trigger hashchange event:
		setHash: function(hash,options,triggerHashChange) {
			window.location.hash = window.currentHash = '#' + hash.replace(/^#\/?/,'');
			console.log('setHash', window.location.hash);
			if( triggerHashChange !== false ){ $(document).trigger('hashchange',[options]) }
		},


		// Parse error & notice message elements from the xhr response:
		// Test for messages in data eg: <!--<MESSAGES>--><h2 class="errorMessage">Oops, something odd happened. <br/> <div class='error'>The trip details could not be saved because:<ul><li>TripElement: (Flight) The Flight agent cannot be left blank</li></ul></div></h2><!--</MESSAGES>-->
		getMessagesFrom: function(data){
			try{
				if( typeof(data) !== 'string' ){ data = $(data).html() }
				var fragment = ( FIND_MESSAGE_CONTENT.exec(data) || [] )[1] || '';
				return $('<div>').html(fragment).find(".noticeMessage,.errorMessage");
			}catch(e){
				return $([]);
			}
		},


		// Prepare multiple callbacks by creating an anonymous function to run each in turn:
		// Important: This returns one function that accepts arguments and passes them to each callback function.
		wrapCallbacks : function( callbacks, always ){

			// Ensure we really are dealing with an array of functions: (Saves time later)
			callbacks = $.grep( $.makeArray(callbacks), function(fn){ return $.isFunction(fn) } );

			if( callbacks.length > 1 || always ){
				return function(args){
					var self = this; args = Array.prototype.slice.call(arguments);
					$.each(callbacks, function(i,fn){ fn.apply(self,args) });
				}
			}else{
				return callbacks[0];
			}

		},


		// Helper for deriving the ui-target element of a link or button etc:
		getTargetOf : function(elem){

			// Allow for when a label is clicked to trigger a submit: (Allow for label or a text node inside label)
			var id, $elem = $(elem), label_for = $elem.parent('LABEL').andSelf().attr('for');
			if( label_for ){ $elem = $( '#' + label_for ) }
			
			var $form  = $elem.closest('FORM');

			// Do our best to read the custom target from the element or the form:
			var target = $elem.find('OPTION:selected').attr('data-target')
				|| $elem.attr('data-target') || $elem.attr('rel') || $elem.attr('data-rel')	// Note: "data-rel" is depricated. "rel" only applies to links and should be depricated.
				|| ( $elem.is(':submit') && $form.attr('data-target') )
				|| ( $elem.is('SELECT.auto-submit') && $form.find(':submit[data-target]').attr('data-target') ) 
				|| ( $elem.is('SELECT.auto-submit') && $form.attr('data-target') ) 
				|| ( $elem.is('OPTION') && $elem.closest('SELECT').attr('data-target') )	// Applies on SELECT[data-method] 
				|| '.ajaxPanel';

			// Attempt to derive the #id selector syntax for the target element:
			if( !/^#/.test(target) && ( id = $elem.closest(target).id() ) ){ target = '#' + id }

			return target;

		},


		// Helper for parsing meta-data from a form: (Eg: the controller name and action, and the id of the object being edited etc)
		getActionOf : function($form){

			$form = $($form).closest('FORM');

			//  You can test this regex at http://rubular.com/r/7pWDd4CNyb The following comment breaks it down for you:
			//  regex:     path     /  controller  / id (if followed by edit, delete, ?, # or $END)      / action                             ?  params        # hash  $END
			var regex  = /(.*?(?:^|\/)([a-z_]+)(?:\/([0-9]+)(?=(?:\/edit|\/delete|\/?\?|\/?#|\/?$)))?(?:\/(index|new|edit|delete))?)\/?(?:(?:\?)([^#]*))?(?:(?:#)(.*))?$/i,
			    method = $form.find("INPUT[name='_method']").val() || $form.attr('method') || 'post',
			    href   = $form.attr('action') || '',
			    match  = href.match(regex) || [],

			    form   = {
					path		: match[1] || '',		// AKA pathname. The url as far as the "?" or "#" or end of string.
					controller	: match[2] || '',		// The name of the controller, just in front of the id or action. Eg "trips"
					id			: match[3] || '',		// But expect blank when handling "new" forms.
					action		: match[4] || '',		// Controller action name: index|new|edit|delete.
					param		: match[5] || '',		// AKA Query or search string. Everything after the "?" until the hash or end of string.
					hash		: match[6] || '',		// Everything after the "#".
					resource	: Layout.singularize(match[2]),	// The name of the controller, just in front of the last id or action. Eg "trip"
					params		: {},					// Hash of url parameters. Will be populated from form.param string.
					method		: method.toLowerCase(),	// The restful method name: get|post|put|delete.
					href		: href,					// The entire path including any query string and hash etc.
					uid			: $form.id()			// Pass the html id of the form element too.
				}

			// Populate params hash with all the name=value pairs in the url?parameters:
			$.each( form.param.split('&'), function(i,pair){ var p = pair.split('='); if(p[0]){ form.params[p[0]] = p[1] } } );

			// Derive {name}_id property for each resource in the path: (And attempt to read the id of the resource being edited)
			$.extend( form, Layout.getResourceIDsFrom(form.path) );
			if(form.resource){ form.resource_id = form.id };

			// Derive controller action from the method or regex-parsed action:
			switch(true){
				case !!form.action : break;												    // Assume regex-parsed action is valid. (index|new|edit|delete)
				case form.method == 'post'   &&  !form.id : form.action = 'create' ; break;	// clients/    (submit "new" form to create)
				case form.method == 'put'    && !!form.id : form.action = 'update' ; break;	// clients/123 (submit "edit" form to update)
				case form.method == 'delete' && !!form.id : form.action = 'destroy'; break;	// clients/123 (submit "delete" form to destroy)
				case form.method == 'get'    && !!form.id : form.action = 'show'   ; break;	// clients/123 ("show" & "index" should be irrelevant for a form!)
				case form.method == 'get'    &&  !form.id : form.action = 'index'  ; break;	// clients/ or clients/index
				default                                   : form.action = '';
			}

			console.log( 'getActionOf =>', form );
			return form;

		},

		// Derive hash of item_id properties for each item in the path: (Split path using positive lookahead to get each 'name/id')
		getResourceIDsFrom : function(path){

			var resources = {};

			$.each( path.split(/\/(?=[^\/]+\/[0-9]+)/), function(i,pair){

				var name  = pair.split('/')[0] || '', id = pair.split('/')[1],
				    model = Layout.singularize(name);

				if( model && id ){ resources[model+'_id'] = id }	// Eg: trip_id

			});

			return resources;
		},
		
		// Helper for singularising plural words such as controller names:
		singularize : function(word){

			word = word || '';
			var lookup = { children:'child', people:'person' };
			return lookup[word] || word.replace(/ies$/,'y').replace(/s$/,'').replace(/statuse$/,'status');

		}
	}


	// Initialise url-specific live event handlers: See end of script.


// *****



	// Generic helpers for ui-tabs:
	var Tabs = {

		// Ensure tab is selected:
		select : function(e,ui){
			$(this).tabs('select',ui.index);
		},

		// Triggered when a tab loads successfully: (Just passes the arguments along to the generic Layout.onSuccess)
		onTabSuccess : function(e,ui){
			var xhr = ui.tabs && ui.tabs.xhr || {};
			//ui.url = ui.url || $.data(ui.tab, 'load.tabs');		// TODO: Fix unformatted tabs after close client tab!
			Layout.onSuccess( ui.panel, 'success', xhr, ui, e );

			// Display any error/notice messages found in the response:
			showMessage( Layout.getMessagesFrom( xhr && xhr.responseText || ui.panel ) );
		},

		// TODO: Triggered when a tab fails: (Just passes the arguments along to the generic Layout.onError)
		onTabError : function(e,ui){
			var xhr = ui.tabs && ui.tabs.xhr || {};
			Layout.onError( ui.panel, 'error', xhr, ui, e );
		}
	
	};





	// Initialise global ajax settings:

	$.ajaxSetup({

// DEPRICATED
//		// Custom callback that fires just before ajax complete: (See customised ajax method in helpers.js)
//		beforeComplete : function(xhr, status, options) {

//			// Set a custom 'data-ajax-url' attribute on the target element if we have the necessary details:
//			if( xhr && xhr.options && xhr.options.target && xhr.options.url ) {
//				$(xhr.options.target).attr( ELEMENT_URL_ATTR, xhr.options.url );
//			}
//			//alert(xhr.options.url )
//		},

		// Depricated because it does not give use info about the url etc:
		//success : function(data,status,xhr){
		//	console.log(data,status,xhr)
		//},

		// Initialise any new tabs etc in client or trip pages AFTER EVERY AJAX LOAD:
		//complete : onAjaxComplete,

		error : function( xhr, status, error ){

			$(document.body).removeClass('waiting-for-ajax');
			console.log( 'AJAX ERROR:', error );

			// Intercept browser error when attempting to open a network file link:
			if( error && IS_BROWSER_DOC_LINK_SECURITY_ERROR.test(error) ){

				alert("Whoopsie! Don't panic. To edit documents on our network you need to:" +
					"\n\n\ - Right-click on the link then " +
					"\n - Click 'Open Link in Local Context  >  in This Tab'" +
					"\n\nWhy? Because of boring browser security restrictions." +
					"\n\nWhat if I don't see those options when I right-click? " +
					"\n - You'll need to add the 'LocalLink' plugin from: " +
					"\n    https://addons.mozilla.org/en-US/firefox/addon/281 ")

				return false

			}else{
			
				if( status == 'timeout' && !xhr.responseText ){
					return false;
				}
			
				var response = xhr.responseText
				//var response = xhr.responseText.split( /<\/?body[^>]*>/i )[1] || xhr.responseText;

				var $errorMessage = $('<h2 class="errorMessage ui-state-highlight ui-corner-all">Uh-oh, something went wrong.<br/>You could copy and paste these nerdy details into a support email: <input type="text"/></h2>');
				$errorMessage.find('>INPUT').val( response );
				
				showMessage($errorMessage);

			}

		},

		// Workaround employing custom comment tags so we can parse the content out of the server response when Firefox on Windows occasionally receives entire page in ajax response! %>
		dataFilter : function(data,type){

			if( ( type == undefined || type == 'html' ) && FIND_DATA_CONTENT.test(data) ){

				// Parse content from between custom <!--<DATA>--> comment tags:
				// Workaround is not working though! jQuery sometimes ignors our parsed data and uses the original responseText data.
				// alert( data.length + ' \n ' + FIND_DATA_CONTENT.exec(data)[1].length + ' \n ' + FIND_DATA_CONTENT.exec(data)[1] )
				return FIND_DATA_CONTENT.exec(data)[1];

			}

			// Typically we just return response as is:
			return data;

		}

		,timeout	: AJAX_TIMEOUT	// Milliseconds

	});



	$(document.body).ajaxComplete(function(e, xhr, settings) {

		$("DIV.ajaxPanel:not(.ajaxPanelBound)").ajaxComplete(function(e, xhr, ajaxOptions) {
			//console.log(ajaxOptions.type,ajaxOptions.url)
			var $target = $(this);

			//alert( "ajaxPanel " + $target.outerHtml() )

		})
		.addClass("ajaxPanelBound");


		// Initialise jQuery UI-theming widget: (In the System Admin > Theme page)
		//$('#ui-theme-switcher:empty').themeswitcher();

	});


	// Display ajax spinner animation during any ajax calls:
	$(document.body)

		// Fires when ajax call starts as long as we're not already waiting for any other ajax responses:
		.ajaxStart(function(){

			$(document.body).addClass('waiting-for-ajax');

		})

		// Fires at the start of every ajax call:
		.ajaxSend(function(){

			// This is a belt and braces fallback for occasions when ajaxStop is not triggered and spinner remains on screen.
			// It will at least disappear after a while! However jQuery still thinks it's waiting for an ajax response so ajaxStart will never fire again.
			window.clearTimeout(spinnerTimeoutId);
			spinnerTimeoutId = window.setTimeout(function(){ $(document.body).removeClass('waiting-for-ajax') }, AJAX_TIMEOUT + 1000 );

		})

		// Fires when ajax call completes and we're not waiting for any more ajax responses:
		.ajaxStop(function(){

			$(document.body).removeClass('waiting-for-ajax');
			window.clearTimeout(spinnerTimeoutId);

		})
	;




	// Automagically hijax all AJAX FORM SUBMITs: (Even those that will be loaded later via ajax)
	// Note: The value of the submit button may not be submitted if we used "click". I think this may be because of the live event.

	// TODO: Depricate this!
	$(":submit.ajax, .ajaxPanel :submit").live("click", function(e) {
return
		// Skip the clever stuff and bail out if the response will be a file to download:
		if( $(this).is('.download') || $(this).is('.ajaxDownload') ){ return }

		var success		= undefined;
		var complete	= onAjaxComplete;
		var $button		= $(this);
		var uiTarget	= $button.attr("rel");
		var ajaxBlank	= $button.is(".ajaxBlank");   // Optional flag to clear form container element after submit.
		var $parent		= $button.parents(".ajaxPanel").eq(0);
		var $form		= $button.closest("FORM");
		var thisForm	= $button.link()			// The link() method is a helper to parse details from a url etc.
		var alreadySucceeded	= false;

		// Attempt to derive target panel from the rel attribute, otherwise search up dom for .ajaxPanel:
		var $uiTarget = uiTarget ? $button.closest(uiTarget).eq(0) : $parent;

		// If we're targeting an ajaxPanel then try deriving the target's id instead if it has one:
		if( ( !uiTarget || uiTarget == '.ajaxPanel' ) && $uiTarget.attr('id') ){
			uiTarget = '#' + $uiTarget.attr('id');
		}

		// DERIVE uiTarget selector if we still don't know it:
		// TODO: Merge this with the previous condition?
		if( !uiTarget ){
			uiTarget = "#" + $uiTarget.id();
		}


		// Before creating new CLIENT or TRIP, prepare custom callbacks to add tabs etc:


		if( thisForm.method == 'post' || thisForm.method == 'put' ){


			// CREATE TRIP:
			if( $button.is('.createTrip') ){

				// These variables are shared by the success & complete callbacks:
				var urlTemplate	= thisForm.url + '/{trip_id}';		// Eg: /clients/12345678/trips/{trip_id}
				var trip_id		= 0;
				var tabLabel	= 'Trip';
				var tripTypeID	= $form.find("[name='trip[type_id]']").val();
				var tabToDelete	= tripTypeID == FIXED_DEPARTURE ? $("UL:visible.clientPageTabsNav").parent().tabs('option', 'selected') : null;

				// For some reason, the success-callback was being fired multiple times so instead we just
				// use it to set a flag and then do the clever stuff in the complete-callback instead:
				success = function( data, status, xhr ){

					if( !alreadySucceeded ){

						alreadySucceeded = true;

						var $fields = $(data).find('INPUT:hidden');

						trip_id  = $fields.filter('[name = trip_id]').val();
						tabLabel = $fields.filter('[name = trip_title]').val();

					}

				}

				complete = function( xhr, status ){

					if( alreadySucceeded ){

						var tabUrl   = urlTemplate.replace( '{trip_id}', trip_id );

						// Add new trip tab to the tabs on the left hand side:
						$("UL:visible.clientPageTabsNav").parent().tabs( 'add', tabUrl, tabLabel, 3 );

						// Neither delete not disabled seem to work as expected here:
						// TODO: Better strategy for adding/removing tabs after ajax:
						if(tabToDelete){
							$("UL:visible.clientPageTabsNav").parent().tabs( 'option', 'disabled', [tabToDelete+1] );
						}

					};

					onAjaxComplete( xhr, status );

				};

			}


			// CREATE CLIENT:
			else if( $button.is('.createClient') ){

				// These variables are shared by the success & complete callbacks:
				var urlTemplate		= thisForm.url + '/{client_id}';		// Eg: /clients/{client_id}
				var client_id		= 0;
				var tabLabel		= 'Client';

				// For some reason, the success-callback was being fired multiple times so instead we just
				// use it to set a flag and then do the clever stuff in the complete-callback instead:
				success = function( data, status, xhr ){

					if( !alreadySucceeded ){

						var $errorMessages	= $(data).find('.errorMessage');
						var saved_ok		= $errorMessages.length == 0 || $errorMessages.is(':empty');

						if( saved_ok ){

							alreadySucceeded = true;

							var $fields = $(data).find('INPUT:hidden');

							client_id = $fields.filter('[name = client_id]').val();
							tabLabel  = $fields.filter('[name = client_label]').val();

						}else{

							// Server reported validation errors.

						}

					}

				}

				complete = function( xhr, status ){

					if( alreadySucceeded && client_id ){

						var tabUrl		= urlTemplate.replace( '{client_id}', client_id );
						var tabIndex	= $('#pageTabs').tabs( "option", "selected" ) - 1;

						// Add new trip tab to the tabs on the left hand side:
						$('#pageTabs').tabs( 'add', tabUrl, tabLabel, 1 );

					};

					onAjaxComplete( xhr, status );

				};

			}


		}

		// When using live event the ajaxSubmit() method will not include name/value of submit button so add it:
		var buttonData = {};
		buttonData[ $button.attr('name') ] = $button.val();

//		$form.ajaxSubmit({
//			target		: uiTarget,
//			success		: success,
//			complete	: complete,
//			data		: buttonData
//		});

		//return false;
		
		// Pass responsibility over to the new Layout handlers!

	});




	// AUTO-SUBMIT is used submit the form when user selects a new item in a pick list:
	// DEPRICATED in favour of the Layout.livePath/liveForm functionality.
	//	$('SELECT.auto-submit').live('change', function(){

	//		var $list		= $(this);
	//		var $form		= $list.closest('FORM');
	//		var $submit		= $form.find('INPUT:submit').eq(0);
	//		var uiTarget	= $list.attr('rel') || $list.attr('data-rel') || $list.attr('data-target') || $submit.attr("rel");
	//		var ajaxBlank	= $submit.is(".ajaxBlank");				// Optional flag to clear form container element after submit.
	//		var $parent		= $form.parents(".ajaxPanel").eq(0);
	//		var thisForm	= $submit.link()						// The link() method is a helper to parse details from a url etc.

	//		// Attempt to derive target panel from the rel attribute, otherwise search up dom for .ajaxPanel:
	//		var $uiTarget = uiTarget ? $submit.closest(uiTarget).eq(0) : $parent;

	//		// Derive uiTarget selector if we still don't know it:
	//		if( !uiTarget && $uiTarget.attr("id") ) uiTarget = "#" + $uiTarget.id();

	//		$form.ajaxSubmit({
	//			target		: uiTarget
	//			//success		: success,
	//			//complete	: complete
	//		});

	//	});



	// DEPRICATED
	//	// Called when any ajax calls complete:
	//	function onAjaxComplete(xhr, status, options) {

	//		var isHtml		= /^\s*\</;				// var isJson = /^\s*[\[\{]/;
	//		var findFormUrl	= / action="([^"]*)"/;

	//		// Only update UI elements if response is html:
	//		if( xhr && xhr.responseText && isHtml.test(xhr.responseText) ){

	//			// Derive a handy hash of url info kinda like window.location on steroids:
	//			// (Extract <form action="url"> using a regex because some responseText can be too big or complex for jQuery to parse)
	//			var formAction	= ( findFormUrl.exec(xhr.responseText) || [] )[1];
	//			var url			= parseUrl( formAction );
	//			var target		= xhr && xhr.options && xhr.options.target;
	//			var $target		= undefined;
	//			
	//			if( target ){ $target = $(target) }

	//			//initLevel2Tabs_forClient($target);
	//			//initLevel3Tabs_forTrip($target);
	//			//initLevel2Tabs_forSysAdmin($target);
	//			//initLevel2Tabs_forReports($target);
	//			initFormAccordions($target);
	//			//initFormTabs($target);	// Eg: countriesTabs on Trip Summary page.
	//			initSpinboxes($target);
	//			initDatepickers($target);
	//			initPostcodeSearch($target);
	//			initMVC($target);
	//			triggerTripInvoiceFormChange();

	//			// Display any user-feedback messages found in the response:
	//			// (Extract message elements using a regex because some responseText can be too big or complex for jQuery to parse)
	//			var messagesFragment = ( FIND_MESSAGE_CONTENT.exec(xhr.responseText) || [] )[1];
	//			if( messagesFragment ){
	//				var $newMessages	 = $(messagesFragment).closest(".noticeMessage, .errorMessage");
	//				showMessage( $newMessages );
	//			}

	//			// TRIP ELEMENTs: Derive trip_element.id from the form url and refresh the element in the timeline:
	//			if( url.resource.trip_element ) {

	////				var elemId			= url.resource.trip_element;
	////				var elemIdFieldName = "trip_element[id]";
	////				//var elemClass	 = elemIdFieldName + "=" + elemId;   // Eg: class="trip_element[id]=123456"
	////				//	elemClass	 = elemClass.replace(/([\[\]\=])/g,"\\$1")
	////				//var $timelineElem = $("LI." + elemClass);
	////				var $timelineElem = $("INPUT:hidden[value='" + elemId + "'][name='trip_element[id]']").parents("LI.tripElement:first");

	////				$timelineElem.reload(function() {
	////					// Refresh timeline overview after ajax reload:
	////					//$('DIV.timelineContent:visible').timelineOverview();
	////				}, true);

	//			}


	//			// Check for a message from the server telling us to OPEN A CLIENT TAB for the specified client:
	//			if( $target && $target.length ){
	//			
	//				// Look for <input name="client_id" class="showClient" value="123456">
	//				$target.find('INPUT[name=client_id][value].showClient').each(function(){

	//					var client_id	 = $(this).val();									  // This extra search simple allows for when the field has been carelessly rendered in a <div class="formField">
	//					var client_label = $(this).siblings('INPUT[name=client_label]').val() || $(this).parent().siblings().children('INPUT[name=client_label]').val();

	//					openClientTab( client_id, client_label );

	//				});
	//			
	//			}
	//			
	//		}

	//	};





	// Initialise tabs:

		initLevel1Tabs_forPage();		// In turn this triggers initLevel2Tabs_forClient();
		//initLevel2Tabs_forSysAdmin();
		//initLevel2Tabs_forReports();	// Typically this is no use here but helpful when testing reports page in isolation.

		$('#dashboard-tabs').tabs();


	// Initialise accordions:

		initFormAccordions();


	// Initialise Spinbox fields:

		initSpinboxes();




	// Initialise "mailto" links, including those next to an email textbox:

	$("xINPUT.mailto").prev("LABEL:not(:has(A:href))").each(function() {
		var $elem = $(this).next("INPUT.mailto");
		mailto = "mailto:" + ($elem.data("mailto") || $elem.attr("mailto") || $elem.val());
		$("<a>").attr({ href: mailto }).addClass("mailto").text(mailto).appendTo(this);
	});



// Initialise DATEPICKERs:

	initDatepickers();


// Initialise calculated fields etc:

	initMVC();	// Depricated

	initKeyPressFilters();

	initTripElementFormTotals();

	initTripInvoiceFormTotals();






// Respond to any "OPEN CLIENT" links: (Eg: <a href="/clients/1234">)

	$("A:resource(/clients/[0-9]+), OPTION:resource(/clients/[0-9]+)").live('click', function() {

		var url			= $(this).attr("href") || $(this).val();
		var location	= parseUrl(url);
		var resource	= location.resource;

		if (resource.client && resource.client === resource.last && !location.action) {

			var id = location.resource.client;
			var label = location.params.label;

			openClientTab(id, label);
			return false;
		};

	});



// Respond to any "NEW CLIENT" or "NEW TOUR" links:

	//$("A[href *= '/clients/new'], A[href *= '/tours/new']").live('click', function() {
	$("A[href *= '/tours/new']").live('click', function() {

		var url		= $(this).attr('href');
		//var newId	= '#' + url.replace('/', '');
		var label	= /tours/.test(url) ? 'New tour' : 'New client';

		$('#pageTabs').tabs('add', url, label);

		return false;
	});




// Respond to any "OPEN TOUR" links: (Eg: <a href="/tours/1234">)

//	$("A:resource(/tours/[0-9]+)").live('click', function() {

//		var url			= $(this).attr("href");
//		var location	= parseUrl(url);
//		var resource	= location.resource;

//		if (resource.tour && resource.tour === resource.last && !location.action) {

//			var id		= location.resource.tour;
//			var label	= location.params.label;

//			openTourTab(id, label);
//			return false;
//		};

//	});





// DEPRICATED
// React to any "add NEW TRIP" links:

//	$("A[href *= '/trips/new']").live('click', function() {

//		var url			= $(this).attr('href');
//		var $lhsTabs	= $('UL:visible.clientPageTabsNav').parents('.ui-tabs:first');
//		var location	= parseUrl(url)

//		if( location.resource.client && location.params.copy_trip_id ){
//		
//			openClientTab( location.resource.client );
//		
//		// Open the "New trip" tab: (The last one on the left hand side)
//		} else if( $lhsTabs.length > 0 ){

//			var newTripTabIndex = $lhsTabs.tabs('length') - 1;
//			$lhsTabs.tabs( 'select', newTripTabIndex );

//		}

//		return false;
//	});





// React to any "SHOW MORE..." option in pick lists:
// Simply fetch new list items from the specified url into the list:
// Eg: <option value="/suppliers/?list=option&type_id=4">+ Show more...</option>

	$("OPTION[value *= 'list=option']").live('click', function(){

		var $item	= $(this).text('Fetching more...');
		var url		= $item.val();

		// Load the new <option> items into the list and delete the "Show more" item:
		// Notice we use get() and append() instead of load() because we don't want to lose any existing list items.
		$.get( url, function(data){
			$item.closest('SELECT').append(data).end().remove();
		})

	});





	// React to any link to open SYSTEM ADMIN page:

	$("A[href $= /system]").live("click", function() {

		existingTabIdx = $('#pageTabs > .sectionHead LI:contains(' + SYSTEM_ADMIN_LABEL + ')').prevAll("LI").length;

		if (existingTabIdx) {

			// System tab is already open, so select it:
			$("#pageTabs").tabs("select", existingTabIdx);

		} else {

			// Add a new tab for system admin:
			var lastButOne = $("#pageTabs").tabs('length') - 1;
			$("#pageTabs").tabs('add', '/system', SYSTEM_ADMIN_LABEL, lastButOne);
		}

		return false;

	});




	// React to any link to open WEB REQUESTS page:

	$("A[href $= /web_requests]").live("click", function() {

		existingTabIdx = $('#pageTabs > .sectionHead LI:contains(' + WEB_REQUESTS_ADMIN_LABEL + ')').prevAll("LI").length;

		if (existingTabIdx) {

			// Web requests tab is already open, so select it:
			$("#pageTabs").tabs("load", existingTabIdx);

		} else {

			// Add a new tab for Web requests admin:
			var lastButOne = $("#pageTabs").tabs('length') - 1;
			$("#pageTabs").tabs('add', '/web_requests', WEB_REQUESTS_ADMIN_LABEL, lastButOne);
		}

		return false;

	});




	// React to any link to open BROCHURE REQUESTS (aka Brochure merge) page:
	// Eg: http://database2:82/brochure_requests?brochure_merge=true

	$("A[href *= /brochure_requests][href *= 'brochure_merge=true']").live("click", function() {

		existingTabIdx = $('#pageTabs > .sectionHead LI:contains(' + BROCHURE_REQUESTS_ADMIN_LABEL + ')').prevAll("LI").length;

		if (existingTabIdx) {

			// Web requests tab is already open, so select it:
			$("#pageTabs").tabs("load", existingTabIdx);

		} else {

			// Add a new tab for Brochure Requests admin:
			var lastButOne = $("#pageTabs").tabs('length') - 1;
			$("#pageTabs").tabs('add', $(this).attr('href'), BROCHURE_REQUESTS_ADMIN_LABEL, lastButOne);
		}

		return false;

	});



	// React to any link to open REPORTS page:

	$("A[href $= /reports]").live("click", function() {

		existingTabIdx = $('#pageTabs > .sectionHead LI:contains(' + REPORTS_PAGE_LABEL + ')').prevAll("LI").length;

		if (existingTabIdx) {

			// Web requests tab is already open, so select it:
			$("#pageTabs").tabs("load", existingTabIdx);

		} else {

			// Add a new tab for Reports page:
			var lastButOne = $("#pageTabs").tabs('length') - 1;
			$("#pageTabs").tabs('add', $(this).attr('href'), REPORTS_PAGE_LABEL, lastButOne);
		}

		return false;

	});





// React to any link to create a LETTER document:

//	$("SELECT.create-letter OPTION[value]").live('click', function(){

//		var params = {
//			document_template_file	: $(this).val(),
//			document_type_id		: DOCUMENT_TYPE_ID_FOR_LETTERS

//		$.post('/documents')
//		
//		return false;

//	});




// Initialise AJAX form links: (For hijaxing "Add new" and "Edit" links that have rel="#someElementID")
// TODO: Handle keyboard access on lists!
// TODO: Depricate our custom href attribute in favour of more compliant data-href attribute.
/*
	$('A.ajax, .ajaxPanel A, SELECT[data-href] OPTION, SELECT[href] OPTION').live('click', function(e) {

		return // !!!

		var $link	= $(this);
		var $list	= undefined;

		// Some links should not be interfered with so bail out if necessary:
		if( $link.is('.noajax, .scrollTo, [href^=mailto], [rel*=document]') || $link.parents().is('UL.ui-tabs-nav') || e.altKey || e.button == BUTTON.RIGHT ){
			return;
		}

		// Some links should not be left-clicked so bail out and cancel the event:
		if( $link.is('.right-click') && e.button == BUTTON.LEFT ){
			return false;
		}

		// Clicked element is usually <a href="url" rel="#elementid"> ...
		var url			= $link.attr('href') || '';
		var uiTarget	= $link.attr('rel' ) || '';

		// ...but it might be something like <option value="url"> or
		// <select href="/suppliers/{value}/edit"><option value="123">...
		// This technique also allows for placeholders in the url, eg: '/clients/{value}'
		if ( $link.is('OPTION') ){
			$list		= $link.parents('SELECT');
			uiTarget	= uiTarget || $list.attr('rel') || $list.attr('data-rel');
			url			= url || $list.attr('data-href') || $list.attr('href') || $link.val();
			url			= url.replace( '{value}', $link.val() ).replace( '{text}', $link.text() );
		}

		// TODO: Merge & refactor this uiTarget derivation with the similar code in the submit handler.

		// TODO: Find out why this caused trip_element cancel button to try to leave the page
		//	// If we're targeting an ajaxPanel then try deriving the target's id instead if it has one:
		//	if ( ( !uiTarget || uiTarget == '.ajaxPanel' ) && $uiTarget.attr('id') ){
		//		uiTarget = '#' + $uiTarget.attr('id');
		//	}

		// If target is .ajaxPanel then find parent ajaxPanel, otherwise search for closest match:
		if ( !uiTarget || uiTarget == '.ajaxPanel' ){
			var $uiTarget = $link.parents('.ajaxPanel');
		}else{
			var $uiTarget = $link.cousins(uiTarget, true);
		}

		// Only use the first target we found, unless selector begins with * :
		if (!uiTarget || uiTarget.charAt(0) !== '*'){
			$uiTarget = $uiTarget.eq(0);
		}

		// If $uiTarget has an id then ensure uiTarget refers to it's id to me more specific:
		//if (!uiTarget && $uiTarget.attr("id")) uiTarget = '#' + $uiTarget.attr('id');

		// Assign unique id to the element if it does not already have one: (Using our custom jQuery id() method)
		if ( !uiTarget || uiTarget.charAt(0) !== '#' ){
			uiTarget = '#' + $uiTarget.id();
		}


		// Specific handler for IMAGESELECTOR links to open popup:
		if (uiTarget == "#imageSelector") {

			var $this = $(this);

			$(this).qtip({
				content: {
					url: this.href,
					data: { country_id: 2 }
				},
				show: {
					ready: true,
					solo: true,
					when: { event: "click" }
				},
				hide: {
					fixed: true,
					when: { event: "unfocus" }
				},
				style: {
					name: "dark",
					width: 520,
					tip: "bottomLeft"
				},
				position: {
					corner: {
						target: "topMiddle",
						tooltip: "bottomLeft"
					},
					adjust: {
						y: 30
					}
				},
				api: {
					onHide: function() { $this.qtip('destroy') }
				}
			});


		// Generic handler for all AJAX CANCEL buttons on forms: (Eg when user clicks Cancel on "/clients/new" form)
		} else if( $link.is('.ajaxCancel') ) {

			// Assume link to Edit page if form's url ends with /id ?
			var formUrl		= $link.parents('FORM').attr('action');
			var formMethod	= $link.parents('FORM').attr('method');
			var wasEdit		= (formMethod === 'post');	  //  /\/([0-9]+)$/.test(formUrl);

			// "A.ajaxCancel.ajaxBlank" means simply clear the contents of $uiTarget:
			if ( $link.is('.ajaxBlank') ) {

				$uiTarget.animate({ height: 'hide', opacity: 0 }, 'slow', function() { $(this).empty(); });

				// Close EDIT form by loading the target url:
			} else if (wasEdit) {

				$uiTarget.load(url);

				// Close NEW form by selecting first tab in the containing tabs and discarding the 'new' tab:
			} else {

				$tabs = $("A[href='" + uiTarget + "']").parents('.ui-tabs:first');
				var selected = $tabs.tabs('option', 'selected');
				$tabs.tabs('remove', selected);

			};


		// Generic handler for other ajax links that have a REL attribute #target or are contained within an ajaxPanel:
		} else if( $uiTarget.length ) {

			var params		= { uiTarget: uiTarget };
			var do_post		= /_method=POST/i.test(url);
			var no_callback	= $link.is('.no-callback') || ( $list && $list.is('.no-callback') );

			var callback	= no_callback ? undefined : function(responseText, status, xhr) {

				// Custom animation for TripElements form ONLY:
				$uiTarget.filter('.tripElementFormContainer').animate({ height: 'show', opacity: 1 }, 'slow');

				// When content loads, set rel target on all links that don't already have a target:
				$uiTarget.find('A, :submit').not('[rel]').attr({ rel: uiTarget }).addClass('ajax');

				//initLevel3Tabs_forTrip($uiTarget);
				//initLevel2Tabs_forReports($uiTarget);
				initFormAccordions($uiTarget);
				initSpinboxes($uiTarget);
				initDatepickers($uiTarget);
				initPostcodeSearch($uiTarget);
				initMVC($uiTarget);

				// TODO: checkboxList style and testing:
				//$uiTarget.find( 'SELECT[multiple]' ).checkboxList();

			};


			// Special action for POST, otherwise assume we're doing a GET:
			if( do_post ){
			
				$.post(url, params, callback);

			}else{

				$uiTarget.load(url, params, callback);

			}

			// Custom animation for TripElements form ONLY: (while the ajax is loading)
			$uiTarget.filter(".tripElementFormContainer").animate({ height: "hide", opacity: 0 }, "slow");
		}

		// else $.get(this.href);

		return false;
	});
*/




	// Handler for click on checkboxes in a checkbox list: (Eg: name="trip[countries_ids][]" )
	$(":checkbox[name *= '_ids' ]").live('click', function(){

		var $checkbox		= $(this),
			value			= $checkbox.val(),
			name			= $checkbox.attr('name'),
			$tabPanel		= $checkbox.closest('DIV.ui-tabs-panel'),	// This tab's content panel.
			$tabContainer	= $tabPanel.closest('DIV.ui-tabs');			// Tabs container element.

		// Un/tick the corresponding checkbox if there is one in another tab:
		var $otherCheckbox = $tabContainer
			.find(":checkbox[name='" + name + "'][value='" + value + "']")
			.not( $checkbox )
			.attr({ checked: $checkbox.attr('checked') });

		// Add a copy of the checkbox to the summary tab if there isn't one already:
		if( $otherCheckbox.length == 0 && !$tabPanel.is('.countriesSelected') ){

			$checkbox.closest('LI').clone()
				.appendTo( $tabContainer.find('DIV.countriesSelected UL.checkboxList') );
		
		}

	});




/*
	// ???
	function onAjaxFormLoaded() {
		$("#bannerTarget").callout({
			className: "bannerCallout",
			arrowHeight: 20,
			arrowInset: 40,
			cornerRadius: 15,
			width: 700,
			content: "#imageEditor"
		});
	};
*/





	// Initialise hash of helper callbacks for the autocomplete plugin:

	var autocomplete_helpers = {


		// Parse json as soon as it loads, to rearrange results as array of objects each with {data, value, result} attributes for autocompleter. More info: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
		// TODO: Depricate this by beefing up the json preparation on the server.
		parseItems : function(rows) {

			return $.map(rows, function(client) {

				// Ensure missing fields are at least represented as blanks:
				// Set up a more friendly alias for active_trips and derive fullname & shortname if not provided in the json:
				// Note: client.shortname is used later to label the client tabs.
				if( !client.title		){ client.title		= '' };
				if( !client.forename	){ client.forename	= '' };
				if( !client.name		){ client.name		= '(no name)' };
				if( !client.trips		){ client.trips		= client.active_trips };
				if( !client.fullname	){ client.fullname  = [ client.title, client.forename, client.name ].join(' ') };
				if( !client.shortname	){ client.shortname = [ client.title, client.forename.charAt(0), client.name ].join(' ') };

				return { data: client, value: client.name, result: client.name };

			});

		},


		// Generate html for each item in the json data: (Arguments: json-object, row-index, number-of-rows, query-string)
		formatItem : function(client, row, count, q) {

			var address  = [], email = [], addr = client.address, tripSummary = 'Trips: ' + client.trips_statement;

			// Prepare the address lines, leaving out any that are blank:
			if( addr ){

				// Give postcode field a little extra formatting to stop it splitting across lines: 
				if( addr.postcode ){ addr.postcode = '<strong>' + addr.postcode.split(/\s+/).join('&nbsp;') + '</strong>' };

				$( 'address1 address2 address3 address4 address5 postcode country'.split(' ') ).each(function(i,field){
					if( addr[field] ){ address.push( addr[field] ) }
				});

			}

			// Email addresses:
			if( client.email1 ){ email.push(client.email1) }
			if( client.email2 ){ email.push(client.email2) }

			// Assemble html for the item: (Using native javascript for best performance)
			var html = [
				//'<li>',
					'<div class="name ui-icon ui-icon-client">',	client.fullname,	'</div>',
					'<div class="address">',						address.join(', '),	'</div>',
					'<div><small class="email">',					email.join(', '),	'</small></div>',
					'<div class="trips"><small>',					tripSummary,		'</small></div>'
				//'</li>'
			];

			return html.join(' ');

		}

	};





	// Initialise autocomplete: (Main search box at top of page)

	$("#mainSearchText").autocomplete("/search", {

		max					: CLIENT_SEARCH_MAX_ROWS,
		delay				: CLIENT_SEARCH_DELAY_BEFORE_AJAX,
		//extraParams		: { user_id: $("#user_id").val() || 0 },
		//autoFill			: true,		// Works but hard to know which field to match and show.
		//mustMatch			: true,
		cacheLength			: 1,		// This simply allows the current results to stay in memory so double-click does not trigger re-search.
		minChars			: 3,
		matchContains		: false,
		matchSubset			: false,
		multiple			: false,
		multipleSeparator	: ",",
		dataType			: "json",
		scrollHeight		: 520,
		width				: 576,
		offsetLeft			: -300,
		//highlight		   : function(val,q){ return tag("em",val); },

		// Parse json as soon as it loads, to rearrange results as array of objects each with {data, value, result} attributes for autocompleter. More info: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
		parse: autocomplete_helpers.parseItems,

		// Generate html for each item in the json data: (json-object, row-index, number-of-rows, query-string)
		formatItem: autocomplete_helpers.formatItem,

		//useFormatItemAsIs : true,	// Custom enhancement: Tells plugin that result of formatItem is already wrapped in <li> tags.

		// ???:
		formatMatch: function(data, i, n, q) { // i=row index, n=number of rows, q=query string
			return data.postcode;
		},

		// Formats the value displayed in the textbox:
		formatResult: function(data, i, n, q) { // i=row index, n=number of rows, q=query string
			return data.postcode;
		}
	})

	// Respond to user's selection in the search results:
	.result(function(e, client) {

		openClientTab(client.id, client.shortname);

	});





	// HIGHLIGHT TEXTBOXES when they receive FOCUS. Highlight first on page by default:
	// (We use Event Capture or Event Delegation so we don't have to re-bind after every ajax call)
	if (window.addEventListener) {

		// Use Event Capture in MOZILLA: (Because it has no focus or focusin event that bubbles)
		window.addEventListener('focus', function(e) {  //window.captureEvents(Event.FOCUS)
			$(e.target).filter("INPUT:text,TEXTAREA").not('[readonly],[disabled]').each(function() { this.select() });
		}, true);   // <-- This flag ensures we use Event Capture.

		// Select first field on page when the page loads:
		$("A,SELECT,INPUT,TEXTAREA", "#pageContent").filter(":visible:first").focus();

	} else {

		// Use Event Delegation in IE: (The focusin event will bubble)
		$("A,SELECT,INPUT,TEXTAREA", "#pageContent").filter("INPUT:text,INPUT:password,TEXTAREA").not('[readonly]')
			.live("focusin", function() { this.select() })
		.end()
		.filter(":visible:first").focus();

	};






	// Handle events on the new/edit photo popup:

	// Depricated until needed:
	//	$("SELECT.imgFilename").live("change", onImgFileChange).triggerHandler("change");
	//	$("SELECT.imgFilename").live("keyup", onImgFileChange);
	//	$("SELECT.imgFolder").live("change", onImgFolderChange);
	//	$("SELECT.imgFolder").live("keyup", onImgFolderChange);

	// Respond when user chooses a different IMAGE FOLDER:
	function onImgFolderChange() {

		var companyFolder = $(this).val();
		var params = "list=files&folder=" + companyFolder;

		$(this).parents("DIV.imgFileSelector")
			.find("DIV.imgFilenameList SELECT")
			  .load("/photos OPTGROUP", params, onAfterAjax)
			  .empty().append("<option>Hang on mo...")
			.end()
			.find("DIV.imgFilenameList").addClass("waiting");

		function onAfterAjax() {
			$(this).parents("DIV.imgFileSelector")
			  .find("DIV.imgFilenameList").removeClass("waiting");

			if ($(this).children().length == 0)
				$(this).append("<option>Oops, none in here!");
		}
	};

	// Respond when user chooses a different IMAGE FILENAME:
	function onImgFileChange() {

		var $div = $(this).parents("DIV.imgFileSelector");
		var root = "imageLibrary";
		var companyFolder = "/" + $div.find(".companyFolder").val();
		var imgFolder = "/" + $div.find("SELECT.imgFolder").val();
		var filename = $(this).val();
		var url = "/" + buildPath(root, companyFolder, imgFolder, filename);
		console.log(url);

		$div.find("IMG.imgThumbnail")
			  .attr({ src: url, title: url })
			  .imgSize(onReadImgSize);  // jQuery plugin to measure IMG dimensions.

		function onReadImgSize(size) {
			var dimensions = size.width + " x " + size.height + " px";
			$(this).siblings(".imgFileSize").text(dimensions);
		}

	};




	// Respond to selection of tripElementTypeId in a TripElement form:
	// This allows the css to display only fields that are relevent to the TripElementType (Eg: .isFlight will reveal all fields flagged with .whenFlight)
	// UNUSED IN LIVE environment because the trip_element[element_type_id] field is hidden.
	function onTripElementTypeChange() {

		// Derive array of TripElementType names formatted as css classnames suitable for the form element:
		var elementType = LOOKUP_TRIP_ELEMENT_TYPE[$(this).val()], formClasses = [];
		$.each(LOOKUP_TRIP_ELEMENT_TYPE, function(id, type) {
			formClasses.push(formClassFor(type))
		});

		// Change the "isType" classname of the TripElement form:
		$(this).parents(".tripElementForm")
			.removeClass(formClasses.join(' '))
			.addClass(formClassFor(elementType));

		// Helper to derive form css class name from elementType: (Eg: formClassFor("flight") --> "isFlight")
		function formClassFor(classname) {
			return "is" + classname.substr(0, 1).toUpperCase() + classname.substr(1);
		}

	};



	$(".tripElementForm SELECT.tripElementTypeId")
		.live("click", onTripElementTypeChange)
		.live("keyup", onTripElementTypeChange);


	// Respond to click on tripElement is_subgroup checkbox:
	$(".tripElementForm INPUT:checkbox[name='trip_element[is_subgroup]']")
		.live("click", function() {
			$(this).parents(".tripElementForm").toggleClass("allTravellers", !$(this).is(":checked"));
		});










	// Apply <textarea> maxlength restrictor plugin:
	$('TEXTAREA')
		.textareaMaxlength({ maxlength:1000 })

	// Apply textareaResizer plugin: (Work in progress!)
		.filter('.resizable')
			.textareaResizer();




	// Set up rules for selections in checkbox lists: (For PRIMARY and INVOICABLE trip_clients)	$(":checkbox:visible[name *= 'is_primary']")		.checkboxLimit({ associates: ":checkbox:visible[name *= 'is_primary']", min:1, toggle:true } );	$(":checkbox:visible[name *= 'is_invoicable']")		.checkboxLimit({ associates: ":checkbox:visible[name *= 'is_invoicable']", min:1, toggle:true });	// Depricated because users need to be able to enter number of singles before adding named clients.	//	// Refresh the singles field when user un/ticks single checkboxes:	//	// (ONLY if ticked quantity is greater than the singles box)	//	$(":checkbox:visible[name *= 'is_single']").live('change', function(){	//		var $form    = $(this).closest('FORM');	//		var singles  = $form.find(":checkbox[name *= is_single]:checked").length;	//		var $singles = $form.find("[name = 'trip[singles]']");	//			//		if( singles > parseInt($singles.val()) ){ $singles.val(singles) }	//	});	






	//	// For highlighting all table cells in the COLUMN the mouse is hovering over:
	//	// The advantage of this technique is that it relies on css to apply style to all the cells in the column.
	//	// Use with css: TABLE.highlightcol0..9 TD:nth-child(1..10) { background-color:#EFEDDE; }
	//	// Also try    : TABLE.highlightcol0..9 COL.column { background-color:#EFEDDE; }
	//	$("TD").live('mouseover', function(){
	//		$(this).closest('TABLE').addClass(    'highlightcol' + this.cellIndex );
	//	}).live('mouseout', function(){
	//		$(this).closest('TABLE').removeClass( 'highlightcol' + this.cellIndex );
	//	});




	// Show system notifications when page loads then hide them after a delay:
	showMessage( $messages );













	// Helper to show SYSTEM MESSAGES etc then hide them after a delay:
	// The $newMessages argument contains a jQuery array of zero or more <h2> elements like these:
	//	<h2 class="noticeMessage ui-state-highlight ui-corner-all" style="display:none">Authenticated Successfully</h2>
	//	<h2 class="errorMessage ui-state-highlight ui-corner-all"  style="display:none"></h2>
	function showMessage( $newMessages ){

		window.setTimeout(function(){

			// Show system notifications etc then hide them after a delay:
			$newMessages.hide().not(':empty').each(function(){

				// When mouse moves over the message then prevent it from hiding after timeout.
				$(this).hover(function(){

					window.clearTimeout(messageTimeoutID);
					
					$(this).stop(true).animate( { opacity:1 }, 'fast' );

				// Reinstate timeout when mouse moves off the message:
				},function(){

					var $msg = $(this);
					messageTimeoutID = window.setTimeout(function() {
						//$msg.animate( { opacity:'hide' }, DURATION_OF_MESSAGE_HIDE, function(){
						//	$(this).slideUp( DURATION_OF_MESSAGE_HIDE, function(){ $(this).remove() } )
						//} )
						$msg.animate( { opacity:'hide' }, DURATION_OF_MESSAGE_HIDE )
							.slideUp( DURATION_OF_MESSAGE_HIDE, function(){
								$(this).remove()
							})
						;
					}, DELAY_BEFORE_MESSAGE_HIDE);

				})
				.appendTo('#messages')
				.trigger('mouseleave')
				.animate( { height:'show', opacity:'show' }, DURATION_OF_MESSAGE_SHOW );

			});

		}, DELAY_BEFORE_MESSAGE_SHOW);

	};




	// Helper to OPEN CLIENT TAB for a specified client id: (Expects client-id and tab-label as arguments)
	function openClientTab(id, label) {

		if( id && parseInt(id) > 0 ){

			existingTabIdx = $("#pageTabs > .sectionHead LI:has( INPUT.client-id[value='" + id + "'] )").prevAll("LI").length;

			if (existingTabIdx) {

				// There is already a tab displayed for this client, so select it:
				$("#pageTabs").tabs("select", existingTabIdx);

			} else {

				// Workaround when spaces have been escaped as '+' in a client link:
				label = ( label || 'Oops missing label!' ).replace( /\+/g, ' ' );

				var url		= "/clients/" + id,
					name	= label + '<input type="hidden" value="' + id + '" class="client-id" />';

				// Add a new tab for this client:
				$("#pageTabs").tabs('add', url, name);

			}
			
		}else{
			console.log( 'Unable to openClientTab(', id, COMMA, label, ')' );
		}

	}



	// Helper to OPEN TOUR TAB for a specified tour id: (Expects tour_id and tab_label as arguments)
	function openTourTab(id, label) {

		if( id && parseInt(id) > 0 ){

			existingTabIdx = $("#pageTabs > .sectionHead LI:has( INPUT.tour-id[value='" + id + "'] )").prevAll("LI").length;

			if (existingTabIdx) {

				// There is already a tab displayed for this tour, so select it:
				$("#pageTabs").tabs("select", existingTabIdx);

			} else {

				// Workaround when spaces have been escaped as '+' in a tour link:
				label = ( label || 'Oops missing label!' ).replace( /\+/g, ' ' );

				var url		= "/tours/" + id,
					name	= label + '<input type="hidden" value="' + id + '" class="tour-id" />';

				// Add a new tab for this client:
				$("#pageTabs").tabs('add', url, name);

			}
			
		}else{
			console.log( 'Unable to openTourTab(', id, COMMA, label, ')' );
		}

	}



	// Helper for initialising the TOP-LEVEL TABS: (Homepage-tab, Tours-tab and client-tabs)
	function initLevel1Tabs_forPage(context) {

		$( '#pageTabs', context ).tabs({

			cache			: false,
			tabTemplate		: '<li><a href="#{href}"><span>#{label}</span></a><a href="#{href}/close" class="close-tab">x</a></li>',
			panelTemplate	: '<div class="sectionBody ajaxPanel clientPageContainer"></div>',
			tabsSelector	: '>UL:first, >DIV:first>UL:first',	// This is a custom option. See modified ui.tabs.js script for details.

			// When a new tab is added, open it immediately: (The server will track every client opened recently by a user)
			add		: function(e,ui) {
				$(this).tabs('select',ui.index);
			},

			// Try to ensure loaded tab has a nice readable label:
			load	: function(e,ui){

				console.log('load')
				// Read hidden label element from the loaded client/tour tab panel:
				// TODO: Depricate #client_label and #tour_label?
				label = $(ui.panel).find('DIV.sectionHead:first').find('#tab_label, #client_label, #tour_label').val();

				// When replacing the label, ensure we don't accidentally overwrite any hidden child elements:
				if(label){
					var $childElems = $(ui.tab).children('INPUT');
					$(ui.tab).text( label ).append( $childElems );
				}

				//var url = $.data(ui.tab, 'load.tabs');
				//if( url ){ Layout.setHash(url,ui) }
				//if( url ){ Layout.onSuccess('success',undefined,ui) }

				Tabs.onTabSuccess(e,ui);			
			
			},

			// Let the server know which client is in the foreground: (So it can be the default tab next time)
			show	: function(e,ui){

				//if(ui.index==1){ $(ui.panel).html('<p>Fetching tours...</p>') }
				var url = $.data(ui.tab, 'load.tabs');
				//if( url && url.indexOf('clients/') >= 0 ){ $.get( url + '/select' ) }
				if( url && /clients\/[0-9]+/.test(url) ){ $.get( url + '/select' ) }
			},

			// When client tab is closed, let server know which client is no longer being worked on: (So it won't be reopened next time)
			// Note: The click on the CLOSE link in each tab is handled by a live('click') handler set up below.
			remove	: function(e,uiTab){
				var url = $(uiTab.tab).siblings('A.close-tab').attr('href');
				//if( url && url.indexOf('clients/') >= 0 ){ $.get(url) }
				if( url && /clients\/[0-9]+/.test(url) ){ $.get(url) }
			}
		})

		// Respond to click on a CLOSE link in a tab: (Assumes tab being closed is the currently selected tab)
		.find("#pageTabsNav A.close-tab").live("click", function(){
			try{
				var index = $('#pageTabs').tabs('option','selected');
				if( index ) $('#pageTabs').tabs('remove',index);
			}
			catch(e){}
			finally{ return false }
		});

		

	};



	// DEPRICATED
	// Helper for initialising the LEFT-HAND TABS on each client page: (Client details, documents, payments and trips)
	function initLevel2Tabs_forClient(context) {
		
		alert('initLevel2Tabs_forClient')
		
		$( 'UL:visible.clientPageTabsNav', context ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

			cache			: false,
			fx				: { opacity: 'toggle', duration: 100 },
			tabTemplate		: '<li class="trip trip-unconfirmed"><a href="#{href}">#{label}</a></li>',	// Only ever used after creating trip.
			panelTemplate	: '<div class="sectionBody ajaxPanel clientSubPageContainer"></div>',		// Only ever used after creating trip.
			panelsSelector	: function() { return this.list.cousins('.clientPageTabsContent > *') },	// This is a custom option. See modified ui.tabs.js script for details.


			// When a new tab is added, open it immediately:
			add		: function(e,ui) {
				$(this).tabs('select',ui.index);		// TODO: This is being called but is not selecting the tab.
			},

			load	: Tabs.onTabSuccess

			// When a tab is opened, initialise it's content:
//			show	: function(e, ui) {

//				if( $(ui.tab).is('.new') ){
//					initFormTabs( ui.panel );
//				}

//			}

		});
	};


//	// Helper for initialiasing the TRIP'S TABS on each trip page: (Trip summary, builder, itinerary etc)
//	function initLevel3Tabs_forTrip(context) {

//		// TODO: Find out why we need eq(0) to work around multiple tab loads. Seems to be a recursive problem. 
//		$( 'UL.tripPageTabsNav', context ).parent().eq(0).tabs({	// (See http://jqueryui.com/demos/tabs)

//			cache			: false,
//			panelTemplate	: '<div class="ajaxPanel sectionContainer noSectionHead"></div>',
//			panelsSelector	: function() { return this.list.cousins(".tripPageTabsContent > *") },	// This is a custom option. See modified ui.tabs.js script for details.
//			
//			load	: Tabs.onTabSuccess,

//			// Init content when Trip tabs are opened:
//			show	: function(e,ui) {

//				switch( ui.index ){

//					case 0 :	// Trip summary tab
//					
//						$(ui.panel).find("UL.tripCountriesTabsNav").parent().tabs({
//							selected: 0
//						});

//						// Activate the trip_clients search box in this tab panel:
//						initTripClientSearch(ui.panel);

//						// Important: The trip_clients checkboxes in this tab panel are enhanced by the checkboxLimit() plugin.
//						break;

//					case 1 :	// Trip builder tab

//						// Build timeline overview (after allowing for some rendering delays!):
//						window.setTimeout(function() {

//							$( 'DIV.timelineContent', ui.panel ).timelineOverview();

//						}, TIMELINE_DELAY_BEFORE_GENERATE_OVERVIEW);

//						break;

//				}

//			}
//		});
//	};



//	// DEPRICATED
//	// Helper for initialiasing the SYSTEM ADMIN TABS on the sys-admin page:
//	function initLevel2Tabs_forSysAdmin(context) {

//		$( 'UL:visible.sysAdminTabsNav', context ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

//			//selected		: 0,
//			fx				: { opacity: 'toggle', duration: 200 },
//			panelTemplate	: '<div class="sectionBody ajaxPanel"></div>',
//			panelsSelector	: function() { return $('#sysAdminTabsContent > *') },	// This is a custom option. See modified ui.tabs.js script for details.

//			// Do we need this on the sysadmin tabs?
//			add  : function(e, tab) {
//				$(this).tabs('select', '#'+tab.panel.id);
//			},

//			load : Tabs.onTabSuccess

//			//,show	: function(e,ui) {
//			//	$( 'SELECT[multiple]', ui.panel ).checkboxList();
//			//}
//		});
//	};


	// Helper for initialiasing the REPORT TABS on the reports page:
	function initLevel2Tabs_forReports(context) {

		$( 'UL:visible.reportTabsNav', context ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

			//selected		: 1,
			//fx				: { opacity: 'toggle', duration: 200 },
			panelTemplate	: '<div class="sectionBody ajaxPanel"></div>',
			//,panelsSelector	: function() { return $('#reportTabsContent > *') }	// This is a custom option. See modified ui.tabs.js script for details.

			load : Tabs.onTabSuccess

		});
	};


	// ADD-REPORT-FILTER button handler:
	$('.add-filter').live('click', function(){

		var newFilterUID	= '[NEW_' + ( +new Date ) + ']';						// New random id. Note: The Delete handler checks for 'NEW_' id.
		var $template		= $(this).siblings('.report-filter:last');				// Locate previous filter to use as a template.
		var $newFilter		= $template.clone().hide();
		$newFilter.find("INPUT[name *= '[id]'], .filter-value-box:gt(0)").remove();	// Discard id field and all but the first value field.
		$newFilter.find('INPUT,SELECT').removeAttr('disabled');						// Ensure fields are enabled (in case we just copied a 'deleted' filter)
		$newFilter.find("INPUT[name *= '[_delete]']").attr('disabled','disabled');	// Ensure the delete field is disabled so it can't be submitted.

		// Change the unique identifier of the cloned fields Eg: "report[report_filters_attributes][918][filter_value][]" => "report[report_filters_attributes][1280307283304][filter_value][]"
		// so that the server can distinguish them when the form is submitted.
		$newFilter.find('INPUT,SELECT')
			.each(function(){
				var newName = $(this).attr('name').replace( /\[\d+\]/, newFilterUID );
				$(this).attr( 'name', newName );
			})
			.end()
			.insertAfter( $template ).slideDown()
		;

		return false;

	})


	// add-report-filter-VALUE button handler: (depricated)
	$('.report-filter .add-filter-value').live('click', function(){

		var $template			= $(this).parent('.filter-value-box');
		var $newElements		= $template.clone().hide();
		
		$newElements.insertAfter( $template ).slideDown();

		return false;

	})


	// DELETE-REPORT-FILTER or VALUE button handler:
	$('.report-filter .delete-filter-value').live('click', function(){

		var $filter = $(this).parent('.filter-value-box').parent('.report-filter');

		// Delete the filter *value* element unless it is the only one:
		// (This action is no longer relevant because the ability to supply multiple values for one filter was depricated)
		if( $filter.has('.filter-value-box').length > 1 ){

			$(this).parent('.filter-value-box').slideUp(function(){ $(this).remove() });

		// Otherwise delete the *entire* filter unless it is the only one left:
		// Note: We cannot actually remove the filter elements yet because we still need to submit something to inform the server:
		}else if( $filter.siblings(".report-filter:has(INPUT[name *= '[_delete]'][disabled])").length > 0 ){

			if( $filter.is(":has( INPUT[ name *= '[NEW_' ] )") ){

				// This filter was added but not saved so we can remove it without letting the server know:
				$filter.slideUp(function(){ $(this).remove() });

			}else{

				// Activate the filter's _delete flag field, then deactivate the filter's settings:
				// (The latter is not strictly necessary but it helps reduce noise in the submitted params)
				$filter.find("INPUT[name *= '[_delete]']").removeAttr('disabled');
				$filter.find("SELECT[name *= '[name]'], SELECT[name *= '[filter_operator]'], INPUT[name *= '[filter_value]']").attr('disabled','disabled');

				$filter.slideUp();

			}

		}

		return false;

	})


//	// Moved to Trip.initShow()
//	// Helper for initialiasing the MINOR TABS within some pages:
//	function initFormTabs(context) {

//		$( 'UL:visible.countryTabs', context ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

//			// This is vital so ticked boxes are not discarded when user switches between country tabs!
//			cache			: true,

//			panelTemplate	: '<div class="countryTabsPanel"></div>',

//			// Wrap all the loaded <li> tags in a <ul> element:
//			load			: function(e,ui){
//				$(ui.panel).children('LI').wrapAll('<ul class="checkboxList columns ellipsis"></ul>')
//			}

//		});
//	};



	// Helper to activate any accordions:
	function initFormAccordions() {

		//window.setTimeout(function(){

			$("DL.accordion")

				.filter(".fixedHeight").accordion({
					autoHeight: false
				})
				.end()
				.not(".fixedHeight").accordion({
					autoHeight: false
					//fillSpace	: true
				})
			;
		
		//},500);	// Not proud of this! A workaround (when autoHeight:true) because sometimes the content (DDs) of the client summary accordions have no height.

	};


// Helper to activate any datepickers:
function initDatepickers(context) {

	// context argument may be a LivePath options hash or an element or a selector:
	context = ( context && ( context.panel || context.target ) ) || context || document;

	var defaults = {
		dateFormat: "dd/mm/yy",
		showButtonPanel: false,
		showOtherMonths: false,
		selectOtherMonths: false,	// TODO: This would be handy but our custom css needs fixing first!
		changeYear: true,
		changeMonth: true,
		minDate: "-90y",
		maxDate: "+5y",
		yearRange: "-90:+5"
	};

	var for_dob = $.extend( {}, defaults, {
		minDate: "-90y",
		maxDate: "+1y",
		yearRange: "-90:+1"
	});

	var for_travel = $.extend( {}, defaults, {
		minDate: "-1y",
		maxDate: "+5y",
		yearRange: "-1:+5"
	});

	// Init the various types of datepickers with relevant settings:
	// Note: The datepicker plugin adds the class 'hasDatepicker' to each field.
	$("INPUT.date:not(.hasDatepicker)", context)

		// Workaround: The datepicker assumes every target field has a unique id.
		// Because of our heavy use of tabs containing similar pages we cannot guarantee this.
		// This loop ensures any duplicated IDs are fixed before we proceed (along with any associated LABEL)
		.each(function(){

			var id				= $(this).attr('id'),
				dupeIDsSelector	= "INPUT[id='{id}']".replace('{id}',id),
				$others			= $(dupeIDsSelector).not(this);

			// Give all date elements a unique ID if their current ID is duplicated in the DOM:
			$others.each(function(){
				var uniqueID = id + '_' + (guid++);
				$(this).attr('id',uniqueID)
					.siblings("LABEL[for='" + id + "']").attr('for',uniqueID);
			});

		})

		// Trip and element date fields:
		.filter('.travel-date')
			.datepicker(for_travel)
		.end()

		// Birthday fields:
		.filter('.dob')
			.datepicker(for_dob)
		.end()

		// Other date fields:
		.not('.travel-date, .dob')
			.datepicker(defaults)
		.end()

	;

	// Cannot use daterange picker yet because it does not have collision detection:
	// http://www.filamentgroup.com/lab/date_range_picker_using_jquery_ui_16_and_jquery_ui_css_framework/
	//.filter(".daterange").daterangepicker({
	//	dateFormat: 'dd/mm/yyyy',
	//	arrows : true,
	//	presetRanges: [ { text:"First day of trip", dateStart:"2009-01-01", dateEnd:"2009-01-01" } ],
	//	presets: { dateRange:"Choose date from/to" }
	//	//posX: 100,
	//	//posY: '16.8em'
	//})

};

// Make initDatepickers available globally: (Eg: For use in trip_elements.js. TODO: Find a tidier solution)
window.initDatepickers = initDatepickers;



// Initialise Spinbox fields: (Assumes jquery.spinbox.css is loaded and spinbox-sprite image is available to mimic buttons)
function initSpinboxes(ui) {

	var panel = $( ui && ui.panel || !$.isPlainObject(ui) && ui || document )

	$("INPUT:text.spinbox:not(.spinbox-active)", panel)
			.filter(".exchange_rate").spinbox({
				max: 1000,
				step: 0.01,
				bigStep: 1
			}).end()
			.filter(".money:not(.spinbox-active)").spinbox({
				min: 0,
				max: 1000000,
				step: 1,
				bigStep: 10,
				scale: 2
			}).end()
			.filter(":not(.spinbox-active)").spinbox({
				min: 0,
				max: 50,
				step: 1,
				bigStep: 10
			});

	//$("INPUT.time").spinbox({
	//	keys			: [ /[0-9]/,/\:/,9,13,8,46,33,34,37,38,39,40,109,188,190 ],
	//	increment		: function(val,step,min,max,options){
	//		console.log( val )
	//		var hh = val.split(":")[0] || 0;
	//		var mm = val.split(":")[1] || 0;
	//		var date = new Date(2000,1,1,hh,mm);
	//		date.setMinutes( date.getMinutes() + step );
	//		console.log( date.getHours() + ":" + date.getMinutes() )
	//		return date.getHours() + ":" + date.getMinutes();
	//	},
	//	decrement		: function(val,step,min,max,options){ return val - step; },
	//	round		   : false
	//});
};




	// Initialise AUTOCOMPLETE within trip summary tab for adding trip_clients to trip:
//	function initTripClientSearch(context){

//		$('INPUT.trip-client-search',context).autocomplete("/search", {

//			max					: CLIENT_SEARCH_MAX_ROWS,
//			delay				: CLIENT_SEARCH_DELAY_BEFORE_AJAX,
//			cacheLength			: 1,		// This simply allows the current results to stay in memory so double-click does not trigger re-search.
//			minChars			: 3,
//			matchContains		: false,
//			matchSubset			: false,
//			multiple			: false,
//			multipleSeparator	: ",",
//			dataType			: "json",
//			scrollHeight		: 200,
//			width				: 576,

//			// Parse json as soon as it loads, to rearrange results as array of objects each with {data, value, result} attributes for autocompleter. More info: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
//			parse: autocomplete_helpers.parseItems,

//			// Generate html for each item in the json data: (json-object, row-index, number-of-rows, query-string)
//			formatItem: autocomplete_helpers.formatItem,

//			// ???:
//			formatMatch: function(data, i, n, q) { // i=row index, n=number of rows, q=query string
//				return data.postcode;

//			}

//		})


//		// Respond to user's choice by adding selected client to the list of travellers:
//		.result(function(e, client) {

//			var $table   = $('TABLE:visible.tripTravellers > TBODY');

//			if( $table.find("INPUT[value='" + client.id + "']").length === 0 ){

//				// Eg: <tr><td><a href="/clients/{id}?label={label}" class="show clientName">{name}</a></td>...</tr>
//				//var template = unescape( $table.find('>TR.template').clone().removeClass('hidden template').find(':disabled').removeAttr('disabled').end().outerHtml() );
//				var template	= $('#trip-traveller-row-template').html();

//				var index	 = $table.children('TR').length;

//				var html	 = interpolate( template, { id:client.id, name:client.shortname, label:client.shortname, index:index } );

//				// Append the row to the table using an animation: (Note we animate the contents because table cells do not animate as expected)
// 				$(html)
//					.find('> TD > *').hide().end()
//				.appendTo( $table )
//					.find('> TD > *').slideDown();

//			}

//		});
//	
//	}





	// Initialise AUTOCOMPLETE within address postcode fields:
	function initPostcodeSearch(context){

		$('INPUT.postal-code',context).each(function(){ console.log(this) }).autocomplete('/postcodes', {

			max					: POSTCODE_LOOKUP_MAX_ROWS,
			delay				: POSTCODE_LOOKUP_DELAY_BEFORE_AJAX,
			minChars			: POSTCODE_LOOKUP_MIN_CHARS,	// The longer the string, the faster the search.
			cacheLength			: 0,
			matchContains		: false,
			matchSubset			: false,
			multiple			: false,
			multipleSeparator	: ",",
			dataType			: "json",
			scrollHeight		: 200,
			width				: 576,

			// Parse json as soon as it loads, to rearrange results as array of objects each with {data, value, result} attributes for autocompleter. More info: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
			parse: function(rows){
				return $.map(rows, function(row){
					return { data: row, value: row.postcode, result: row.postcode };
				});
			},
			
			formatItem : function(postcode, row, count, q) {
				var address = [];
				if(postcode.address1){ address.push(postcode.address1) }
				if(postcode.address2){ address.push(postcode.address2) }
				if(postcode.address3){ address.push(postcode.address3) }
				if(postcode.address4){ address.push(postcode.address4) }
				if(postcode.address5){ address.push(postcode.address5) }
				if(postcode.postcode){ address.push(postcode.postcode) }
				return address.join(', ');
			}

		})
			
		// Respond to user's choice by populating address fields with selected address:
		.result(function(e, premise) {

			var $formFields = $(this).parent().parent().find('> DIV.formField');
			var $textboxes	= $formFields.find('> INPUT:text');
			var $country	= $formFields.find('> SELECT[name*=country]');
			
			$textboxes.filter('[name*=address1]').val( premise.address1 );
			$textboxes.filter('[name*=address2]').val( premise.address2 );
			$textboxes.filter('[name*=address3]').val( premise.address3 );
			$textboxes.filter('[name*=address4]').val( premise.address4 );
			$textboxes.filter('[name*=address5]').val( premise.address5 );
			$textboxes.filter('[name*=postcode]').val( premise.postcode );
			
			$country.filter(':not(:has(OPTION[value=' + UK_COUNTRY_ID + ']))')
				//.prepend('<option value="6">United Kingdom</option>')
			.end()
			.val(UK_COUNTRY_ID);
			
		})


			// Generate html for each item in the json data: (json-object, row-index, number-of-rows, query-string)
			//formatItem: autocomplete_helpers.formatItem,

			// ???:
			//formatMatch: function(data, i, n, q) { // i=row index, n=number of rows, q=query string
			//	return data.postcode;
			//}

	
	}









// DEPRICATED in favour of faster task-specific code:
function initMVC(context) {

	// Initialise TripElement calculated totals by faking user interaction and triggering event handler: 
	$("SELECT[name='trip_element[supplier_id]']").each( onTripElementFieldChange );

	return;

	// Go no further because this MVC function is DEPRICATED!
	// It caused memory leak and massive typing slowdown after several ajax calls.



/*
	// Listen to number of Trip adults/children/infants and update totals:
	$( 'FORM:has(.total):not(.mvc-active)', context ).View()

		// Update traveller count on TRIP form:
		.addListener("trip[adults], trip[children], trip[infants]", function(fields) {

			var $form	= $(this).parents("FORM");
			var $texts	= $form.find("INPUT");
			var total	= numVal("[name='trip[adults]']",   $texts)
						+ numVal("[name='trip[children]']", $texts)
						+ numVal("[name='trip[infants]']",  $texts);

			$form.find("DIV.trip-travellers.total").text(total);
			$texts.filter("INPUT[name='trip[travellers]'].total").val(total);

		})

		// Update trip element total costs on TRIP-ELEMENT form:
		// Important: This makes use of our custom textVal() jQuery method.
		.addListener("trip_element[supplier_id], trip_element[adults], trip_element[children], trip_element[infants], trip_element[cost_per_adult], trip_element[cost_per_child], trip_element[cost_per_infant], trip_element[exchange_rate], trip_element[taxes], trip_element[margin], trip_element[margin_type], trip_element[biz_supp_per_adult], trip_element[biz_supp_per_child], trip_element[biz_supp_per_infant]", function(fields) {

			// Cache field lists for better query performance:
			var $form			= $(this).parents("FORM:first");
			var $all			= $form.find("SELECT,INPUT,TEXTAREA,DIV");
			var $totals			= $all.filter(".total");						// Fields and DIVs with class of .total
			var $fields			= $all.filter("SELECT,INPUT,TEXTAREA");			// Form fields
			var $texts			= $fields.filter("INPUT:text");					// Textboxes only
			var $lists			= $fields.filter("SELECT");						// Dropdown lists only
			var $currencyField	= $lists.filter("[name='currency']");

			var currencyBeforeChange = $currencyField.val();

			// Update currency and exchange_rate whenever a new supplier_id is chosen:
			var newCurrencyName      = $lists.filter("[name='trip_element[supplier_id]']").textVal();   // Eg: "Air Iceland [GBP]" => "GBP"
			var $newCurrencyListItem = $currencyField.find("OPTION[text ^= '" + newCurrencyName + "']:first").attr({ selected: "selected" })

			var currencyAfterChange = $currencyField.val();

			// Update exchange_rate textbox: (unless no supplier is selected)
			if( currencyAfterChange != currencyBeforeChange ){
				var new_exchange_rate = $newCurrencyListItem.textVal();
				$texts.filter("[name='trip_element[exchange_rate]']").val(new_exchange_rate);
				//$lists.filter("[name='trip_element[margin_type]'], [name='trip_element[biz_supp_margin_type]']").find("OPTION[value!='%']").text(new_currency_name);	// Just update the friendly list item label representing the fixed-value margin.
			}

			// Read values from form:
			var adults				= numVal("[name='trip_element[adults]']", $texts);
			var children			= numVal("[name='trip_element[children]']", $texts);
			var infants				= numVal("[name='trip_element[infants]']", $texts);
			var cost_per_adult		= numVal("[name='trip_element[cost_per_adult]']", $texts);
			var cost_per_child		= numVal("[name='trip_element[cost_per_child]']", $texts);
			var cost_per_infant		= numVal("[name='trip_element[cost_per_infant]']", $texts);
			var exchange_rate		= numVal("[name='trip_element[exchange_rate]']", $texts);
			var taxes				= numVal("[name='trip_element[taxes]']", $texts);
			var margin				= numVal("[name='trip_element[margin]']", $texts);
			var margin_type			= $lists.filter("[name='trip_element[margin_type]']").val();
			var biz_supp_per_adult	= numVal("[name='trip_element[biz_supp_per_adult]']", $texts);
			var biz_supp_per_child	= numVal("[name='trip_element[biz_supp_per_child]']", $texts);
			var biz_supp_per_infant	= numVal("[name='trip_element[biz_supp_per_infant]']", $texts);
			var biz_supp_margin		= numVal("[name='biz_supp_margin']", $texts);
			var biz_supp_margin_type= $lists.filter("[name='trip_element[biz_supp_margin_type]']").val();

			// Calculate totals etc:
			var travellers			= adults + children + infants;
			var total_std_cost		= adults * cost_per_adult + children * cost_per_child + infants * cost_per_infant;
			var total_biz_cost		= adults * biz_supp_per_adult + children * biz_supp_per_child + infants * biz_supp_per_infant;
			var total_biz_margin	= (biz_supp_margin_type === '%') ? (total_biz_cost * biz_supp_margin / 100) : biz_supp_margin;	// Typically 10%
			var total_std_margin	= (margin_type === '%') ? (total_std_cost * margin / 100) : margin;
			var total_margin		= total_std_margin + total_biz_margin;
			var total_cost			= total_std_cost + total_biz_cost + taxes;
			var total_price			= total_cost + total_margin;
			var total_price_gbp		= total_price / Math.max(exchange_rate, 0.001);  // Prevent divide-by-zero error.

			// For better display, round currency values to 2 decimal places and pad pence with zeros where necessary:
			total_margin	= round(total_margin);
			total_cost		= round(total_cost);
			total_price		= round(total_price);
			total_price_gbp	= round(total_price_gbp);

			// Update fields with new totals etc:
			$totals.filter(".trip-element-travellers, [name='trip_element[travellers]'], #trip_element_travellers")
				.filter("INPUT").val(travellers)
				//.end().not("INPUT").text(travellers);

			$totals.filter("[name='trip_element[total_margin]'], #trip_element_total_margin")
				.filter("INPUT").val(total_margin)
				//.end().not("INPUT").text(total_margin);

			$totals.filter("[name='trip_element[total_cost]']")
				.filter("INPUT").val(total_cost)
				//.end().not("INPUT").text(total_cost);

			$totals.filter("[name='trip_element[total_price]']")
				.filter("INPUT").val(total_price)
				//.end().not("INPUT").text(total_price);

			$totals.filter("[name='total_price_gbp']")
				.filter("INPUT").val(total_price_gbp)
				//.end().not("INPUT").text(total_price_gbp);

		})
		
	.addClass('mvc-active');

	// Initialise calculated fields by faking user interaction to trigger MVC listeners: 
	$("INPUT[name='trip[adults]'], SELECT[name='trip_element[supplier_id]']").change();
	//$("INPUT[name='trip[adults]']").change();

	// HELPER for ensuring .val() returns a usable number from a form element:
	function numVal(selector, $fields, defaultAlternative) {
		//return parseFloat( $($fields).find(selector).andSelf().filter(selector).val() ) || defaultAlternative || 0;
		return parseFloat( $fields.filter(selector).val() ) || defaultAlternative || 0;
	};
*/
};







// Filter user's typing in numeric fields etc:
function initKeyPressFilters(){

	// Only allow POSITIVE values: (Simply by stopping the user form typing a minus)
	// TODO: Validate pasted values too?
	$( "INPUT:text.positive" ).live( 'keydown', function(e){

		if( isKeyCodeLikeFilter( e.keyCode, KEY.minus ) ){
			return false;
		}

	});

	

	// Only allow INTEGER values:
	// TODO: Validate pasted values too?
	$( "INPUT:text.integer" ).live( 'keydown', function(e){

		var keys = [ KEY.integer, KEY.tab, KEY.enter, KEY.backspace, KEY.delete, KEY.navigation, KEY.fkeys ];

		if( ( isKeyCodeInList( e.keyCode, keys ) && !e.shiftKey ) || e.ctrlKey || e.altKey ){

			// Key looks valid but lets do quick check to prevent symbols from being entered twice:
			if( isKeyCodeLikeFilter( e.keyCode, KEY.minus ) && $(this).is("[value *= '-']") ){ return false }
			if( isKeyCodeLikeFilter( e.keyCode, KEY.dot   ) && $(this).is("[value *= '.']") ){ return false }

			return true;

		}else{
			return false;
		}

	});

	// Only allow DECIMAL values:
	// TODO: Validate pasted values too? And other number formats? (eg in France they use commas and dots the other way around)
	$( "INPUT:text.decimal, INPUT:text.money" ).live( 'keydown', function(e){

		var keys = [ KEY.decimal, KEY.tab, KEY.enter, KEY.backspace, KEY.delete, KEY.navigation, KEY.fkeys ];

		if( ( isKeyCodeInList( e.keyCode, keys ) && !e.shiftKey ) || e.ctrlKey || e.altKey ){

			// Key looks valid but lets do quick check to prevent symbols from being entered twice:
			if( isKeyCodeLikeFilter( e.keyCode, KEY.minus ) && $(this).is("[value *= '-']") ){ return false }
			if( isKeyCodeLikeFilter( e.keyCode, KEY.dot   ) && $(this).is("[value *= '.']") ){ return false }

			return true;

		}else{
			return false;
		}

	});


	// Helper for testing whether keyCode matches any of the specified character codes or regexs:
	function isKeyCodeInList( keyCode, keyFilters ){

		return !!$.grep( keyFilters || [], function(keyFilter){
			return isKeyCodeLikeFilter( keyCode, keyFilter )
		}).length;

	};


	// Helper for testing whether keyCode matches a specified character code or regex:
	function isKeyCodeLikeFilter( keyCode, keyFilter ){

		return keyCode === keyFilter || ( keyFilter instanceof RegExp && keyFilter.test( String.fromCharCode(keyCode) ) );

	};

}




	// Called to update TripElement totals whenever user makes changes in TripElement form: (And each time it is loaded by ajax)
	function onTripElementFieldChange(){

		// Cache field lists for better query performance:
		var $form			= $(this).parents("FORM:first");
		var $all			= $form.find("SELECT,INPUT,TEXTAREA,DIV");
		var $totals			= $all.filter(".total");						// Fields and DIVs with class of .total
		var $fields			= $all.filter("SELECT,INPUT,TEXTAREA");			// Form fields
		var $texts			= $fields.filter("INPUT:text, INPUT:hidden");	// Textboxes and hiddens only
		var $lists			= $fields.filter("SELECT");						// Dropdown lists only
		var $currencyField	= $lists.filter("[name='currency']");

		var currencyBeforeChange = $currencyField.val();

		// Update currency and exchange_rate whenever a new supplier_id is chosen:
		var newCurrencyName      = $lists.filter("[name='trip_element[supplier_id]']").textVal();   // Eg: "Air Iceland [GBP]" => "GBP"
		var $newCurrencyListItem = $currencyField.find("OPTION[text ^= '" + newCurrencyName + "']:first").attr({ selected: "selected" })

		var currencyAfterChange = $currencyField.val();

		// Update exchange_rate textbox: (unless no supplier is selected)
		if( currencyAfterChange != currencyBeforeChange ){
			var new_exchange_rate = $newCurrencyListItem.textVal();
			$texts.filter("[name='trip_element[exchange_rate]']").val(new_exchange_rate);
			//$lists.filter("[name='trip_element[margin_type]'], [name='trip_element[biz_supp_margin_type]']").find("OPTION[value!='%']").text(new_currency_name);	// Just update the friendly list item label representing the fixed-value margin.
		}

		// Read values from form:
		var adults				= numVal("[name='trip_element[adults]']", $texts);
		var children			= numVal("[name='trip_element[children]']", $texts);
		var infants				= numVal("[name='trip_element[infants]']", $texts);
		var singles				= numVal("[name='trip_element[singles]']", $texts);
		var cost_per_adult		= numVal("[name='trip_element[cost_per_adult]']", $texts);
		var cost_per_child		= numVal("[name='trip_element[cost_per_child]']", $texts);
		var cost_per_infant		= numVal("[name='trip_element[cost_per_infant]']", $texts);
		var single_supp			= numVal("[name='trip_element[single_supp]']", $texts);
		var exchange_rate		= numVal("[name='trip_element[exchange_rate]']", $texts) || 1;	// Allow for rates accidentally set to zero.
		var taxes				= numVal("[name='trip_element[taxes]']", $texts);
		var std_margin			= numVal("[name='trip_element[margin]']", $texts);
		var biz_margin			= numVal("[name='trip_element[biz_supp_margin]']", $texts);
		var margin_type			= $lists.filter("[name='trip_element[margin_type]']").val();
		var biz_supp_per_adult	= numVal("[name='trip_element[biz_supp_per_adult]']", $texts);
		var biz_supp_per_child	= numVal("[name='trip_element[biz_supp_per_child]']", $texts);
		var biz_supp_per_infant	= numVal("[name='trip_element[biz_supp_per_infant]']", $texts);
		var biz_supp_margin		= numVal("[name='biz_supp_margin']", $texts);
		var biz_supp_margin_type= $lists.filter("[name='trip_element[biz_supp_margin_type]']").val();

		// Calculate basic costs: (in local currency)
		var std_margin_mult		= ( 100 - std_margin ) / 100;	// Eg: 24% means "(100-24)/100" => 0.76
		var biz_margin_mult		= ( 100 - biz_margin ) / 100;	// (See margin notes below)
		var travellers			= adults + children + infants;
		var total_adult_cost	= adults   * cost_per_adult;
		var total_child_cost	= children * cost_per_child;
		var total_infant_cost	= infants  * cost_per_infant;
		var total_sgl_supp		= singles  * single_supp;
		var total_std_cost		= total_adult_cost + total_child_cost + total_infant_cost + total_sgl_supp;
		var total_biz_cost		= adults * biz_supp_per_adult + children * biz_supp_per_child + infants * biz_supp_per_infant;

		// Calculate margins, taxes and price: (in local currency)
		// Important: We're calulating Margin and not Markup. There's a difference apparently :)
		// (Markup would be derived as a percentage of Cost. Eg: 24% on £100 => £124 (then subtract Cost to get Margin)
		// Margin is derived by calculating Gross using "Cost / margin-multipler". Eg: £100 / 0.76 => £131.6 (then subtract Cost to get Margin)
		var total_std_margin	= ( (margin_type          == '%') ? (total_std_cost / std_margin_mult) : std_margin      ) - total_std_cost;	// Typically 24%
		var total_biz_margin	= ( (biz_supp_margin_type == '%') ? (total_biz_cost / biz_margin_mult) : biz_supp_margin ) - total_biz_cost;	// Typically 10%
		var total_margin		= total_std_margin + total_biz_margin;
		var total_taxes			= taxes * travellers
		var total_cost			= total_std_cost + total_biz_cost + total_taxes;
		var total_price			= total_cost + total_margin;

		// Calculate prices: (in GBP)
		var total_margin_gbp	= total_margin / Math.max(exchange_rate, 0.0001);  //
		var total_cost_gbp		= total_cost   / Math.max(exchange_rate, 0.0001);  // Avoid divide-by-zero error.
		var total_price_gbp		= total_price  / Math.max(exchange_rate, 0.0001);  //

		// For better display, round and format currency values to 2 decimal places:
		total_margin			= round(total_margin);
		total_cost				= round(total_cost);
		total_price				= round(total_price);
		total_margin_gbp		= round(total_margin_gbp);
		total_cost_gbp			= round(total_cost_gbp);
		total_price_gbp			= round(total_price_gbp);

		// Update fields with new totals etc:
		$totals.filter(".trip-element-travellers, [name='trip_element[travellers]'], #trip_element_travellers").filter("INPUT").val(travellers)

		// BEWARE! total_margin field is actually total_margin_gbp!
		$totals.filter("[name='trip_element[total_margin]'], #trip_element_total_margin").filter("INPUT").val(total_margin_gbp)

		// BEWARE! total_cost field is actually total_cost_gbp!
		$totals.filter("[name='trip_element[total_cost]']").filter("INPUT").val(total_cost_gbp)

		$totals.filter("[name='trip_element[total_price]']").filter("INPUT").val(total_price)

		$totals.filter("[name='total_price_gbp']").filter("INPUT").val(total_price_gbp)

	};







	function initTripElementFormTotals(){

		// Update TripElement totals when these fields change:
		// Warning: If you change this code, verify that the form initialisation still works: See TripElement.initForm
		// By testing for general name likeness first, we waste less cpu time when event is triggered on unrelated fields:
		$( "INPUT[name ^= 'trip_element'], SELECT[name ^= 'trip_element']" ).live( 'change keyup', function(e){
			if( $(this).is("SELECT[name='trip_element[supplier_id]'], INPUT[name='trip_element[adults]'], INPUT[name='trip_element[children]'], INPUT[name='trip_element[infants]'], INPUT[name='trip_element[cost_per_adult]'], INPUT[name='trip_element[cost_per_child]'], INPUT[name='trip_element[cost_per_infant]'], INPUT[name='trip_element[single_supp]'], INPUT[name='trip_element[exchange_rate]'], INPUT[name='trip_element[taxes]'], INPUT[name='trip_element[margin]'], SELECT[name='trip_element[margin_type]'], INPUT[name='trip_element[biz_supp_per_adult]'], INPUT[name='trip_element[biz_supp_per_child]'], INPUT[name='trip_element[biz_supp_per_infant]']") ){
				onTripElementFieldChange.call(this,e);
			}
		});
		// The following equivalent code was slower becaue it required jQuery to check many names every time event was triggered.
		//	$( "SELECT[name='trip_element[supplier_id]'], INPUT[name='trip_element[adults]'], INPUT[name='trip_element[children]'], INPUT[name='trip_element[infants]'], INPUT[name='trip_element[cost_per_adult]'], INPUT[name='trip_element[cost_per_child]'], INPUT[name='trip_element[cost_per_infant]'], INPUT[name='trip_element[single_supp]'], INPUT[name='trip_element[exchange_rate]'], INPUT[name='trip_element[taxes]'], INPUT[name='trip_element[margin]'], SELECT[name='trip_element[margin_type]'], INPUT[name='trip_element[biz_supp_per_adult]'], INPUT[name='trip_element[biz_supp_per_child]'], INPUT[name='trip_element[biz_supp_per_infant]']" )
		//		.live( 'change keyup', onTripElementFieldChange )
		//	;

	}





// Update Trip Invoice amount when these fields change:
function initTripInvoiceFormTotals(){

	// Update Trip Invoice amount when these fields change:
	$( "INPUT[name='money_in[deposit]']" )
		.live( 'click keyup', onTripInvoiceFieldChange );

	$( "SELECT[name='money_in[name]']" )
		.live( 'change', onTripInvoiceTypeChange );

	triggerTripInvoiceFormChange();

}

	// Helper for refreshing fields after ajax loaded content:
	function triggerTripInvoiceFormChange(){

		// Update Trip Invoice amount when these fields change:
		$( "INPUT[name='money_in[deposit]']" ).trigger('keyup');
		$( "SELECT[name='money_in[name]']"   ).trigger('change');

	}

	// Called to update TripElement totals whenever user makes changes in TripElement form: (And each time it is loaded by ajax)
	function onTripInvoiceFieldChange(){

		// Cache field lists for better query performance:
		var $form	= $(this).parents("FORM:first");
		var $all	= $form.find("SELECT,INPUT,TEXTAREA,DIV");
		var $totals	= $all.filter(".total");						// Fields and DIVs with class of .total
		var $fields	= $all.filter("SELECT,INPUT,TEXTAREA");			// Form fields
		var $texts	= $fields.filter("INPUT:text");					// Textboxes only
		var $lists	= $fields.filter("SELECT");						// Dropdown lists only

		var total   = numVal("[name='money_in[total_amount]']",		$texts);
		var deposit = numVal("[name='money_in[deposit]']",	$texts);

		$texts.filter("[name='money_in[amount]']").val( total - deposit );

	}


	// Called to adjust Trip Invoice fields when user chooses main or supp invoice:
	function onTripInvoiceTypeChange(){

		var $form	= $(this).parents("FORM:first");
		var $all	= $form.find("SELECT,INPUT,TEXTAREA,DIV");
		var $totals	= $all.filter(".total");						// Fields and DIVs with class of .total
		var $fields	= $all.filter("SELECT,INPUT,TEXTAREA");			// Form fields
		var $texts	= $fields.filter("INPUT:text");					// Textboxes only
		var $deposit = $texts.filter( "[name='money_in[deposit]']" );
		var $amountLabels		= $form.find('DIV.invoice-amount-label');
		var $mainAmountLabel	= $amountLabels.filter('.for-main-invoice');
		var $suppAmountLabel	= $amountLabels.filter('.for-supp-invoice');
		var $creditAmountLabel	= $amountLabels.filter('.for-credit-invoice');
		
		var isMainInvoice = $(this).val() == '';
		var isCreditNote  = /\/C$/.test( $(this).val() );

		$texts.filter( "[name='money_in[deposit]']" ).attr( 'readonly', isMainInvoice ? null : 'readonly' );
		$texts.filter( "[name='money_in[amount]']"  ).attr( 'readonly', isMainInvoice ? 'readonly' : null );
		
		// Reset deposit amount for main invoice:
		if( isMainInvoice ){

			var defaultDeposit = numVal("[name='default_deposit']", $fields);

			// Show the deposit field:
			$deposit.val(defaultDeposit).cousins('>TD>*').fadeTo('slow',1);

			// Show the label for main invoice amount and hide the others:
			$mainAmountLabel.siblings().fadeOut('fast').end().delay('fast').fadeIn('fast');

		}else{

			// Hide the deposit field:
			$deposit.val(0).cousins('>TD>*').fadeTo('slow',0);

			if( isCreditNote ){
				// Show the label for supp invoice amount and hide the others:
				$creditAmountLabel.siblings().fadeOut('fast').end().delay('fast').fadeIn('fast');
			}else{
				// Show the label for credit invoice amount and hide the others:
				$suppAmountLabel.siblings().fadeOut('fast').end().delay('fast').fadeIn('fast');
			}

		}

	}













	var Client = {

		openNew : function(options){

			// We're intercepting a link so prevent the default ajax handler from loading it:
			if(options && options.event){ options.event.stopImmediatePropagation() }	// isImmediatePropagationStopped()

			var ui       = $('#pageTabs').tabs('url', /clients\/new/ );
			var orig_url = $.data(ui.tab,'load.tabs');
			
			$.data(ui.tab, 'load.tabs', options.url);
			$(ui.tabs).tabs('select', ui.index);
			$.data(ui.tab, 'load.tabs', orig_url);

		},

		// Prepare the client new/edit form:
		initForm : function(options){

			var target = options && ( options.panel || options.target );
			var client = getClientName(target);

			if( target ){
				// Select accordion's 2nd panel when form is for new client:
				var index = options.client_id ? 0 : 1;
				$( 'DL.accordion', target ).accordion({ autoHeight: false, active: index });
			}


			// Respond to user editing title, forename or surname:
			$("SELECT[name='client[title_id]']", target).bind('change keyup', onNameChanged);
			$("INPUT[name='client[forename]'], INPUT[name='client[name]']", target).bind('keyup', onNameChanged);

			// Flag user's direct edits of salutation and addressee:
			$("INPUT[name='client[salutation]'], INPUT[name='client[addressee]']", target).bind('change', function(){
				$(this).attr('data-edited',true);
			})
			// If the fields don't match their defaults then assume they've been set explicity so flag them to prevent overwite:
			.filter(function(){
				var $this = $(this);
				var default_val = $this.is("[name *= salutation]") ? client.default_salutation : client.default_addressee;
				return !!$this.val() && $this.val() != default_val;
			})
			.attr('data-edited',true);


			// Enable the address search on the postcode field(s):
			initPostcodeSearch(target)


			// Handler to update salutation ans addressee from title, forename and surname: (unless 'edited' flag is set)
			function onNameChanged(){

				var $this = $(this);

				if( $this.is('INPUT') ){
					var text = $this.val().replace(/\b([a-z])/g, function($0,$1){ return $1.toUpperCase() });
					$this.val(text);
				}

				var client = getClientName( $this.closest('FIELDSET') );

				client.salutation_field.not('[data-edited]').val(client.default_salutation);
				client.addressee_field .not('[data-edited]').val(client.default_addressee);

			}

			// Helper for reading values from client fields into a hash:
			// TODO: Can we make this into a generic method to read form fields into a hash?
			function getClientName(context){

				context = context || target || document;

				// Find the form fields:
				var client = {
					title_field      : $("SELECT[name='client[title_id]'] > OPTION:selected", context),
					forename_field   : $("INPUT[name='client[forename]']", context),
					surname_field    : $("INPUT[name='client[name]']", context),
					known_as_field   : $("INPUT[name='client[known_as]']", context),
					addressee_field  : $("INPUT[name='client[addressee]']", context),
					salutation_field : $("INPUT[name='client[salutation]']", context)
				};

				// Read the form field values too:
				$.extend( client, {
					title      : client.title_field.text() || '',
					surname    : client.surname_field.val() || '',
					forename   : client.forename_field.val() || '',
					known_as   : client.known_as_field.val() || '',
					addressee  : client.addressee_field.val() || '',
					salutation : client.salutation_field.val() || '',
					initial    : ( client.forename_field.val() || '' ).slice(0,1)
				});

				// Derive other values and return the result:
				return $.extend( client, {
					default_salutation : client.title + ' ' + client.surname,
					default_addressee  : client.title + ' ' + (client.initial ? client.initial + ' ' : '' ) + client.surname
				});

			}

		},

		// Helper to open a client tab:
		openShow : function(options){

			// TODO: Move show-client tab functionality to generic handler that runs after all responses.

			var matches		= options && options.matches;	// Result of livePath regex or submitted form.
			var form		= options && options.form;
			var $idField	= options && options.data && $(options.data).find('INPUT.show-client[name=client_id][value]');
			var $labelField	= $($idField).siblings('INPUT[name=client_label]').add( $($idField).parent().siblings().children('INPUT[name=client_label]') ).first();
			var id			= matches && matches[1] || form && form.client_id || $idField.val();
			var name		= matches && matches[2] ||                           $labelField.val() || 'Oops missing label!';

			if(id){

				var url		= Url('clients',id);
				var ui		= $('#pageTabs').tabs('url',url);

				// Select existing tab if already open:
				if( ui.tab ) {
					$('#pageTabs').tabs('select',ui.index);

				// Otherwise add a fresh tab:
				}else{

					// Workaround when spaces have been escaped as '+' in a link:
					// var label = name.replace(/\+/g,' ') + '<input type="hidden" value="{id}" class="client-id"/>'.replace('{id}',id);
					var label = name.replace(/\+/g,' ') + tag('input', null, { type:'hidden', value:id, 'class':'client-id' });
					$("#pageTabs").tabs('add', url, label);

				}

			}else{
				console.log( 'Unable to open client tab(', id, COMMA, name, ')', options );
			}

		},

		// Called when a client is opened:
		initShow : function(ui){

			// Derive tabs ui object if necessary:
			if( !ui.tab ){
				var options = ui,
					id  = options.form && options.form.client_id || options.matches[1],	// Result of livePath regex.
					url = 'clients/' + id;
					ui  = $('#pageTabs').tabs('url',url);
			}

			var context = ui.panel;

			// Init LHS tabs:
			$( 'UL:visible.clientPageTabsNav', context ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

				cache			: false,
				fx				: { opacity: 'toggle', duration: 100 },
				tabTemplate		: '<li class="trip trip-unconfirmed"><a href="#{href}">#{label}</a></li>',	// Only ever used after creating trip.
				panelTemplate	: '<div class="sectionBody ajaxPanel clientSubPageContainer"></div>',		// Only ever used after creating trip.
				panelsSelector	: function() { return this.list.cousins('.clientPageTabsContent > *') },	// This is a custom option. See modified ui.tabs.js script for details.

				add		: Tabs.select,		// When a new tab is added, open it immediately.
				load	: Tabs.onTabSuccess

			});

		}


	} // End of Client utilities.



	var Trip = {

		openShow : function(options){
		
			console.log(options)
			//alert(options)

		},

		// Called when a TRIP is opened:
		initShow : function(ui){

			// Ensure the new tripPageTabsContent element has an indentifier:
			var tabPanelContainerID = $( '.tripPageTabsContent', ui.panel || ui.target ).id();

			// Initialise the trip's tabs:
			$( 'UL.tripPageTabsNav', ui.panel ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

				cache			: false,
				panelTemplate	: '<div class="ajaxPanel sectionContainer noSectionHead"></div>',
				//panelTemplate	: '<div class="sectionBody ajaxPanel"></div>',	// This is the desired markup but will require changes to each tab-panel's sections and the css!
				panelsSelector	: function() { return this.list.cousins('#' + tabPanelContainerID + ' > *') },	// This is a custom option. See modified ui.tabs.js script for details.
				load			: Tabs.onTabSuccess

			});

		},

		// Called when TRIP EDIT tab is opened:
		initForm : function(ui){

			// Activate the country-tabs and trip_clients search box in this tab panel:
			Trip.initCountryTabs(ui.panel);

			// Reduce the effect of the CountryTabs FOUC by giving the browser a chance to render them before other changes:
			window.setTimeout(function(){
				initSpinboxes(ui.panel);
				initDatepickers(ui.panel);
				Trip.initClientSearch(ui.panel);
			},0);

		},

		// Called when TRIP BUILDER tab is opened:
		initTimeline : function(ui){

			// Build timeline overview (after allowing browser to calm down a little!):
			window.setTimeout(function() {

				$( 'DIV.timelineContent', ui.panel ).timelineOverview();

			}, TIMELINE_DELAY_BEFORE_GENERATE_OVERVIEW);


		},

		// Helper for initialising the country tabs on the trip form:
		initCountryTabs : function(panel){

			$( 'UL.countryTabs', panel ).parent().tabs({

				cache			: true, // Ensure ticked boxes are not discarded when user switches between country tabs!
				panelTemplate	: '<div class="countryTabsPanel"></div>',
				load			: function(e,ui){
					// Wrap all the loaded <li> tags in a <ul> element:
					$(ui.panel).children('LI').wrapAll('<ul class="checkboxList columns ellipsis"></ul>')
				}

			});

		},

		// Helper for initialising the autocomplete for adding clients on the trip edit page:
		initClientSearch : function(panel){

			$('INPUT.trip-client-search', panel).autocomplete("/search", {

				max					: CLIENT_SEARCH_MAX_ROWS,
				delay				: CLIENT_SEARCH_DELAY_BEFORE_AJAX,
				cacheLength			: 1,		// This simply allows the current results to stay in memory so double-click does not trigger re-search.
				minChars			: 3,
				matchContains		: false,
				matchSubset			: false,
				multiple			: false,
				multipleSeparator	: ",",
				dataType			: "json",
				scrollHeight		: 200,
				width				: 576,

				// Parse json as soon as it loads, to rearrange results as array of objects each with {data, value, result} attributes for autocompleter. More info: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
				// Generate html for each item in the json data: (json-object, row-index, number-of-rows, query-string)
				parse				: autocomplete_helpers.parseItems,
				formatItem			: autocomplete_helpers.formatItem

			})

			// Respond to user's choice by adding selected client to the list of travellers:
			.result(function(e, client) {

				var $table = $('TABLE.tripTravellers > TBODY', panel);

				if( $table.find("INPUT[value='" + client.id + "']").length === 0 ){

					// Eg: <tr><td><a href="/clients/{id}?label={label}" class="show clientName">{name}</a></td>...</tr>
					//var template = unescape( $table.find('>TR.template').clone().removeClass('hidden template').find(':disabled').removeAttr('disabled').end().outerHtml() );
					// TODO: Try the templating plugin instead.
					var template = $('#trip-traveller-row-template').html();
					var index	 = $table.children('TR').length;
					var html	 = interpolate( template, { id:client.id, name:client.shortname, label:client.shortname, index:index } );

					// Append the row to the table using an animation: (Note we animate the contents because table cells do not animate as expected)
 					$(html)
						.find('> TD > *').hide().end()
					.appendTo( $table )
						.find('> TD > *').slideDown();

				}

			});

		},

		onCreateSuccess : function(options){

			if(options && options.form && options.form.target){

				var $panel    = $(options.form.target);
				var $tabs     = $panel.parents('.clientPage, .tour').find('.ui-tabs:first');	// Context is a Tour or a Client.
				var trip_id   = options.form.trip_id || $panel.find('INPUT[name=trip_id]').val();
				var trip_name = $panel.find('INPUT[name=trip_name]').val() || 'New trip';
				var url       = options.form.path + '/' + trip_id;			// Eg: /clients/123/trips/{trip_id} or /tours/456/trips/{trip_id}
				var index     = options.form.tour_id ? 2 : 4;				// Choose tab position depending on whether trip is for Client or Tour.

				$tabs.tabs('add', url, trip_name, index);
				
				// TODO: Find out why we had to resort to a timeout to select the new tab!
				window.setTimeout( function(){ $tabs.tabs('select', index); }, 2000 );

			}

		},

		onUpdateSuccess : function(options){

			var form = options && options.form;

			// Derive the target element manually when form was submitted from the FLIGHTS GRID:
			// Eg: Trip page id "#clients123trips456" or "#tours123trips456"
			if( form && form.params && form.params.grid && form.path ){

				options.target = form.target = '#' + form.path.replace('/','','g');

				$(form.target).replaceWith(options.data);
				Trip.initShow(options);
				TripElement.closeGridDialog();
				
			}

			// Otherwise handle a normal trip update:
			else if( form && form.id && form.target ){

				var $panel   = $(form.target);
				var tripName = $panel.find("INPUT[name='trip[name]']").val();

				if(tripName){
					var $tabs = $panel.parents('.clientPage').find('.ui-tabs:first');
					var regex = new RegExp('/trips/' + form.trip_id);	// Eg: /\/trips\/1234/
					var ui    = $tabs.tabs('url',regex);
					$(ui.tab).text(tripName);	// TODO: This seems correct but UI is not changing!
				}

			}
		},

		onDestroySuccess : function(options){

			if(options){

				if( options.form && options.form.tour_id ){
					Tour.initShow(options)
				}else{
					Client.initShow(options)
				}

			}
		},

		// For finding another trip to copy elements from:
		showSearch : function(options){

			// We've intercepted a link so prevent default code from handling it:
			options.event.stopImmediatePropagation();

			// Re-use existing dialog or create new: 
			$('#trip-search-results').parents('.ui-dialog').add('<div>').first()
			.html('Opening...')
			.dialog({
				modal		: true,
				title		: icon('trip') + ' Find a trip to copy details from',
				minHeight	: 400,
				width		: 750,
				open		: function(e,ui){
					ui.panel = this;
					options.target = '#' + $(ui.panel).id();
					options.url = options.url
					Layout.load(options.url,options);
				},
				close		: function(e,ui){
					// Prevent odd effects later by removing dialog from DOM:
					$(this).remove();
				},
				buttons		: {
					'Close'				: function(){ $(this).dialog('close').remove() },
					'Copy from trip'	: function(){ $('FORM:last',this).submit() }	// First form is for searching the second (last) is to perform the copy.
				}
			});

		},

		showSearchResults : function(options){
			// Results will be loaded into #trip-search-results
		},

		// Handler to copy Gross Price pp from adjacent cell into the 'Set gross' textbox:
		// (This function is bound directly to the event handler so it receives an event object)
		copyGrossPrice : function(e){
			var price = parseFloat( $(this).closest('TR').find('.calculated-gross').text() || 0 );
			if( parseInt(price) != price ){ price += 1 }	// Ensure decimals will always ROUND-UP (add 1 because parseInt rounds down)
			$(this).closest('TD').find('INPUT[name *= price_per]').val( parseInt(price) );
			e.stopPropagation();
		}

	} // End of Trip utilities.



	var TripElement = {

		hideForm : function(options){

			var selector  = ".tripPage[id $= trips{id}]".replace('{id}', options.trip_id);
			var $tripPage = $(selector);
			var $target   = $tripPage.find('.tripElementFormContainer');

			$target.animate({ height: 'hide', opacity: 0 }, 'fast');

		},

		showForm : function(options){

			var selector  = ".tripPage[id $= trips{id}]".replace('{id}', options.trip_id || ( options.form && options.form.trip_id ) );
			var $tripPage = $(selector);
			var $target   = $tripPage.find('.tripElementFormContainer');

			// Add form to page but hide it while initialising elements:
			$target.hide().html(options.data);

			$target.animate({ height:'show', opacity:1 }, 'fast');

		},

		initForm : function(options){

			var selector  = ".tripPage[id $= trips{id}]".replace('{id}', options.trip_id || ( options.form && options.form.trip_id ) );
			var $tripPage = $(selector);
			var $target   = $tripPage.find('.tripElementFormContainer');

			initSpinboxes($target);
			initDatepickers($target);
			$target.find("[name='trip_element[supplier_id]']").trigger('change');	// Refresh calculated fields.

		},

		openGrid : function(options){

			// We've intercepted a link so prevent default code from handling it:
			options.event.stopImmediatePropagation();

			// Re-use existing dialog or create new: 
			$('#trip-elements-grid').closest('.ui-dialog-content').add('<div>').first()
				.html('Opening...')
				.dialog({
					modal		: true,
					title		: icon('grid') + ' Quickie trip builder',
					minHeight	: 450,
					maxHeight	: 450,
					width		: 950,
					open		: function(e,ui){
						ui.panel = this;
						options.target = '#' + $(ui.panel).id();
						options.url = options.url + '?limit=100'
						Layout.load(options.url,options);
					},
					close		: function(e,ui){
						// Prevent odd effects later by removing dialog from DOM:
						$(this).remove();
					},
					buttons		: {
						'Cancel'		: function(){ console.log(this,$(this)); TripElement.closeGridDialog() },
						'Save changes'	: function(){ $('FORM:last',this).submit() }
					}
				})
			;
		},

		closeGridDialog : function(){
			$('#trip-elements-grid').closest('.ui-dialog-content').dialog('close');
		},

		initGrid : function(options){

			// This works but we must also apply datepickers whenever rows are added dynamically:
			initDatepickers(options.target);

		}


	} // End of TripElement utilities.
	



	// Note: Tours are known as Groups in the UI.
	var Tour = {

		// Parse the tour id and name from the data, then trigger method to show the tab:
		onCreateSuccess : function(options,data){

			data = data || options.data;
			var ui = $('#pageTabs').tabs('url', /tours\/new/);
			var $data = $(data),
				tour_id   = $data.find('#tour_id').val(),
				tour_name = $data.find('#tour_label, #tour_name').val();
				ui.url    = '/tours/' + tour_id;

			Layout.onSuccess( data, 'success', undefined, ui, options.event )

		},

		// Helper to open a tour tab:
		openShow : function(options){

			// We're intercepting a link so prevent the default ajax handler from loading it:
			if(options && options.event){ options.event.stopImmediatePropagation() }	// isImmediatePropagationStopped()

			var id   = options.matches[1],							// Result of livePath regex.
			    name = options.matches[2] || 'Oops missing label!',	// Result of livePath regex.
				url  = 'tours/' + id,
				ui   = $('#pageTabs').tabs('url',url);

			// Select existing tab if already open:
			if( id && ui.tab ) {
				$('#pageTabs').tabs('select',ui.index);

			// Otherwise add a fresh tab:
			}else if(id){

				// Workaround when spaces have been escaped as '+' in a link:
				name = name.replace( /\+/g,' ');
				var label = name + '<input type="hidden" value="{id}" class="tour-id"/>'.replace('{id}',id);
				$("#pageTabs").tabs('add', url, label);

			}else{
				console.log( 'Unable to open tour tab(', id, COMMA, name, ')' );
			}

		},

		initShow : function(options){

			var id  = options.form && options.form.tour_id || options.matches[1],	// Result of livePath regex.
				url = 'tours/' + id,
				ui  = $('#pageTabs').tabs('url',url);

			if( ui.tab ) {

				var context = ui.panel;

				$( 'UL.ui-tabs-nav-vertical', context ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

					selected		: 2,	// Default to open the latest tour-dates.
					cache			: false,
					fx				: { opacity: 'toggle', duration: 100 },
					tabTemplate		: '<li class="trip trip-unconfirmed"><a href="#{href}">#{label}</a></li>',	// Only ever used after creating trip.
					panelTemplate	: '<div class="sectionBody ajaxPanel clientSubPageContainer"></div>',		// Only ever used after creating trip.
					panelsSelector	: function() { return this.list.cousins('.clientPageTabsContent > *') },	// This is a custom option. See modified ui.tabs.js script for details.

					//show	: function(e,ui){ $(ui.panel).html('Loading...') },

					// When a new tab is added, open it immediately:
					// TODO: This is being called but is not selecting the tab.
					add		: Tabs.select,
					load	: Tabs.onTabSuccess

				});

			}else{
				$('#pageTabs').tabs('add',url,'label')
			}

		},

		// Simply close a Tour tab:
		closeShow : function(options){

			var id  = options.form && options.form.tour_id || options.matches[1];	// Result of livePath regex.

			if(id){ $('#pageTabs').tabs('remove', '/tours/'+id) }

		},

		// Open the Tours list tab: (Groups)
		openIndex : function(options){

			// Trigger the tab-select method:
			$('#pageTabs').tabs('select', '/tours');

			// Cache the latest list of tour names to speed up search-as-you-type:
			var $tourItems = $( "DT:has(A.tour-name)", options.panel );
			var timer;

			// Respond to typing in Quick Search textbox to search-as-you-type:
			// (Room for some performance improvement here but it is satisfactory)
			$( '#tour_quick_search', options.panel ).trigger('focus').bind('keyup', function(e){

				if( timer ){
					console.log( window.clearTimeout(timer) )
					timer = null;
				}
				var text = $(this).val().toLowerCase();
				
				timer = window.setTimeout( function(){ filterGroups(text) }, 100 );
			});

			function filterGroups(query){

				// Unhide previously hidden items and hide those that match search text:
				$tourItems.filter(":hidden").show().next("DD").show().end().end()
					.filter(function(){ return $(this).text().toLowerCase().indexOf(query) == -1; })
					.filter(":visible")
					.hide().next("DD").hide();

			}

		},

		// Close the New Tour tab:
		closeNew : function(options){
			$('#pageTabs').tabs('remove', '/tours/new');
		}

	} // End of Tour methods.



	var Report = {

		initForm : function(options){

			$( 'UL:visible.reportTabsNav', options.target ).parent().tabs({	// (See http://jqueryui.com/demos/tabs)

				selected		: 1,
				panelTemplate	: '<div class="sectionBody ajaxPanel"></div>',
				load			: Tabs.onTabSuccess

			});

		}

	} // End of Report utilities.



	var SysAdmin = {
	
		initShow : function(ui){

			$( 'UL.sysAdminTabsNav', ui.panel ).parent().tabs({

				fx				: { opacity: 'toggle', duration: 200 },
				panelTemplate	: '<div class="sectionBody ajaxPanel"></div>',
				panelsSelector	: function() { return $('#sysAdminTabsContent > *') },	// This is a custom option. See modified ui.tabs.js script for details.

				load : Tabs.onTabSuccess

			});

		},

		refreshIndex : function(ui){

			// Set the focus on the filter-button that represents the currently applied index_filter param:
			var index_filter_label = $(ui.target).find("[name=index_filter_label]").val();

			$(".filter-button")
				//.removeClass("ui-state-default")
				.filter(":contains('" + index_filter_label + "')")
					//.addClass("ui-state-default")
					.focus();

		}

	} // End of SysAdmin methods.



	var Autotext = {

		// Populate the list of countries from the ajax response filtered by company:
		showCountries : function(options){
			$(options.target).html(options.data)
		},

		showAutotexts : function(options){
		
		
		}

	}


	var Task = {

		openNew : function(options){

			// We've intercepted a link so prevent default code from handling it:
			options.event.stopImmediatePropagation();

			$('<div>').html('Opening...').dialog({
				//autoOpen: false,
				title		: icon('clock') + ' New followup',
				minHeight	: 300,
				width		: 550,
				open		: function(e,ui){
					ui.panel = this;
					options.target = '#' + $(ui.panel).id();
					Layout.load(options.url,options)
				},
				buttons		: {
					'Cancel'				: function(){ $(this).dialog('close').remove() },
					'Save my new reminder'	: function(){ $('FORM',this).submit() }
				}
			});

		},
	
		openEdit : function(options){

			// We've intercepted a link so prevent default code from handling it:
			options.event.stopImmediatePropagation();

			var $dialog = $('<div>').html('Opening...').dialog({
				//autoOpen: false,
				modal		: true,
				title		: 'Modify followup',
				minHeight	: 320,
				width		: 550,
				open		: function(e,ui){
					options.target = '#' + $(this).id();
					Layout.load(options.url,options)
				},
				buttons		: {
					'Cancel'			: function(){ $(this).dialog('close').remove() },
					'Save my changes'	: function(){ $('FORM',this).submit() }
				}
			});

		},
		
		initIndex : function(ui){
			// unused
			console.log(ui)
		},
		
		initForm : function(ui){

			$("SELECT[name='task[status_id]']").change(Task.toggleClosedTaskFields).trigger('change');

		},

		// Helper for reacting to selection in the task[status_id] field:
		toggleClosedTaskFields : function(){

			var $closed_fields = $(this).closest('FORM').find("[name ^= 'task[closed_']");

			if( $(this).val() == TASK_STATUS_OPEN ){
				$closed_fields.attr('disabled','disabled').parent('.formField').slideUp();	// Important: Disabled fields will not be submitted.
			}else{
				$closed_fields.removeAttr('disabled').parent('.formField').slideDown();
			}

		},

		onCreateSuccess : function(ui){

			// Close all dialogs: (TODO: Can we be more specific?!)
			$('DIV.ui-dialog-content').dialog('close').remove();

			if(ui && ui.form && ui.form.client_id){

				// Refresh the list of the client's tasks:
				ui.url		= Url('clients', ui.form.client_id, 'tasks');	// Eg: "/clients/1234/tasks"
				ui.target	= '#' + ui.url.replace('/','','g');				// Eg: "#clients1234tasks"

				// No need to use Layout.load(ui.url,ui) here, just go ahead and refresh the content;
				$(ui.target).load(ui.url);				// Reload client's custom list of tasks.
				$("#user-followups").load('/tasks');	// Reload user's custom list of tasks on the home page.

			}
		}

	};




	var WebRequest = {
	
		openShow : function(options){

			// We've intercepted a link so prevent default code from handling it:
			options.event.stopImmediatePropagation();

			var $dialog = $('<div>').html('Opening...').dialog({

				modal		: true,
				title		: 'Geeky Web Request data',
				minHeight	: 300,
				maxHeight	: 300,
				minWidth	: 600,
				maxWidth	: 700,
				open		: function(e,ui){
					$(this).css({'max-height': 300}); 
					options.target = '#' + $(this).id();
					Layout.load(options.url,options)
				},
				buttons		: {
					'Close'	: function(){ $(this).dialog('close').remove() }
				}
			});

		}

	};


	var MoneyIn = {
	
		initForm : function(options){

			// Ensure form displays correct label next to the amount textbox: (Context dependent on Main/Supp/Credit)
			$(options.panel || options.target).find( "SELECT[name='money_in[name]']" ).trigger('change');

		}
	
	};


	var Document = {

		// For listing TEMPLATE filenames in a picklist:
		list : function(options){
	
			console.log( 'Fetching list of doc templates', options.params, $(options.target), options )

		}

	};



	var BoundFields = {

		// Helper to apply any new field values to other elements bound to the same field:
		// Fields are identified by custom data-resource and data-field attributes.
		// Any "INPUT[data-resource][data-field]" in the loaded html is assumed to be a source of data.
		// Any "[data-bound][data-resource][data-field]" on the page is assumed to be bound to the data (if resource & field match source).
		update : function(ui){

			var $updates = $( ui.panel || ui.target ).find("INPUT[data-resource][data-field]");

			if( $updates.length ){

				// Locate all the bound elements on the page: (Potentially SLOW!)
				var $candidates  = $("SPAN,INPUT").filter("[data-bound]");

				// Update all fields bound to the updated data:
				$updates.each(function(){

					var $this    = $(this);
					var resource = $this.attr('data-resource');
					var field    = $this.attr('data-field');
					var value    = $this.val();
					var selector = "[data-resource='{r}'][data-field='{f}']".replace("{r}",resource).replace("{f}",field);

					$candidates.filter(selector).not(this)
						.not('INPUT,TEXTAREA').text(value).end()	// Set bound text elements.
						.filter('INPUT,TEXTAREA').val(value);		// Set bound value elements.

				});

			}

		}

	};







// Helper for assembling a url from several arguments: (Eg: Url('clients',client_id,'tasks') => "/clients/1234/tasks")
function Url(path){
	return '/' + Array.prototype.slice.call(arguments).join('/');
}

// Helper for generating the markup required for a standard icon:
// TODO: Refactor using html template?
function icon(name){
	return '<span class="ui-icon ui-icon-{name}"></span>'.replace('{name}',name,'g');
}


// Helper to parse details from a url and return an object hash similar to the window.location object:
function parseUrl(url) {

	//url = "/clients/2/trips/3/edit?label=Mrs+K+Adamson#bookmark"
	// regex info: /(path  ) ? (params)  #(bookmark)
	var matches  = /([^\?#]*)\??([^\#]*)\#?(.*)/.exec(url),
		location = { params:{length:0}, resource:{length:0} };

	if (matches.length) {

		// These attributes are named to be consistent with the window.location object!
		location.pathname	= matches[1];	// Eg: /clients/1/trips/2/edit
		location.search		= matches[2];	// Eg: name=Smith&date=20090102 (whatever follows the question mark)
		location.hash		= matches[3];	// Eg: #bookmark (whatever follows the hash mark)

		// Copy all the url params to a location.params object:
		location.params = keyValPairs(location.search.split("&"), location.params, "=");

		// Extract each "/controller/id" pair from nested pathname:
		// We also provide a function to trim off training "s" or swap "ies" to "y" on each controller name (remove pluralisation, eg countries ==> country)
		// Regex uses Positive Lookahead to split on alternate "/" characters. See http://msdn.microsoft.com/en-us/library/1400241x%28VS.85%29.aspx
		keyValPairs( location.pathname.split(/\/(?=[^\/]+\/[0-9]+)/),
			location.resource, "/",
			// Callback for each key in the controllerName/id pairs:
			function(controllerName, id) {
				// Attempt to singularise the plural controller names!
				return controllerName.replace(/ies$/, "y").replace(/s$/, "");
			}
		);

		// If there's a "/action" on the end of the path then get that too!
		location.action = (/\/([^0-9]+)$/.exec(location.pathname) || ["", ""])[1];

	};

	return location;


	// Helper for converting an ARRAY of "key=value" string pairs into an object hash:
	// Optional keyFn and valFn callbacks can be used to alter the strings in some way. They receive arguments: key, value, index, originalArray, keyArray, valArray, hashBuiltSoFar.
	function keyValPairs(arr, obj, sep, keyFn, valFn) {

		sep = sep === undefined ? "=" : sep;
		obj = obj || {};
		obj.length = obj.length || 0;
		var keyArr = [], valArr = [];

		for (var i in arr) {
			var pair = arr[i].split(sep),
					key = !keyFn ? pair[0] : keyFn( pair[0], pair[1], i, arr, keyArr, valArr, obj ),
					val = !valFn ? pair[1] : valFn( pair[1], pair[1], i, arr, keyArr, valArr, obj ) || "";
			keyArr.push(key);
			valArr.push(val);
			if (key.length) { // Skip blank keys
				obj[key] = obj[i] = obj.last = val;
				obj.length++;
			};
		};
		return obj;
	};
};



// Helper function to generate html syntax for an html tag:
// Specify attrs as an object hash of name:value pairs.
function tag(name, contents, attrs) {

	// Make it a self-closing tag when contents undefined.
	// Otherwise open/close tags either side of contents:
	return (contents === null || contents === undefined)
			? '<' + name + html_attributes(attrs) + '/>'
			: '<' + name + html_attributes(attrs) + '>' + contents + '</' + name + '>';

	function html_attributes(attrs) {
		if(!attrs){ return '' }
		var arr = [];
		$.each(attrs, function(name,val) { arr.push(name + '="' + val + '"') });
		return ' ' + arr.join(' ');
	}
};


// A better alternative to Math.round(num) that lets you choose the number of dp to round to:
function round(num, dp) {
	dp = (dp === undefined) ? 2 : Math.max(dp, 0);
	var multiplier = Math.pow(10, dp) || 1;
	result = (Math.round(num * multiplier) / multiplier) + '';
	var beforeDp = result.split('.')[0];
	var afterDp = result.split('.')[1] || '';
	var zeros = new Array(dp - afterDp.length + 1).join('0');
	return beforeDp + '.' + afterDp + zeros;
};


// Helper for escaping html code:
function escapeHTML(html){

	return html
		.replace('&','&amp;')
		.replace('<','&lt;')
		.replace('>','&gt;')
		.replace('"','&quot;')
		.replace("'",'&apos;');

}


// Private helper for ensuring .val() returns a usable number from a form element:
function numVal(selector, $fields, defaultAlternative) {
	//return parseFloat( $($fields).find(selector).andSelf().filter(selector).val() ) || defaultAlternative || 0;
	return parseFloat( $fields.filter(selector).val() ) || defaultAlternative || 0;
};


// QUnit testing://$.getScript('/javascripts/testing/qunit.js', function(){//	$.getScript('/javascripts/testing/test-specs.js')//});
	// Initialise all our custom Layout event handling:
	Layout.init();
	// Intercept accidental attempts to use the BACK BUTTONS etc:	// Note: We only intercept page-unload when there are client tabs open. That way testing individual controller pages is not annoying!	// TODO: Allow use of back buttons by adding to the browser history while user navigates around the tabs.	window.onbeforeunload = function(e){		// Derive file extension of clicked link if applicable: (Eg 'doc', 'pdf')		var elem = e.target.activeElement;		var href = !!elem && elem.href || '';		var file_extension = href.split(/#|\?/).shift().split('.').pop();	// Get text between the last dot and the first # or ?, if any.		if( $('#pageTabsNav > LI').length > 1 && !DOWNLOADABLE_EXT[file_extension] ){			return "- Tip: If you are simply trying to reload the page then press OK to continue.\n\n" +				"- More info:\n This site is more like an application than an ordinary web page, so " +				"using your browser's back and forward buttons will not navigate you around this application."		}	};});	// End of jQuery ready handler.