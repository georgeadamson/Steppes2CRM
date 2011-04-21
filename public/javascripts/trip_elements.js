
// Helpers and utitities for handling TRIP_ELEMENTS on the grids or in the element-form:


// Handle DELETE:
$('#trip-elements-grid BUTTON.delete').live('click', function(e){

	// Ignore this click if it was triggered by pressing <Enter> on another field: (Let it bubble to submit form save)
	if( this != document.activeElement ){ return }

	var $row = $(this).closest('TR');

	if( $row.is('.create') ){
		$row.remove();
	}else{
		$row.addClass('delete').removeClass('create update')		// Alter the display and
			.find("INPUT[name *= delete]").removeAttr('disabled');	// enable the field that instructs server to delete flight.
	}

	e.stopImmediatePropagation();
	return false;

});


// Bonus feature: Allow UNDO delete: (On deleted rows that have not yet been submitted)
$('#trip-elements-grid TR.delete .undo').live('click', function(e){

	var $row = $(this).closest('TR');

	$row.addClass('update').removeClass('delete')						// Alter the display and
		.find("INPUT[name *= delete]").attr({ disabled:'disabled' });	// disable the field that instructs server to delete flight.

	e.stopImmediatePropagation();
	return false;

});


// Respond to CLIPBOARD PASTE in the amadeus textbox:
// For some reason pasted text is not available from the event object, so we use timeout to give textbox a chance to accept it.
$('#amadeus-paste').live('paste', function(e){

	var $textbox = $(this);

	window.setTimeout( function(){

		var text    = $textbox.val();
		var flights = parsePastedAmadeusText(text);
		addFlightsToGrid(flights);

	}, 0 );

})


//	// DEPRICATED: Use ARROW KEYS to NAVIGATE the trip-elements-grid: (/views/trip_elements/grid)
//	$('#trip-elements-grid INPUT, #trip-elements-grid SELECT').live('keydown', function(e){

//		//if( e.keyCode == KEY.arrowRight ){ e.keyCode = KEY.tab; $(this).trigger(e); return }

//		if( e.keyCode in { 37:1,38:1,39:1,40:1 } ){

//			var $cell = $(this).closest('TD');
//			var $row  = $cell.parent();
//			var x     = $cell.attr('cellIndex');

//			switch(e.keyCode){

//				case KEY.arrowLeft : $(this).prevCell().find('INPUT,SELECT').first().focus(); break;
//				case KEY.arrowRight: $(this).nextCell().find('INPUT,SELECT').first().focus(); break;
//				case KEY.arrowUp   : $(this).prevCellUp().find('INPUT,SELECT').first().focus(); break;
//				case KEY.arrowDown : $(this).nextCellDown().find('INPUT,SELECT').first().focus(); break;

//			}

//		}

//	});



