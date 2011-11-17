(function($){

	var undefined;



// Extra methods for jQuery UI tabs:
// This script must be loaded AFTER the jqueryui scripts.

// Keep a reference to the original methods that we're about to override:
var orig_ui_method  = $.ui.tabs.prototype._ui;
var orig_url_method = $.ui.tabs.prototype.url;
var orig_getIndex_method = $.ui.tabs.prototype._getIndex;

$.extend( $.ui.tabs.prototype, {

	// Override the default _ui method with additional functionality:
	// Adds an extra "tabs" attribute to the tabs ui hash to refer to the tabs element itself.
	// Note: We test for existing tabs attibute first, just in case it is set by a future version of jQuery UI Tabs.
	_ui: function( tab, panel ) {
		var ui = orig_ui_method.call(this, tab, panel);
		return ui.tabs ? ui : $.extend( ui, { tabs: this.element[0] || this.element } );
	},


	// Override the default _getIndex method with additional functionality:
	// To also match tabs on url as well as index or href (because href on ajax tabs is dynamically generated)
    _getIndex: function( index ) {

		var containsSlash = /\//,
		    prefixSlash = /^\//;

		// Do special functionality when index is a url or regex:
		if ( containsSlash.test(index) || index instanceof RegExp ) {

			var $tab = this.anchors.filter(function(){
				var url = $.data(this,'load.tabs') || '';
				return ( index instanceof RegExp ) ? index.test(url) : index.replace(prefixSlash,'') == url.replace(prefixSlash,'');
			});

			return this.anchors.index( $tab );
		}

		// Otherwise do default functionality:
		return orig_getIndex_method.call(this,index);
	},

	// TODO: Can we depricate this and use .tabs('getIndex',i) instead?
	// Override the default url method with additional functionality:
	// Provides a finder method for searching for a tab by it's ajax url.
	// Usage: $('#myTabs').tabs( 'find', /\clients\/new/ ) returns a ui object.
	// Note: Default 'setter' usage would be more like: $('#myTabs').tabs('find', 3, url)
	url : function( index, url ){

		// When both arguments are provided, assume the default (expected) setter action:
		if( url !== undefined ){
			orig_url_method.call( this, index, url );
			return this;
		}

		// Otherwise act as a getter for finding a tab...
		var self = this, selector = index;

		// Search for exact or regex url match:
		if( typeof(selector) === 'string' || selector instanceof RegExp ){

			var $tab = self.anchors.filter(function(){
				var url = $.data(this,'load.tabs') || '';
				return ( typeof(selector) === 'string' ) ? selector.replace(/^\//,'') == url.replace(/^\//,'') : selector.test(url);
			});

			index = self.anchors.index( $tab );

		// Otherwise just assume we're just matching by index:
		} else {
			index = parseInt(selector);
		}

		// Fetch the index and return a standard jQuery-ui hash:
		return self._ui( self.anchors[index], self.panels[index] )

	}

});



})(jQuery);

