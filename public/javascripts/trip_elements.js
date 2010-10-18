
// Helpers and utitities for handling TRIP_ELEMENTS.


// Use ARROW KEYS to navigate the trip-elements-grid: (/views/trip_elements/grid)
$('#trip-elements-grid INPUT, #trip-elements-grid SELECT').live('keydown', function(e){

	//if( e.keyCode == KEY.arrowRight ){ e.keyCode = KEY.tab; $(this).trigger(e); return }

	if( e.keyCode in { 37:1,38:1,39:1,40:1 } ){

		var $cell = $(this).closest('TD');
		var $row  = $cell.parent();
		var x     = $cell.attr('cellIndex');

		switch(e.keyCode){

			case KEY.arrowLeft : $(this).prevCell().find('INPUT,SELECT').first().focus(); break;
			case KEY.arrowRight: $(this).nextCell().find('INPUT,SELECT').first().focus(); break;
			case KEY.arrowUp   : $(this).prevCellUp().find('INPUT,SELECT').first().focus(); break;
			case KEY.arrowDown : $(this).nextCellDown().find('INPUT,SELECT').first().focus(); break;

		}

	}

});