// Returns an array of flight objects parsed from the specified amadeus text:
// Sample lines: "  9  TA 143 Y 17JAN 1 GIGLIM HK1       1  0650 0929   *1A/E*  "
//               " 10  BA 249 Y 15JAN 6 LHRGIG HK1       5  1210 2150   *1A/E*  "
function parsePastedAmadeusText(rawAmadeus){

	rawAmadeus = rawAmadeus || '';
	var flights,
		isValidAirlineCode = /^([A-Z][A-Z]|[A-Z][0-9]|[0-9][A-Z])$/,	// Two letters, or a number and a letter.
		lookupMonthNumber  = {'JAN':1,'FEB':2,'MAR':3,'APR':4,'MAY':5,'JUN':6,'JUL':7,'AUG':8,'SEP':9,'OCT':10,'NOV':11,'DEC':12};

	// Separate raw amadesus text into lines and discard any that do not look like flight data:
	// We use a regex to identify lines beginning with a line-number and containing times like "0650 0929".
	flights = rawAmadeus.toUpperCase().split(/\n/);
	flights = $.grep(flights, function(line){ return /^\s*[1-9][0-9]?\s\s.*[0-9]{4}\s[0-9]{4}/.test(line) });

	// Allow for slapdash copy-and-paste by ensuring the line begins with the expected number of spaces:
	// This is necessary because we will locate each value by it's position in the line.
	// (Typically only applies to first line. Prefix must be 2 spaces when line-number is single digit or 1 space when it is 2 digits)
	flights = $.map( flights, function(line){ return line.replace( /^\s*([1-9]\s)/, '  $1' ).replace( /^\s*([1-9][0-9]\s)/, ' $1' ) });

	// Parse explicit attributes from raw amadeus line into a hash of properties for each flight:
	// Note we use Number() because parseInt() would parse '09' as 0 instead of 9.
	// console.log(flights, flights[0]);
	flights = $.map(flights, function(line){

		var flight = {
			line_number				: Number( line.substr(1,2) ),
			airline_code			: line.substr(5,2),
			flight_code				: line.substr(5,6),
			class_code				: line.substr(12,1),
			start_date_day			: Number( line.substr(14,2) ),
			start_date_month_name	: line.substr(16,3),
			depart_airport_code		: line.substr(22,3),
			arrive_airport_code		: line.substr(25,3),
			start_date_hour			: Number( line.substr(42,2) ),
			start_date_minute		: Number( line.substr(44,2) ),
			end_date_hour			: Number( line.substr(47,2) ),
			end_date_minute			: Number( line.substr(49,2) ),
			arrives_next_day		: !!parseInt( line.substr(52,1) )
		};

		// We attempted to derive the airline_code from the flight_code. (Eg: "BA123" -> "BA")
		// Assume airline_code is only valid if it begins with two-letters or a letter and a number:
		if( !isValidAirlineCode.test(flight.airline_code) ){ flight.airline_code = '' }

		return flight;

	});

	// Derive implicit attributes such as year, start_date and end_date for each flight:
	// Beware: Javascript months are zero-based (ie January is zero).
	// console.log(flights);
	flights = $.map(flights, function(flight){

		// Derive the month number: (1-12)
		flight.start_date_month = lookupMonthNumber[ flight.start_date_month_name ];

		var today     = new Date();
		var this_year = today.getFullYear();
		var next_year = this_year + 1;
		
		// Prepare to decide whether flight is this year or next: (because Amadeus only provides month and day!)
		var start_date_this_year = new Date( this_year, flight.start_date_month - 1, flight.start_date_day, flight.start_date_hour, flight.start_date_minute );
		var start_date_next_year = new Date( next_year, flight.start_date_month - 1, flight.start_date_day, flight.start_date_hour, flight.start_date_minute );

		// Assume any day/month combination before today is for next year:
		flight.start_date_year   = ( start_date_this_year >= today ) ? this_year : next_year;
		flight.start_date        = ( start_date_this_year >= today ) ? start_date_this_year : start_date_next_year;
		
		// Derive end_date and add a day if flight arrives_next_day:
		flight.end_date          = new Date(flight.start_date_year, flight.start_date_month - 1, flight.start_date_day, flight.end_date_hour, flight.end_date_minute );
		if( flight.arrives_next_day ){ flight.end_date.setDate( flight.start_date.getDate() + 1 ) };
		flight.end_date_month    = flight.end_date.getMonth() + 1;
		flight.end_date_day      = flight.end_date.getDate();

		// Derive "readable" date strings formatted for display in the ui:
		flight.ui_start_date     = uiDate(flight.start_date);
		flight.ui_end_date       = uiDate(flight.end_date);
		flight.ui_start_time     = twoDigit(flight.start_date_hour) + ':' + twoDigit(flight.start_date_minute);
		flight.ui_end_time       = twoDigit(flight.end_date_hour) + ':' + twoDigit(flight.end_date_minute);

		return flight;

	});

	// console.log(flights);
	return flights;

	// Helper to return number padded with a leading zero if it only had one digit:
	function twoDigit(num){
		num = (''+num).slice(0,2);
		return ('00'+num).slice(-2);
	}

	// Helper for format a date as "dd/mm/yyyy":
	function uiDate(date){
		return twoDigit(date.getDate()) + '/' + twoDigit(date.getMonth()+1) + '/' + date.getFullYear();
	}

}


