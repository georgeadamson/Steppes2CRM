
var Brochure = {

	openNew : function(options){

		// We've intercepted a link so prevent default code from handling it:
		options.event.stopImmediatePropagation();

		$('<div>').html('Opening...').dialog({
			//autoOpen: false,
			title		: 'Log an Enquiry or Request a Brochure',
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
			title		: 'Modify Enquiry or Brochure Request',
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
	
}