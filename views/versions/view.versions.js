/*
	File:
		view.versions.js
		
	Description:
		Contains functions of the Versions View.
	
	Version:
        1.2.7
	
	Date:
		05.12.2013
*/

/* Retrieves and displays the version details */
(function() {
	function VersionsViewer() {
		
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
			this.wrapper.id = 'versions-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {type: 'versions',
										           values: 'alignment',
								                   seqIDs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
		this.parseData = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
			var contig = root.getElementsByTagName('sequence')[0];
			if(!contig) {
				GUI.displayErrorMsg('No similar transcripts are available. Note, however, that the search was performed automatically. '+
									   'In order to get more results run Blast against the assembly of interest.',
									this.wrapper);
				GUI.toggleInfoMsg(this.msg);
				return;
			}
			var mapdata = {length: parseInt(contig.getAttribute('length'), 10),
				           nTicks: 10,
				           lines: [],
				           sort: Controls.GB_SMSORT_NONE};
		    var homologs = contig.getElementsByTagName('homolog');
		    for(var i=0;i<homologs.length;i++) {
				var homolog = homologs[i];
				var name = homolog.getAttribute('name');
				var alndata = homolog.getElementsByTagName('alignment')[0];
				var line = {title: '<a target="_blank" href="/transcripts/'+name+'">'+name+'</a>',
							fragments: [],
							version: parseInt(homolog.getAttribute('assembly'), 10)};
				this.data[name] = {annotation: undefined, hsps: {}};
				var annotation = homolog.getElementsByTagName('annotation')[0];
				if(annotation) {
					this.data[name].annotation = {definition: Core.extractLongText(annotation),
					                              symbol: annotation.getAttribute('symbol')};
					if(this.data[name].annotation.symbol)
						line.title += ' ('+this.data[name].annotation.symbol+')';
				}
				var hsps = alndata.getElementsByTagName('hsp');
				for(var j=0;j<hsps.length;j++) {
					var hsp = Core.parseHSPdata(hsps[j], 'Transcript', 'Sibling');
					var fragment = {position: {start: hsp.sequence.start, end: hsp.sequence.end},
									type: (hsp.sequence.frame>=0 && hsp.hit.frame>=0) ? Controls.GB_SMFRAGMENT_FORWARD : Controls.GB_SMFRAGMENT_REVERSE,
									tooltip: 'Bitscore: '+hsp.score + 'E-value: '+hsp.evalue,
									callback: {scope: this,
											   cbClicked: this.toggleAlignment,
											   cbParams: [name, j]}};
					line.fragments.push(fragment);
					this.data[name].hsps[j]  = hsp;
					}
				mapdata.lines.push(line);
		    }
			mapdata.lines.sort(function(a,b){return b.version-a.version});
		    var map = Controls.createMap(mapdata);
		    this.wrapper.appendChild(map);
		    GUI.toggleInfoMsg(this.msg);
		}
		
		this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('versions-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'versions-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
			alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('versions-alnslider');
			var nSlides = 0;
			for(var i in this.data[name].hsps) {
				var strAnnotation = undefined;
				if(this.data[name].annotation) {
					strAnnotation = this.data[name].annotation.definition;
					if(this.data[name].annotation.symbol)
						strAnnotation += ' (<i>'+this.data[name].annotation.symbol+'</i>)';
				}
				var slide = Controls.createHSPSlide(this.data[name].hsps[i],
													name + ', HSP '+(parseInt(i,10)+1),
													strAnnotation,
													'versions-content-wrapper',
													{scope: this, fnCallback: this.runBlast, args: [name, i]});
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#versions-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
			alnwrapper.className = '';
		    this.lastShown.name = name;
			this.lastShown.index = index;
			GUI.scrollToElement(alnwrapper.id);
	    }
		
		this.runBlast = function(bLocal, name, index) {
			var hspdata = this.data[name].hsps[index];
			var strJobID = name+', HSP '+(parseInt(index,10)+1);
			var strSeq = hspdata.sequence.seq.replace(/-/g, '');
			Viewer.blastSequence(bLocal, strSeq, 'blastx', 'refseq_protein', 'nucleotide', strJobID);
		}
	}
	
  	Views.registerEventHandler('view-versions', new VersionsViewer());
})();