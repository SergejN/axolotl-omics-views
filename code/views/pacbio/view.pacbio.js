/*
	File:
		view.pacbio.js
		
	Description:
		Contains functions of the PacBio View.

	Version:
        1.0.1	
	
	Date:
		14.09.2015
*/

/* Retrieves and displays the PacBio alignment details */
(function() {
	function PacBioViewer() {
		
	    this.wrapper = undefined;
	    this.msg = undefined;
	    this.data = {};
	    this.lastShown = {name: undefined, index: undefined};
	    
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
		    this.wrapper.id = 'pacbio-content-wrapper';
		    content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {type: 'PacBio',
										           values: 'alignment',
								                   seqIDs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData,
									        args: []}});
	    }
		
	    this.parseData = function(data) {
		    var xml = data.responseXML;
		    var root = xml.documentElement;
			var contig = root.getElementsByTagName('sequence')[0];
			if(!contig) {
				GUI.displayErrorMsg('No PacBio reads are available for this transcript. '+
									   'Note, however, that the mapping was done automatically. '+
									   'In order to get more results try running Blast against the PacBio reads collection.',
									this.wrapper);
				GUI.toggleInfoMsg(this.msg);
				return;
			}
			this.mapdata = {length: parseInt(contig.getAttribute('length'), 10),
							nTicks: 10,
							lines: [],
							sort: Controls.GB_SMSORT_BYLEFTMOST,
							topLine: 0};
			var homologs = contig.getElementsByTagName('homolog');
			for(var i=0;i<homologs.length;i++) {
				var homolog = homologs[i];
				var name = homolog.getAttribute('name');
				var line = {title: '<input type="checkbox" id="'+name+'"><a target="_blank" href="/collections/sequence/'+name+'">'+name+'</a>',
							fragments: []};
				this.data[name] = {};
				var alndata = homolog.getElementsByTagName('alignment')[0];
				var hsps = alndata.getElementsByTagName('hsp');
				for(var j=0;j<hsps.length;j++) {
					var hsp = Core.parseHSPdata(hsps[j], 'Transcript', 'Read');
					var fragment = {position: {start: hsp.sequence.start, end: hsp.sequence.end},
									type: (hsp.hit.frame>0) ? Controls.GB_SMFRAGMENT_FORWARD : Controls.GB_SMFRAGMENT_REVERSE,
									callback: {scope: this,
											   cbClicked: this.toggleAlignment,
											   cbParams: [name, j]}};
					line.fragments.push(fragment);
					this.data[name][j]  = hsp;
				}
				this.mapdata.lines.push(line);
			}
			var map = Controls.createMap(this.mapdata);
			this.wrapper.appendChild(map);
			GUI.toggleInfoMsg(this.msg);
	    }

	    this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('pacbio-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'pacbio-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
			alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('pacbio-alnslider');
			var nSlides = 0;
			for(var i in this.data[name]) {
				var slide = Controls.createHSPSlide(this.data[name][i],
													name + ', HSP '+(parseInt(i,10)+1),
													undefined,
													'pacbio-content-wrapper',
													{scope: this, fnCallback: this.runBlast, args: [name, i]});
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#pacbio-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
		    alnwrapper.className = '';
		    this.lastShown.name = name;
			this.lastShown.index = index;
			GUI.scrollToElement(alnwrapper.id);
	    }
		
		this.runBlast = function(bLocal, name, index) {
			var hspdata = this.data[name][index];
			var strJobID = name+', HSP '+(parseInt(index,10)+1);
			var strSeq = hspdata.sequence.seq.replace(/-/g, '');
			Viewer.blastSequence(bLocal, strSeq, 'blastx', 'refseq_protein', 'nucleotide', strJobID);
		}
	}
	
  	Views.registerEventHandler('view-pacbio', new PacBioViewer());
})();