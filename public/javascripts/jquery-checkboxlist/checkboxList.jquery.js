$.fn.extend({

	checkboxList : function(options){

		options = $.extend( {}, {

			listTag		: '<ul>',	// Typically '<ul>' or '<dl>'.
			itemTag		: '<li>',	// Typically '<li>' or '<dd>'.
			groupTag	: null,		// Typically  null  or '<dt>'. When not null, it's text is copied from OPTGROUP labels.
			copyAttrs	: ['name'],	// Array of names of attributes to copy from the list to the checkboxes.
			attrs		: {},		// Hash of axtra attributes to set on each checkbox.
			css			: {			// Hash of css to set on the checkboxList (specify height:true and/or width:true to copy dimensions from the <select> list)
				width		: true,
				height		: true,
				'overflow-y':'auto'
			},
			activeClass	: 'checkbox-list-activated'	// Class name added to <select> lists after converting to checkboxList.

		}, options );


		return this.filter('SELECT[multiple]:not(.' + options.activeClass + ')').each(function(){

			var $oldList	= $(this);
			var $newList	= $(options.listTag).addClass('checkbox-list').attr({ id:$oldList.attr('id') });	//.attr( $oldList.attr('className') )
			var attrs		= $.extend( {}, options.attrs );
			var idPrefix	= $oldList.attr('id') || 'chk';

			// Build hash of attributes copied from the old list: 
			$(options.copyAttrs).each(function(i,attr){
				attrs[attr] = $oldList.attr(attr)
			});

			// Style the new list box:
			if( options.css ){

				// Decide whether to copy dimensions etc from $oldList:
				if( options.css.width  === true ){ $newList.width(  $oldList.width() ); delete options.css['width']  }
				if( options.css.height === true ){ $newList.height( $oldList.width() ); delete options.css['height'] }

				$newList.css( options.css );

			}

			// Helper to generate checkbox item based on an <option> item:
			function buildCheckbox(){

				var $option		= $(this);
				var $newItem	= $(options.itemTag);
				var id			= idPrefix + (new Date).getTime();

				// Add a checkbox to the new list item:
				$('<input type="checkbox"/>')
					.attr({
						id			: id,
						value		: $option.val(),
						className	: $option.attr('className'),
						checked		: $option.attr('selected') ? 'checked' : null
					})
					.attr( attrs )
					.appendTo( $newItem );

				// Add a label to the new list item:
				$('<label>')
					.attr({ 'for': id })
					.text( $option.text() )
					.appendTo( $newItem );

				// Add the new list item to the list:
				$newItem
					.appendTo( $newList );

			}


			// Helper to generate group heading based on an <optgroup> item:
			function buildGroupHeading(){

				if( options.groupTag ){

					$(options.groupTag)
						.text( $(this).attr('label') )
						.appendTo( $newList );

				}
			
			}


			// Convert every <optgroup> (if any) and <option> item:
			$(this).children().each(function(){

				$(this)
					// Convert <option> element that is not in an optgroup:
					.filter('OPTION').each(buildCheckbox).end()

					// Convert <optgroup> and all <option> elements within it:
					.filter('OPTGROUP').each(buildGroupHeading)

					// Convert all <option> items in this optgroup:
					.children('OPTION').each(buildCheckbox)
				;

			});

			// Show the new list in place of the old one: (We disable the old one to exclude it from form submissions)
			$newList.insertBefore( $oldList.hide().attr({ disabled:'disabled' }) );

		}).addClass( options.activeClass ).end();

	}

});