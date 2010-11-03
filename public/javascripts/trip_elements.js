
	// Helpers and utitities for handling TRIP_ELEMENTS.


	// Handle DELETE:
	$('#trip-elements-grid BUTTON.delete').live('click', function(e){

		var $row = $(this).closest('TR');

		if( $row.is('.create') ){
			$row.remove();
		}else{
			$row.addClass('delete').removeClass('create update')		// Alter the display and
				.find("INPUT[name *= delete]").removeAttr('disabled');	// enable the delete field.
		}

		e.stopImmediatePropagation();
		return false;

	});

		// Handle UNDO delete:
		$('#trip-elements-grid TR.delete .undo').live('click', function(e){

			var $row = $(this).closest('TR');

			$row.addClass('update').removeClass('delete')						// Alter the display and
				.find("INPUT[name *= delete]").attr({ disabled:'disabled' });	// disabled the delete field.

			e.stopImmediatePropagation();
			return false;

		});


	// Respond to CLIPBOARD PASTE into the amadeus textbox:
	// For some reason the pasted text is not available, so we use timeout to give textbox a chance to accept it.
	$('#amadeus-paste').live('paste', function(e){

		var $text = $(this);

		window.setTimeout( function(){

			var flights = parsePastedAmadeusText( $text.val() );
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

		var flights, isValidAirlineCode = /^([A-Z][A-Z]|[A-Z][0-9]|[0-9][A-Z])$/;
		var lookupMonthNumber = {'JAN':1,'FEB':2,'MAR':3,'APR':4,'MAY':5,'JUN':6,'JUL':7,'AUG':8,'SEP':9,'OCT':10,'NOV':11,'DEC':12};
		rawAmadeus = rawAmadeus || '';

		// Separate raw amadesus text into lines and discard any that do not look like flight data:
		// We use a regex to identify lines beginning with a number and containing times like "0650 0929".
		flights = rawAmadeus.toUpperCase().split(/\n/);
		flights = $.grep(flights, function(line){ return /^\s(\s|[0-9])[0-9]\s{2}.*[0-9]{4}\s[0-9]{4}/.test(line) });
		console.log(flights);

		// Parse explicit attributes from raw amadeus line into a hash of properties for each flight:
		// Note we use Number() because parseInt() would parse '09' as 0 instead of 9.
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
		console.log(flights);

		// Derive implicit attributes such as year, start_date and end_date for each flight:
		// Beware: Javascript months are zero-based so January is zero.
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
		console.log(flights);

		return flights;

		// Helper to return number padded with a leading zero if it only had one digit:
		function twoDigit(num){
			//return String(num).replace(/^([0-9])$/, '0$1');
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

		$.each( flights, function(index,flight){

			console.log('Adding flight row for:', flight);
			var $row = newFlightRow(flight, 'new'+index, templateHtml);

			$row.appendTo($table);

		});

	}


	// Helper to generate html for a new row in the flights grid:
	function newFlightRow(flight, index, templateHtml){

		// Give the row fields a unique nested_attributes index and ensure the row has no [id] field:
		var $row = $( templateHtml.replace( '[new]', '['+index+']', 'g' ) );
		$row.find("INPUT[name *= '[id]' ]").remove();

		$row.find("INPUT[name *= '[flight_code]']").val(flight.flight_code);
		$row.find("INPUT[name *= '[start_date]']" ).val(flight.ui_start_date);
		$row.find("INPUT[name *= '[start_time]']" ).val(flight.ui_start_time);
		$row.find("INPUT[name *= '[end_date]']"   ).val(flight.ui_end_date);
		$row.find("INPUT[name *= '[end_time]']"   ).val(flight.ui_end_time);

		// Attempt to select AIRPORTS using airport code: (Eg: "LHR" -> "London Heathrow")
		// (Hopefully we avoid false-positives because the code is in upper case and the name is mixed case)
		$row.find("SELECT[name *= '[depart_airport_id]'] OPTION:contains('" + flight.depart_airport_code + "')" ).attr({selected:'selected'});
		$row.find("SELECT[name *= '[arrive_airport_id]'] OPTION:contains('" + flight.arrive_airport_code + "')" ).attr({selected:'selected'});

		// Attempt to select AIRLINE (supplier) using airline_code derived from flight_code: (Eg: "BA123" -> "BA" -> "British Airways")
		selectRowAirline( $row, flight.airline_code );

		return $row;
	}


	// Helper to select AIRLINE (supplier) using airline_code:
	// By default this will not overwrite an existing airline selection.
	// If no airline_code provided then attempt to derive it from flight_code field (Eg: "BA123" -> "BA" -> "British Airways")
	// (Hopefully we avoid false-positives because the code is in upper case and the name is mixed case)
	function selectRowAirline( $row, airline_code, overwrite ){

		var alreadySelected = parseInt( $row.find("SELECT[name *= '[supplier_id]']").val() );

		if( overwrite || !alreadySelected ){

			// If airline_code was not specified, attempt to derive it from the flight_code field:
			if( !airline_code ){
				var flight_code = $row.find("INPUT[name *= '[flight_code]']").val();
				   airline_code = $.trim(flight_code).substr(0,2);
			}

			// Set the airline (supplier) by finding one that matches airline_code:
			if( airline_code ){

				var isCodeIn = new RegExp( '\\s' + airline_code + '\\s' );

				$row.find("SELECT[name *= '[supplier_id]'] OPTION").filter(function(){

					var airlineNameAndCode = $(this).text(); 
					return isCodeIn.test( airlineNameAndCode );

				}).attr({selected:'selected'});

			}

		}

	}


	// For dev/test only. Run parser when grid page loads:
	$(function($){

		parsePastedAmadeusText( $('#amadeus-paste').val() )

	});