// Helper to add several new rows to the flights grid:
function addFlightsToGrid(flights){

	var $table       = $('#trip-elements-grid TBODY');
	var templateHtml = $('#trip-elements-grid-row-template').html();
	var index        = 0;

	// This original loop has been superseded by recursive function below for better ui feedback
	// $.each( flights, function(index,flight){
	//   //console.log('Adding flight row for:', flight);
	//   var $row = newFlightRow(flight, 'new'+index, templateHtml);
	//   $row.appendTo($table);
	// });

	// Recursive function to add a row for each flight:
	// By using setTimeout, this technique allows the UI to render each new row while processing:
	(function(){

		var flight = flights[index++];

		if(flight){
			var $row = newFlightRow(flight, 'new'+index, templateHtml);
			$row.appendTo($table);
			window.setTimeout( arguments.callee, 0 );
		}else{
			// All flights added so lets activate the datepickers:
			initDatepickers($table);
		}

	})();

}


// Helper to generate html for a new row in the flights grid:
function newFlightRow(flight, index, templateHtml){

	// Give the row fields a unique nested_attributes index and ensure the row has no [id] field:
	var $row     = $( templateHtml.replace( '[new]', '['+index+']', 'g' ) );
	var $INPUTs  = $row.find("INPUT");
	var $SELECTs = $row.find("SELECT");
	//$row.find("INPUT[name *= '[id]' ]").remove();
	$INPUTs.filter("[name *= '[id]' ]").remove();

	$INPUTs.filter("[name *= '[flight_code]']").val(flight.flight_code);
	$INPUTs.filter("[name *= '[start_date]']" ).val(flight.ui_start_date);
	$INPUTs.filter("[name *= '[start_time]']" ).val(flight.ui_start_time);
	$INPUTs.filter("[name *= '[end_date]']"   ).val(flight.ui_end_date);
	$INPUTs.filter("[name *= '[end_time]']"   ).val(flight.ui_end_time);

	// Attempt to select AIRPORTS using airport code: (Eg: "LHR" -> "London Heathrow")
	// (Hopefully we avoid false-positives because the code is in uppercase + space and the name is mixed case)
	//$row.find("SELECT[name *= '[depart_airport_id]'] OPTION:contains('" + flight.depart_airport_code + " ')" ).attr({selected:'selected'});
	//$row.find("SELECT[name *= '[arrive_airport_id]'] OPTION:contains('" + flight.arrive_airport_code + " ')" ).attr({selected:'selected'});
	$SELECTs.filter("[name *= '[depart_airport_id]']").find("OPTION:contains('" + flight.depart_airport_code + " ')").attr({selected:'selected'});
	$SELECTs.filter("[name *= '[arrive_airport_id]']").find("OPTION:contains('" + flight.arrive_airport_code + " ')").attr({selected:'selected'});

	// Attempt to select AIRLINE (supplier) using airline_code derived from flight_code: (Eg: "BA123" -> "BA" -> "British Airways")
	selectRowAirline( $row, flight.airline_code, false, $INPUTs, $SELECTs );

	return $row;
}


// Helper to select AIRLINE (supplier) using airline_code:
// By default this will not overwrite an existing airline selection.
// If no airline_code provided then attempt to derive it from flight_code field (Eg: "BA123" -> "BA" -> "British Airways")
// (Hopefully we avoid false-positives because the code is in upper case and the name is mixed case)
function selectRowAirline( $row, airline_code, overwrite, $INPUTs, $SELECTs ){

	$INPUTs  = $INPUTs  || $row.find("INPUT");
	$SELECTs = $SELECTs || $row.find("SELECT");

	var $AIRLINES       = $SELECTs.filter("[name *= '[supplier_id]']");
	var alreadySelected = parseInt( $AIRLINES.val() || 0 );

	if( overwrite || !alreadySelected ){

		// If airline_code was not specified, attempt to derive it from the flight_code field:
		if( !airline_code ){
			//var flight_code = $row.find("INPUT[name *= '[flight_code]']").val();
			var flight_code = $INPUTs.filter("[name *= '[flight_code]']").val();
			   airline_code = $.trim(flight_code).slice(0,2);
		}

		// Set the airline (supplier) by finding one that matches airline_code:
		// Eg: A search for " AF " should match list item "Air France - AF [GBP]".
		if( airline_code ){

			var isCodeIn = new RegExp( '\\s' + airline_code + '\\s' );

			$AIRLINES.find("OPTION").filter(function(){

				return isCodeIn.test( $(this).text() );

			}).attr({selected:'selected'});

		}

	}

}


// For dev/test only. Run parser when grid page loads:
$(function($){

	//parsePastedAmadeusText( $('#amadeus-paste').val() )

});

