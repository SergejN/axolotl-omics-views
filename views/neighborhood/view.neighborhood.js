/*
	File:
		view.neighborhood.js
		
	Description:
		Contains functions of the Genomic Neighborhood View.
	
	Version:
        1.4.4
		
	Date:
		17.11.2014
*/

/* Retrieves and displays the genomic neighborhood details */
(function() {
    function GenomicNeighborhoodViewer() {
	
		// Variables.
		this.infomsg = undefined;
		this.wrapper = undefined;
		this.data = {};
		this.toolbar = undefined;
		this.lastShown = {cname: undefined, hsp: undefined};
	
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
			GUI.toggleInfoMsg(msg);
			// Create the wrapper element and the content.
			var parent = view.parentNode;
			var content = parent.getElementsByClassName('view-expanded')[0];
			this.wrapper = document.createElement('div');
			this.wrapper.id = 'neighborhood-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {seqIDs: this.sequence.id,
										           values: 'alignment'}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
	
		this.parseData = function(data) {
			var xml = data.responseXML;
		    var root = xml.documentElement;
			var seqdata = root.getElementsByTagName('sequence')[0];
			if(!seqdata) {
				GUI.displayErrorMsg('No homologous transcripts are available for this PacBio read. '+
									   'Note, however, that the mapping was done automatically. '+
									   'In order to get more results try running Blast against the assembly.',
									this.wrapper);
				GUI.toggleInfoMsg(this.infomsg);
				return;
			}
			this.mapdata = {length: parseInt(seqdata.getAttribute('length'), 10),
							nTicks: 10,
							lines: [],
							sort: Controls.GB_SMSORT_BYLONGEST,
							topLine: 0};
			var homologs = seqdata.getElementsByTagName('homolog');
			for(var i=0;i<homologs.length;i++) {
				var homolog = homologs[i];
				var name = homolog.getAttribute('name');
				var line = {title: '<a target="_blank" href="/transcripts/'+name+'">'+name+'</a>',
							fragments: []};
				this.data[name] = {};
				var alndata = homolog.getElementsByTagName('alignment')[0];
				var hsps = alndata.getElementsByTagName('hsp');
				for(var j=0;j<hsps.length;j++) {
					var hsp = Core.parseHSPdata(hsps[j], 'PacBio read', 'Transcript');
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
			GUI.toggleInfoMsg(this.infomsg);
		}
		
		this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('neighborhood-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'neighborhood-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
			alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('neighborhood-alnslider');
			var nSlides = 0;
			for(var i in this.data[name]) {
				var slide = Controls.createHSPSlide(this.data[name][i],
													name + ', HSP '+(parseInt(i,10)+1),
													undefined,
													'neighborhood-content-wrapper',
													{scope: this, fnCallback: this.runBlast, args: [name, i]});
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#neighborhood-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
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
	
    Views.registerEventHandler('view-neighborhood', new GenomicNeighborhoodViewer());
})();