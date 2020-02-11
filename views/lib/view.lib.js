/*
	File:
		view.lib.js
		
	Description:
		Contains functions of the Library View.

	Version:
        1.7.6	
	
	Date:
		09.08.2013
*/

/* Retrieves and displays the library details */
(function() {
	function LibraryViewer() {
		
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
		    this.wrapper.id = 'lib-content-wrapper';
		    content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {type: 'LibSeq',
										           values: 'alignment',
								                   seqIDs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData,
									        args: ['libseqs']}});
	    }
		
	    this.parseData = function(data, step) {
		    var xml = data.responseXML;
		    var root = xml.documentElement;
			if(step == 'libseqs') {
				var contig = root.getElementsByTagName('sequence')[0];
				if(!contig) {
					GUI.displayErrorMsg('No library sequences are available for this transcript. '+
										   'Note, however, that the mapping was done automatically. '+
										   'In order to get more results try running Blast against the library of interest.',
										this.wrapper);
					GUI.toggleInfoMsg(this.msg);
					return;
				}
				this.mapdata = {length: parseInt(contig.getAttribute('length'), 10),
							    nTicks: 10,
							    lines: [],
							    sort: Controls.GB_SMSORT_BYLONGEST,
								topLine: 0};
				var homologs = contig.getElementsByTagName('homolog');
				for(var i=0;i<homologs.length;i++) {
					var homolog = homologs[i];
					var name = homolog.getAttribute('name');
					var line = {title: '<a target="_blank" href="/libraries/sequence/'+name+'">'+name+'</a>',
								fragments: []};
					this.data[name] = {};
					var alndata = homolog.getElementsByTagName('alignment')[0];
					var hsps = alndata.getElementsByTagName('hsp');
					for(var j=0;j<hsps.length;j++) {
						var hsp = Core.parseHSPdata(hsps[j], 'Transcript', 'LibSeq');
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
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'Contig.getSummary',
										      params: {values: 'orf',
								                       contigs: this.sequence.id}},
								     callback: {scope: this,
								                fn: this.parseData,
									            args: ['orf']}});
			} else {
				var contig = root.getElementsByTagName('contig')[0];
				var orf = contig.getElementsByTagName('orf')[0];
				if(orf) {
					var iStart = parseInt(orf.getAttribute('start'), 10);
					var iORFlen = (Core.extractLongText(orf)).length*3;
					var strORFClass = orf.getAttribute('class');
					var strORFDescription = orf.getAttribute('description');
					var fragment = Controls.createORFFragment(strORFClass, strORFDescription, iStart, iORFlen, this.mapdata.length);
					var line = {title: 'ORF outline',
								fragments: [fragment]};
					this.mapdata.lines.unshift(line);
				}
				var map = Controls.createMap(this.mapdata);
				this.wrapper.appendChild(map);
				GUI.toggleInfoMsg(this.msg);
			}
	    }

	    this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('lib-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'lib-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
			alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('lib-alnslider');
			var nSlides = 0;
			for(var i in this.data[name]) {
				var slide = Controls.createHSPSlide(this.data[name][i],
													name + ', HSP '+(parseInt(i,10)+1),
													undefined,
													'lib-content-wrapper',
													{scope: this, fnCallback: this.runBlast, args: [name, i]});
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#lib-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
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
	
  	Views.registerEventHandler('view-lib', new LibraryViewer());
})();