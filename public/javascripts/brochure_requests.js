
var Brochure = {

	openNew : function(options){

		// We've intercepted a link so prevent default code from handling it:
		options.event.stopImmediatePropagation();

		$('<div>').html('Opening...').dialog({
			//autoOpen: false,
			title		: 'Log an Enquiry',
			minHeight	: 300,
			width		: 550,
			open		: function(e,ui){
				ui.panel = this;
				options.target = '#' + $(ui.panel).id();
				Layout.load(options.url,options)
			},
			buttons		: {
				'Cancel'				: function(){ $(this).dialog('close').remove() },
				'Save my new enquiry'	: function(){ $('FORM',this).submit() }
			}
		});

	},

	openEdit : function(options){

		// We've intercepted a link so prevent default code from handling it:
		options.event.stopImmediatePropagation();

		var $dialog = $('<div>').html('Opening...').dialog({
			//autoOpen: false,
			modal		: true,
			title		: 'Modify Enquiry',
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
		
	initForm : function(ui){
	
		//$("SELECT[name='task[status_id]']").change(Task.toggleClosedTaskFields).trigger('change');

	},
	
	onCreateSuccess : function(ui){

		// Close all dialogs: (TODO: Can we be more specific?!)
		$('DIV.ui-dialog-content').dialog('close').remove();

		if(ui && ui.form && ui.form.client_id){

			// Refresh the list of the client's brochure_requests:
			// No need to use Layout.load(ui.url,ui) here, just go ahead and refresh the content;
			ui.url		= Url('clients', ui.form.client_id, 'brochure_requests');	// Eg: "/clients/1234/brochure_requests"
			ui.target	= '#' + ui.url.split('/').join('');								// Eg: "#clients1234brochure_requests"
			$(ui.target).load(ui.url);												// Reload client's custom list of brochure_requests.

			ui.url     = Url('clients', ui.form.client_id, 'summary', 'marketing')
			ui.target  = '#' + ui.url.split('/').join('');
			$(ui.target).load(ui.url);													// Reload client summary page.



		}
	}

}