/*
	File:
		view.liblocation.js
		
	Description:
		Contains functions of the Library Location View.

	Version:
        1.4.4
    
	Date:
		26.11.2014
*/

/* Retrieves and displays the library location details */
(function() {
	function LibSeqLocationViewer() {
		
	    this.wrapper = undefined;
	    this.msg = undefined;
	    
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
		    this.msg = msg;
		    GUI.toggleInfoMsg(msg);
		    // Create the wrapper element and the content.
		    var parent = view.parentNode;
		    var content = parent.getElementsByClassName('view-expanded')[0];
		    this.wrapper = document.createElement('div');
		    this.wrapper.id = 'liblocation-wrapper';
		    content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Library.getLocation',
										  params: {seqIDs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
	    }

	    this.parseData = function(data) {
		    var xml = data.responseXML;
		    var root = xml.documentElement;
		    var sequence = root.getElementsByTagName('sequence')[0];
		    if(!sequence) {
			    GUI.displayErrorMsg('This sequence does not have location information. Either it is not an EST or it originates from the library '+
									   'that does not contain this kind of information',
									this.wrapper);
			    GUI.toggleInfoMsg(this.msg);
			    return;
		    }
			var location = sequence.getElementsByTagName('location')[0];
			var lines = [{label: 'Sequence name', value: location.getAttribute('name')},
						 {label: 'Plate', value: location.getAttribute('plate')},
						 {label: 'Well', value: location.getAttribute('well')}];
			for(var i=0;i<lines.length;i++) {
				var line = document.createElement('div');
				line.className = 'infoline';
				var label = document.createElement('div');
				label.className = 'linelabel';
				label.innerHTML = lines[i].label + ':';
				line.appendChild(label);
				var value = document.createElement('div');
				value.className = 'linevalue';
				value.innerHTML = lines[i].value;
				line.appendChild(value);
				this.wrapper.appendChild(line);
			}
		    GUI.toggleInfoMsg(this.msg);
	    }
	}
	
  	Views.registerEventHandler('view-liblocation', new LibSeqLocationViewer());
})();