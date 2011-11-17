
// Actions will only be logged if window.MCV_LOGGING_ENABLED is true.


(function($){

	if(!window.console) window.console = {}; if(!console.log) console.log = function(){};
	var undefined;

	$.fn.extend({

		Model	: function(options){

			// Assume defaults for any options not specified:
			options = $.extend( {}, $.fn.Model.defaults, options );

			// Convert each action definition into a caller method and copy the options onto it as attributes:
			// Eg: Options.create.caller() becomes Model.create() and Options.create.action becomes Model.create.action.
			// This might seem odd but it makes the options syntax simpler to specify then simpler to use.
			$.each('create update delete get all'.split(' '), function(i,actionName){
				var actionOpts		= options[actionName];
				options[actionName]	= options[actionName].caller;
				options[actionName].name = actionName;		// Can be helpful for a callback to find out which action it is dealing with.
				$.each('action method params dataType callback'.split(' '),function(i,attr){ options[actionName][attr] = actionOpts[attr]; });
			});
			var Model = $.extend({}, this, options);

			//Model.get(3);
			return Model;
		},



		View : function(options){

			if( options && typeof(options)=='String' && options=='destroy' )
				return this.find('*').andSelf().unbind('.mvc').die('.mvc').removeData('mvcGetDataFld').removeData('mvcOldVal');

			// Assume defaults for any options not specified: (And convert options.live string to a hash for easier lookup)
			options  = $.extend( {}, $.fn.View.defaults, options );
			var View = $.extend( {}, this, options, { live : Hash.make( options.live.split(" "), "live" ) } );

			// Define handy new mvcDataFld() jQuery method for fetching dataFld and a selector for finding elements matching dataFld:
			// Usage: var dataFldName = $("INPUT").mvcDataFld();
			if( !$.fn.mvcDataFld ) $.fn.extend({
				mvcDataFld : function(){
					var getDataFld = $(this).data("mvcGetDataFld") || View.getDataFld;
					return $.isFunction(getDataFld) ? getDataFld.apply(this,[this]) : false;
				}
			});
			// Usage: var $postcodeFields = $("INPUT:mvcDataFld(client[postcode])");
			// Usage: var $boundFields = $("INPUT:mvcDataFld()");
			if( !$.expr[':'].mvcDataFld ) $.extend( $.expr[':'], {
				mvcDataFld : function(elem,i,match) {
					return match[3] ? $(elem).mvcDataFld() == match[3] : $(elem).mvcDataFld();
				}
			});

			// HELPERS: View.getterFor() & View.setterFor(): Given a UI element, return 1st getter/setter function we find for specified event name:
			// Usage: var getter = View.getterFor(element,"click");
			$.each(['getter','setter'], function(i,xetter){

				View[xetter+'For'] = function(elem,eventType){
					var result; eventType = (eventType||"").toLowerCase();
					$.each( View[xetter+'s'], function(selector,handlers){
						return !( $(elem).is(selector) && ( result = eventType ? handlers[eventType] : Hash.nth(handlers,0) ) );
					});
					return result;
				};

			});


			// Derive elements selector from the list of getters and setters and use it to find elements to bind:
			$.each( View.getters, function(selector){ View.getterSelectors.push(selector); } );
			$.each( View.setters, function(selector){ View.setterSelectors.push(selector); } );
			var getters		= View.getterSelectors.join(",");
			var $allFields	= View.find(getters).add( View.filter(getters) );
			$allFields.data( "mvcGetDataFld", View.getDataFld );	// This provides a reference to the getDataFld() function for use by our custom .mvcDataFld() method and :mvcDataFld() selector.

			// Bind all getter handlers so the view can respond to user input: TODO: Init "mvcOldVal" data.
			$.each( View.getters, function(selector,events){
				$fields = $allFields.filter(selector); log($fields.length, selector); 
				$.each(events, function(eventType){ View.bindField( $fields, eventType ) });
			});


			// Attempt some housekeeping:
			this.bind( 'unload.mvc', function(){ $(this).View('destroy') } )


			return View;
		},



		Controller	: function(Model, View, options){

			// Assume defaults for any options not specified:
			options = $.extend( {}, $.fn.Controller.defaults, options );
			var Controller = $.extend({}, this, options);

			View.id				= 1;
			View.idField		= "client[id]";
			Model.controller	= "client"	// Name of server-side controller to post updates to etc.

			// Copy the Model's field values to the View:
			Model.addListener( function(fields){
				Controller.copy(fields).from(Model).to(View);
			});

			// Copy the View's field values to the Model:
			View.addListener( function(fields){
				Controller.copy(fields).from(View).to(Model);
			});

			// Derive full-name field from others: (Changes to any of these fields will trigger callback)
			View.addListener("client[title], client[forename], client[surname]", function(fields){
				var model = Controller.copy(fields).from(View).to(Model);
				model.name = [ model.title||"", model.forename||"", model.surname||"" ].join(" ");
				var view = Controller.toViewField(model,"client[$1]");
				View.update(view);
			});

			// Initialise model from View:
			Controller.copy( View.get() ).from(View).to(Model);
			View.update();

		}

	});




	// Define DEFAULTS for the MODEL options:
	$.extend($.fn.Model, {
		version	: '0.1',
		defaults: {

			isModel	: true,
			controller	: "countries",
			urlPrefix	: "/jquery.mvc/",	//"http://10.0.0.101:4000/",	// URL root

			// Model.create() (AKA New)
			'create': {
				action	: "{controller}",
				method	: "post",
				params	: { _method:"post" },
				caller	: function(fields){
					var Model = this;
					Model.cache["NEW"] = fields;
				}
			},

			// Model.update() (AKA Modify)
			'update': {
				action	: "{controller}/{id}",
				method	: "post",
				params	: { _method:"put" },
				caller	: function(fields){	// Updates cache with any fields specified in fields hash. One of them must be the row id!

					var Model = this, id = fields[Model.idField], row = Model.cache[id];
					if(id) row ? $.extend(Model.cache[id],fields) : Model.cache[id] = fields;
					
					if( !Model.waitForCommit )
						Model.ajaxRequest( "UPDATE", id );
					
					return !!id;
				}
			},

			// Model.delete() (AKA Destroy)
			'delete': {
				action	: "{controller}",
				method	: "post",
				params	: { _method:"delete" },
				caller	: function(id){}
			},

			// Model.get() (AKA Show) Returns hash of fields if already loaded, Otherwise they will be fetched by ajax.
			'get': {
				action	: "{controller}/{id}.json",
				method	: "get",
				dataType: "json",
				caller	: function(id){

					var Model = this, row = Model.cache[id];

					if( row )
						Model.notifyCallback( Model.get.callback, row );
					else
						Model.ajaxRequest( "GET", id );

					return row;
				},
				callback: function(row){
					var Model = this, id = row[Model.idField]; if(id) Model.cache[id] = row;
				}
			},

			// Model.all() (AKA Index, List) Returns an ARRAY of ids of rows already loaded. Remainder will be fetched by ajax.
			'all': {
				action	: "{controller}/all.json",
				method	: "get",
				dataType: "json",
				caller	: function(ids){

					var Model = this; ids = $.makeArray(ids);
					var cachedIDs = $.grep( ids, function(id){ return Model.cache[id] });

					if( cachedIDs.length == ids.length )
						Model.notifyCallback( Model.all.callback, cachedIDs );
					else
						Model.ajaxRequest( "ALL", ids );

					return loadedIDs;
				},
				callback: function(rows){
					var Model = this;
					$.each(rows, function(i,row){
						var id = row[Model.idField]; if(id) Model.cache[id] = row;
					});
				}
			},

			cache		: {},	// Will be a hash like: { 5:{ id:5,surname:"Smith",forename:"John",title:"Mr" }, 8:{ id:8, ... } }
			idField		: "id",	// Name of the unique ID field in each data row.
			metadata	: {},	// TBA

			waitForCommit	: true,

			// Send AJAX request to server:
			ajaxRequest	: function(action,ids){

				// Get references to the Model and it's settings for the desired action: (Model.get, Model.create etc)
				var Model = this, action = Model[action.toLowerCase()]; ids=$.makeArray(ids);
				var url = interpolate( Model.urlPrefix + action.action, { controller:Model.controller, id:ids[0] } );
				log("url:",url);

				$.ajax({
					url		: url,
					data	: action.params,
					dataType: (action.dataType || "json").toLowerCase(),
					type	: (action.method   || "GET" ).toUpperCase(),
					success	: function(response,status){
						var data = Model.loadResponse(response);
						$.each( data.rows, function(id,row){
							Model.notifyListeners(id, row, data.updatedRows[id]);
						});
					}
				});
				
				return true;
			},

			// Load AJAX response data into cache: (And identify rows that are new or different to cached rows)
			loadResponse	: function(data){
				var Model = this, oldRow, rows = {}, updatedRows = {};
				$.each( $.makeArray(data), function(i,newRow){
					var id = newRow[Model.idField], oldRow = Model.cache[id]; rows[id] = newRow;
					if( !oldRow || oldRow!=newRow ) Model.cache[id] = updatedRows[id] = newRow;
				});
				return { rows:rows, updatedRows:updatedRows };
			},

			// Common code used for triggering an ajax callback asyncronously:
			notifyCallback	: function(callback,data){
				window.setTimeout( function(){
					callback = callback || $.ajaxSettings.success;
					if(callback) callback(data);
				}, 0 );
			},

			// Trigger View.listeners callbacks, passing a hash of fields represnting the modified row:
			notifyListeners	: function(id, row, oldRow){
				var Model = this;
				$.each( Model.listeners, function(i,listener){
					listener.apply( Model, [row, oldRow, id] );
				});
			},

			// Add a listener callback to the list of View.listeners:
			addListener		: function(type,listener){  
				if( !listener ){ listener = type; type = "*" };	// type is optional. Defaults to ANY ("*").
				var Model = this;
				Model.listeners.push(listener);  
			},

			// Array of Model listener callback functions:
			listeners		: []
		}
	});



	// Define default options for the VIEW:
	$.extend($.fn.View, {
		version	: '0.1',
		defaults: {

			isView	: true,

			// Bunch of selectors for finding elements to bind to, and the events to respond to:
			// Tip: Place more specific selectors above more general selectors for the same type of element. Eg "SELECT[multiple]" before "SELECT".
			getters	: {
				"SELECT, INPUT:text"			: { change : function(e){ return $(this).val(); }, keyup : function(e){ return $(this).val(); } },
				"INPUT:radio, INPUT:checkbox"	: { click  : function(e){ return $(this).val(); } }
			},

			// Bunch of selectors for finding elements to set whenever the data changes:
			// Tip: Place more specific selectors above more general selectors for the same type of element. Eg "SELECT[multiple]" before "SELECT".
			// Warning: values is an array of 1 or more values so try values.toString() if you're getting an error using .text(values) etc.
			setters	: {
				"SELECT, TEXTAREA, INPUT:text, INPUT:radio, INPUT:checkbox"	: function(dataFld,value){ $(this).val(value); },
				"DIV, SPAN, P, H1, H2, H3, H4" : function(dataFld,value){ $(this).text(value.join()); }
			},

			// Name of the unique ID field on the page: Must be set by your Controller!
			id			: 0,
			idField		: "modelname[id]",
			newId		: "NEW",

			// Work in progress. Rather clunky. Must be a better way.
			deriveIdField	: function(idRegex,fieldTemplate,View){
				View			= View || this;
				idRegex			= idRegex || /(.*)\[id\]/;			// Like "modelname[id]"
				idPattern		= { regex: /(.*\[).*(\])/, template: "$1id$2" };
				var $form		= View.parents().andSelf().filter("FORM"), idField;				
				var $fields		= $form.find("*").andSelf().filter(":mvcDataFld");
				idField			= $fields.filter(function(){ return idRegex.test( $(this).mvcDataFld() ) }).mvcDataFld()
								|| $fields.mvcDataFld().replace( idPattern.regex, idPattern.template )
								|| ""

				return {
					name	: idField,
					value	: $fields.filter( ":mvcDataFld(" + idField + ")" ).val()
							|| $form.attr("action").replace( /.*\/(.*)/, "$1" )
							|| ""
				}
			},

			// Each listener can be a function or an array of functions:
			listeners	: {},
			
			addListener	: function(fields,listener){  
				View = this; if( !listener ){ listener = fields; fields = "*" };	// fields argument is OPTIONAL and defaults to "*".
				$.each( fields.split(","), function(i,field){						// Allow for comma separated list of fieldnames.
					View.listeners[ $.trim(field) ] = listener;
					listener.fields = fields.split(",");
				});
				return View;
			},

			//controllerName: function(){ $(this).mvcDataFld().split("[").shift(); },
			//fieldName		: function(){ $(this).mvcDataFld().split("]").shift().split("[").pop(); },
			//fieldUid		: function(){ $(this).parents().andSelf().filter("FORM").attr("action").split("/").pop(); },

			// Read dataFld attribute from an element. Usually just value of dataFld attribute but hey, you can do it your way:
			getDataFld	: function(elem){ return $(elem).attr("name"); },

			// Find out whether element expects to be bound to the specified dataFld:
			hasDataFld	: function(elem,dataFld){ return $(elem).filter(function(){ return $(this).attr("name")==dataFld }).length },

			// When false, we trigger listeners at every opportunity, even if user triggered event but didn't actually change the value:
			ignoreUnchanged	: true,

			// Array of selectors for finding elements to bind to. All view.getters and view.setters will be added to this too!
			getterSelectors		: [],
			setterSelectors		: [],

			//getterFor			: null,
			//setterFor			: null,

			// Which events can be bound using jQuery's live() method? (Space separated list of event names)
			live		: "click dblclick mousedown mouseup mousemove mouseover mouseout keydown keypress keyup",	// also possible: "keydown keypress keyup"

			// HELPER to bind element(s) to handler to react to user input: (Also decides whether to use jQuery bind() or live() method)
			bindField	: function(elem,eventType){
				var View = this, bind = View.live[eventType] || "bind";
				$(elem)[bind]( eventType+".mvc", function(event){
					View.onFieldChanged(this,event);
				});
			},

			// Generic HANDLER called whenever user makes a change in the UI:
			// The itemId argument is optional for future use!
			onFieldChanged	: function(elem, event, itemId){

				var View	= this;
				var getter	= View.getterFor( elem, event.type );
				var dataFld = $(elem).mvcDataFld();
				var oldVal	= $(elem).data("mvcOldVal") || "";
				var newVal	= getter.apply(elem,[event]); if( $.isArray(newVal) ) newVal = newVal.join(",");

				log("before update:",dataFld, "newVal:", newVal, "oldVal:", oldVal, "val:", $(elem).val() )
				if( newVal != oldVal || !View.ignoreUnchanged ){
					var fields = {}; fields[dataFld] = newVal;
					var oldFields = {}; oldFields[dataFld] = oldVal;
					fields[View.idField] = oldFields[View.idField] = ( itemId || View.id );
					View.update(fields, elem);
					View.notifyListeners(fields, oldFields, elem);
					$(elem).data("mvcOldVal", newVal);
				}
			},

			// Relay a change from the View to the Controller: (Allow one or an array of listeners for each dataFld)
			// The fields and oldFields arguments must each be a hash of name:value pairs.
			notifyListeners	: function(fields, oldFields, elem){
				var View = this;
				$.each(fields||{}, function(dataFld,value){
					var listeners = $.makeArray( View.listeners[dataFld] );
					if( View.listeners["*"] ) listeners.push( View.listeners["*"] );
					$.each(listeners, function(i,listener){
						listener.apply( elem, [fields, oldFields] );
					});
				});
			},

			// Return a hash of field values from the UI:
			get		: function(){

				// Copy all UI field values into an object hash:
				var View = this, fields = {};
				this.find("*").andSelf().filter(":mvcDataFld").each(function(){
					var getter	= View.getterFor(this);
					if(getter){
						var dataFld = $(this).mvcDataFld();
						fields[dataFld] = getter.apply(this);
					};
				});

				// Ensure hash includes an id field:
				if( !fields[View.idField] ) fields[View.idField] = View.id || View.newId;
				return fields;
			},

			// Update the UI with new values passed from controller: (source is used internally to prevent us triggering events on the element that caused the change!)
			// Currently only accepts {dataFld:value} as fields argument.
			update	: function(fields, source){

				// Bail out if no fields specified. Just refresh UI by triggering all View.listeners:
				var View = this;
				if( !fields ) return this.notifyListeners( View.get() );

				var $fields = View.find( View.setterSelectors.join(",") ).andSelf();
				if(source){ source=$(source)[0]; $fields=$fields.filter(function(){ return this!=source; }); };

				$.each(fields||{}, function(dataFld,value){

					// For each type of setter selector, apply it's setter function to each element that matches selector:
					var $subset = dataFld != "*" ? $fields.filter(":mvcDataFld("+dataFld+")") : $fields;
					$.each( View.setters, function(selector,setter){
						$subset.filter(selector).each(function(){
							log("Calling", dataFld, "'"+selector+"'", "setter with values:", value);
							setter.apply( this, [ dataFld, $.makeArray(value) ] );
						});
					});
				});
			}
		}
	});

	// Define default options for the CONTROLLER:
	$.extend($.fn.Controller, {
		version: '0.1',
		defaults: {

			// Helper to convert a Model field name to a View field name: (This is only for use in your own code so feel free to rename or replace)
			fromViewField	: function(fieldname, template, regex){
				if( typeof(fieldname)=="string" ){
					regex		= regex || /.*\[(.*)\]/;
					template	= template || "$1";
					return fieldname.replace(regex,template);	// Eg: "client[surname]" => "surname"
				}else{
					var convert = this.fromViewField;
					return Hash.map( fieldname, function(fld,val){ return [ convert(fld,template,regex),val ]; });
				};
			},

			// Helper to convert a View field name to a Model field name: (This is only for use in your own code so feel free to rename or replace)
			toViewField		: function(fieldname, template, regex){
				if( typeof(fieldname)=="string" ){
					regex		= regex || /(.*)/;
					template	= template || "unknown[$1]";
					return fieldname.replace(regex,template);	// Eg: "postcode" => "client[postcode]"
				}else{
					var convert = this.toViewField;
					return Hash.map( fieldname, function(fld,val){ return [ convert(fld,template,regex),val ]; });
				};
			},

			// Helper for updating Model and View from eachother using very self-describing code just for a larf ;o)
			// Usage: Controller.copy(fields).from(View).to(Model);
			// Important: copy() expects a hash of fields. from() and to() expect a Model or View.
			copy	: function(fields){
				var Controller = this;
				return {
					from : function(source){		// Source Model or View.
						return {
							to : function(target){	// Target Model or View.
								if( source.isView ) fields = Controller.fromViewField(fields);	// Convert View fields to Model fields.
								if( target.isView ) fields = Controller.toViewField(fields);	// Convert Model fields to View fields.
								target.update(fields); var id = fields[target.idField];
								return target.isModel ? target.get(id) : fields ;
							}
						};
					}
				};
			},

			// Unused: Possible replacement for controller.fromViewField() and controller.toViewField()
			convert	: function(fieldname, template, regex){
				var Controller = this;
				return {
					from: function(source){	// Model or View
						return {
							to : function(target){

								// Usage: Controller.convert(field).from(View).to(Model)
								if( source.isView ){

									if( typeof(fieldname)=="string" ){
										regex		= regex || /.*\[(.*)\]/;
										template	= template || "$1";
										return fieldname.replace(regex,template);	// Eg: "client[surname]" => "surname"
									}else{
										var convert = this.fromViewField;
										return Hash.map( fieldname, function(fld,val){ return [ Controller.convert(fld,template,regex).from(View).to(Model), val ]; });
									};

								// Usage: Controller.convert(field).from(Model).to(View)
								}else if( source.isModel ){

									if( typeof(fieldname)=="string" ){
										regex	= regex || /(.*)/;
										template= template || "unknown[$1]";
										return fieldname.replace(regex,template);	// Eg: "postcode" => "client[postcode]"
									}else{
										var convert = this.toViewField;
										return Hash.map( fieldname, function(fld,val){ return [ Controller.convert(fld,template,regex).from(Model).to(View), val ]; });
									};

								};
							}
						};
					}
				};
			}

		}
	});




	// All in one mvc automatic init method: (TBD)
	$.fn.MVC = function(options){

		if( options && typeof(options)=="String" && options=="destroy" ) return this.View("destroy");

		options = options || {};
		var Model = this.Model(options.model);
		var View  = this.View(options.view);

		return {
			Model		: Model,
			View		: View,
			Controller	: this.Controller(Model, View, options.controller)
		}
	}



	// Helper functions for manipulating object hashes:
	var Hash = {
	
		// Convert array to hash: (Sets all items to true if corresponding array of values is not specified)
		// Usage: var myHash = Hash.make(arrayOfKeys,arrayOfValues);
		make : function(keys,values){
			var hash = {}, isArray = jQuery.isArray(values);
			$.each(keys, function(i,key){ hash[key] = isArray ? values[i] : (values||true) });
			return hash;
		},

		// Similar to jQuery.map but this works on objects: (Optionally specify an object to extend, otherwise a new object will be returned)
		// Usage: var newHash = Hash.map(origHash,function(key,val){ return [key+"NEW",val+"NEW"] });
		map	: function(hash,callback,extend){
			var result = extend||{}, undefined;
			$.each(hash,function(key,value){
				var mapped = callback.apply(value,[key,value]);
				if(mapped[0] != undefined){
					var newItem = {}; newItem[mapped[0]] = mapped[1];
					$.extend(result,newItem);
				};
			});
			return result;
		},

		// Return the nth value in a hash object:
		// Usage: var thirdItem = Hash.nth(myHash,2);
		nth	: function(hash,n){
			var result, i=0; n=parseInt(n)||0;
			$.each(hash,function(key,value){ if( i++ === n ){ result=value; return false; }; });
			return result;
		}

	};


	function interpolate(template, data){
		$.each( data||{}, function(key,val){
			template = template.replace( new RegExp("\{" + key + "\}", "g"), val );
		});
		return template;
	};

	// helper fn for console logging: (set options.debug to true to enable debug logging)
	function log() {
		if ( window.MCV_LOGGING_ENABLED && window.console && window.console.log ){
			window.console.log.apply(window.console,arguments);
			//window.console.log('[jquery-mvc] ' + Array.prototype.join.call(arguments,' '));
		}
	};

	// Helper to ensure we concatenate folder names correctly to make a valid url:
	function buildPath(folders){
		return $.map(arguments, function(folder,i){ return folder.replace( /^\/*|\/*$/g, ""); }).join("/");
	};

})(jQuery);