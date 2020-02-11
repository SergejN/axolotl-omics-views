/*
	File:
		view.secstr.js
		
	Description:
		Contains functions of the Secondary Structure View.
	
	Version:
        1.2.2
	
	Date:
		07.11.2014
*/

/* Retrieves and displays the secondary structure details */
(function() {
	function SecondaryStructureViewer() {
		
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
		    this.wrapper.id = 'secstr-wrapper';
		    content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Molecule.predictSecondaryStructure',
										  params: {seqID: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
	    }
		
	    this.parseData = function(data) {
		    var xml = data.responseXML;
		    var root = xml.documentElement;
		    if(root.nodeName!='svg') {
			    GUI.displayErrorMsg('The secondary structure could not be predicted', this.wrapper);
			    GUI.toggleInfoMsg(this.msg);
			    return;
		    }
			var copyright = 'The prediction of the RNA secondary structure was performed by '+
			                '<a target="_blank" href="http://rna.tbi.univie.ac.at/cgi-bin/RNAfold.cgi">RNAfold</a>.';
			var cr = document.createElement('div');
			cr.id = 'secstr-copyright';
			cr.innerHTML = copyright;
			this.wrapper.appendChild(cr);
			this.wrapper.appendChild(root);
		    GUI.toggleInfoMsg(this.msg);
	    }
	}
	
  	Views.registerEventHandler('view-secstr', new SecondaryStructureViewer());
})();