/*
	File:
		view.ish.js
		
	Description:
		Contains functions of the In-Situ View.

	Version:
        1.2.6	
	
	Date:
		30.05.2013
*/

(function() {
	function ISHViewer() {
        
		// Methods.
		this.toggleView = function(view, state, msg) {
			// First, toggle the view content visibility. If the visibility was not turned on, simply return.
			if(state!='expanded') {
			    return;
			}
			// If the wrapper element already exists, simply return.
			if(this.wrapper) {
			    return;
			}
			this.infomsg = msg;
			GUI.toggleInfoMsg(this.infomsg);
				this.nRunning = this.nSelected = 0;
			// Create the wrapper element and the content.
			var parent = view.parentNode;
			var content = parent.getElementsByClassName('view-expanded')[0];
			this.wrapper = document.createElement('div');
			this.wrapper.id = 'ish-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {type: 'ISH',
										           values: 'alignment',
								                   seqID: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
		this.parseData = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
			var contig = root.getElementsByTagName('sequence')[0];
			if(!contig) {
				GUI.displayErrorMsg('No <i>in-situ</i> data are available', this.wrapper);
				GUI.toggleInfoMsg(this.infomsg);
				return;
			}
			GUI.toggleInfoMsg(this.infomsg);
		}
	}
	
	Views.registerEventHandler('view-ish', new ISHViewer());
})();