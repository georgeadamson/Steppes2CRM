(function($){

	var undefined;



// Extra methods for jQuery UI tabs:
// This script must be loaded AFTER the jqueryui scripts.

// finder method for searching for a tab by it's ajax url.
// TODO: This overrides the default url method with additional functionality.
// Usage: $('#myTabs').tabs( 'find', /\clients\/new/ ) returns a ui object.
// Note: Default 'setter' usage would be more like: $('#myTabs').tabs('find', 3, url)

var orig_url_method = $.ui.tabs.prototype.url;

$.extend( $.ui.tabs.prototype, {

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

