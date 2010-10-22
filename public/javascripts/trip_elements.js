
	// Helpers and utitities for handling TRIP_ELEMENTS.


	// Respond to CLIPBOARD PASTE into the amadeus textbox:
	// For some reason the textbox value is not available immediately so we use timeout to give it a chance.
	$('#amadeus-paste').live('paste', function(e){
		var $text = $(this);
		window.setTimeout( function(){

			var flights = parsePastedAmadeusText( $text.val() );
			
			addFlightRows(flights);

		}, 0 );
	})


	// Use ARROW KEYS to NAVIGATE the trip-elements-grid: (/views/trip_elements/grid)
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



	// Returns an array of flight objects parsed from the specified amadeus text:
	function parsePastedAmadeusText(rawAmadeus){
		
		var flights; rawAmadeus = rawAmadeus || '';
		var lookupMonthNumber = {'JAN':1,'FEB':2,'MAR':3,'APR':4,'MAY':5,'JUN':6,'JUL':7,'AUG':8,'SEP':9,'OCT':10,'NOV':11,'DEC':12};

		// Separate raw amadesus text into lines and discard any that do not look like flight data:
		// We use a regex to identify lines beginning with a number and containing times like "0650 0929".
		// Sample lines: "  9  TA 143 Y 17JAN 1 GIGLIM HK1       1  0650 0929   *1A/E*  "
		//               " 10  BA 249 Y 15JAN 6 LHRGIG HK1       5  1210 2150   *1A/E*  "
		flights = rawAmadeus.toUpperCase().split(/\n/);
		flights = $.grep(flights, function(line){ return /^\s(\s|[0-9])[0-9]\s{2}.*[0-9]{4}\s[0-9]{4}/.test(line) });
		console.log(flights);

		// Parse explicit attributes from raw amadeus line into a hash of properties for each flight:
		flights = $.map(flights, function(line){

			var flight = {
				line_number				: parseInt( line.substr(1,2) ),
				airline_code			: line.substr(5,2),
				flight_code				: line.substr(5,6),
				class_code				: line.substr(12,1),
				start_date_day			: parseInt( line.substr(14,2) ),
				start_date_month_name	: line.substr(16,3),
				depart_airport_code		: line.substr(22,3),
				arrive_airport_code		: line.substr(25,3),
				start_date_hour			: parseInt( line.substr(42,2) ),
				start_date_minute		: parseInt( line.substr(44,2) ),
				end_date_hour			: parseInt( line.substr(47,2) ),
				end_date_minute			: parseInt( line.substr(49,2) ),
				arrives_next_day		: !!parseInt( line.substr(52,1) )
			};

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


	function newFlightRow(flight, index, templateHtml){

		// Give the row fields a unique nested_attributes index and ensure the row has no [id] field:
		var $row = $( templateHtml.replace( '[new]', '['+index+']', 'g' ) );
		$row.find("INPUT[name *= '[id]' ]").remove();

		$row.find("INPUT[name *= '[flight_code]']").val(flight.flight_code);
		$row.find("INPUT[name *= '[start_date]']" ).val(flight.ui_start_date);
		$row.find("INPUT[name *= '[start_time]']" ).val(flight.ui_start_time);
		$row.find("INPUT[name *= '[end_date]']"   ).val(flight.ui_end_date);
		$row.find("INPUT[name *= '[end_time]']"   ).val(flight.ui_end_time);

		$row.find("SELECT[name *= '[depart_airport_id]'] OPTION:contains('" + flight.depart_airport_code + " ')" ).attr({selected:'selected'});
		$row.find("SELECT[name *= '[arrive_airport_id]'] OPTION:contains('" + flight.arrive_airport_code + " ')" ).attr({selected:'selected'});

		return $row;
	}


	function addFlightRows(flights){

		var $table       = $('#trip-elements-grid TBODY');
		var templateHtml = $('#trip-elements-grid-row-template').html();

		$.each( flights, function(index,flight){

			console.log('Adding flight row for:', flight);
			var $row = newFlightRow(flight, 'new'+index, templateHtml);

			$row.appendTo($table);

		});

	}

	$(function($){

		parsePastedAmadeusText( $('#amadeus-paste').val() )

	});