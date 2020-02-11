/*
	File:
		view.libhomologs.js
		
	Description:
		Contains functions of the Library Homologs View.

	Version:
        1.4.4	
	
	Date:
		26.11.2014
*/

/* Retrieves and displays the library homologs details */
(function() {
	function LibHomologsViewer() {
		
	    this.wrapper = undefined;
	    this.msg = undefined;
		this.data = {};
	    this.lastShown = undefined;
	    
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
		    this.wrapper.id = 'libhomologs-wrapper';
		    content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {type: 'libseq',
										           values: 'alignment',
								                   seqIDs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
	    }
		
	    this.parseData = function(data) {
		    var xml = data.responseXML;
		    var root = xml.documentElement;
		    var sequence = root.getElementsByTagName('sequence')[0];
		    if(!sequence) {
			    GUI.displayErrorMsg('This sequence does not have location any homologous transcripts', this.wrapper);
			    GUI.toggleInfoMsg(this.msg);
			    return;
		    }
			var mapdata = {length: parseInt(sequence.getAttribute('length'), 10),
			               nTicks: 10,
						   lines: [],
						   sort: Controls.GB_SMSORT_BYLONGEST};
			var homologs = sequence.getElementsByTagName('homolog');
			for(var i=0;i<homologs.length;i++) {
				var name = homologs[i].getAttribute('name');
				var alndata = homologs[i].getElementsByTagName('alignment')[0];
				var fEvalue = alndata.getAttribute('evalue');
				var fScore = alndata.getAttribute('bitscore');
				// Library sequence data.
				var libseq = alndata.getElementsByTagName('sequence')[0];
				var strLSSeq = Core.extractLongText(libseq);
				var lss = parseInt(libseq.getAttribute('start'));			// First position within the aligned portion of the library sequence
				var lse = lss+strLSSeq.replace(/-/g, '').length-1;			// Last position within the aligned portion of the library sequence
				var ftype = Controls.GB_SMFRAGMENT_FORWARD;
				// Transcript data.
				var tdata = alndata.getElementsByTagName('hit')[0];
				var strTSeq = Core.extractLongText(tdata);
				var ts = parseInt(tdata.getAttribute('start'));				// First position within the aligned portion of the transcript sequence
				var te = 0;													// Last position within the aligned portion of the transcript sequence
				// Since the data only contains the start position of the alignment, calculate the fragment positions based on the
				// alignment length and orientation.
				var fs = 0;
				var fe = 0;
				if(libseq.getAttribute('frame') == '1') {
					fs = lss;
					fe = lss+strLSSeq.replace(/-/g, '').length-1;
					lse = fe;
				} else {
					fs = lss-strLSSeq.replace(/-/g, '').length+1;
					fe = lss;
					var tmp = lss;
					lss = fs;
					lse = tmp;
					ftype = Controls.GB_SMFRAGMENT_REVERSE;
				}
				var line = {title: '<a target="_blank" href="/transcripts/'+name+'">'+name+'</a>',
							fragments: [{position: {start: fs, end: fe},
										 type: ftype,
										 tooltip: 'Bitscore: '+fScore+' E-value: '+fEvalue,
										 callback: {scope: this,
													cbClicked: this.toggleAlignment,
													cbParams: [name]}}]};
				mapdata.lines.push(line);
				this.data[name]  = {libseq: {seq: strLSSeq, start: lss, end: lse},
								    transcript: {seq: strTSeq, start: ts, end: te, frame: (ftype == Controls.GB_SMFRAGMENT_FORWARD) ? 1 : -1},
								    midline: Core.extractLongText(alndata.getElementsByTagName('midline')[0]),
								    score: fScore,
								    evalue: fEvalue};
			}
			var map = Controls.createMap(mapdata);
		    this.wrapper.appendChild(map);
		    GUI.toggleInfoMsg(this.msg);
	    }
		
		this.toggleAlignment = function(name) {
		    var alnwrapper = document.getElementById('libhomologs-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'libhomologs-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown == name) {
				    alnwrapper.className = 'hidden';
				    this.lastShown = undefined;
				    return;
		    }
		    var hspdata = this.data[name];
		    alnwrapper.innerHTML = '';
		    var header = document.createElement('h3');
		    header.innerHTML = name;
		    alnwrapper.appendChild(header);
		    var alndata = {score: hspdata.score,
					       evalue: hspdata.evalue,
					       algorithm: 'blastn',
					       type: Controls.GB_AT_DNA,
					       first: {name: 'Sequence',
						           frame: 0,
							       start: hspdata.libseq.start,
							       end: hspdata.libseq.end,
							       sequence: hspdata.libseq.seq},
					       second: {name: 'Transcript',
							        frame: hspdata.transcript.frame,
								    start: hspdata.transcript.start,
								    end: hspdata.transcript.end,
								    sequence: hspdata.transcript.seq},
					       midline: hspdata.midline,
					       style: Controls.GB_AS_HEADER};
		    var aln = Controls.createAlignment(alndata);
		    alnwrapper.appendChild(aln);
		    alnwrapper.className = '';
		    this.lastShown = name;
	    }
	}
	
  	Views.registerEventHandler('view-libhomologs', new LibHomologsViewer());
})();