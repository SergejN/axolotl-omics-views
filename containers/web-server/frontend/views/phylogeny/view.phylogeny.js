/*
	File:
		view.phylogeny.js
		
	Description:
		Contains functions of the Phylogeny View.
	
	Version:
        1.0.1	
		
	Date:
		18.06.2015
*/

/* Retrieves and displays the phylogeny details */
(function() {
	function PhylogenyViewer() {
		
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
			this.wrapper.id = 'phylogeny-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {type: 'phylogeny',
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
				GUI.displayErrorMsg('No homologous sequences were found', this.wrapper);
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
				var line = {title: '<a target="_blank" href="'+homolog.getAttribute('reference')+'">'+name+'</a>'+
				                   ' ('+parseInt(homolog.getAttribute('length', 10))+'bp)',
							fragments: [],
							version: parseInt(homolog.getAttribute('assembly'), 10)};
				this.data[name] = {source: {name: homolog.getAttribute('source'),
										    organism: homolog.getAttribute('organism'),
										    reference: homolog.getAttribute('reference')},
								   hsps: {}};
				var hsps = alndata.getElementsByTagName('hsp');
				for(var j=0;j<hsps.length;j++) {
					var hsp = Core.parseHSPdata(hsps[j], 'Transcript', 'Homolog');
					var fragment = {position: {start: hsp.sequence.start, end: hsp.sequence.end},
									type: (hsp.hit.frame>0) ? Controls.GB_SMFRAGMENT_FORWARD : Controls.GB_SMFRAGMENT_REVERSE,
									tooltip: 'Bitscore: '+hsp.score + '; E-value: '+hsp.evalue + '; Start: '+hsp.hit.start + '; End: '+hsp.hit.end,
									callback: {scope: this,
											   cbClicked: this.toggleAlignment,
											   cbParams: [name, j]}};
					line.fragments.push(fragment);
					this.data[name].hsps[j]  = hsp;
				}
				mapdata.lines.push(line);
		    }
		    var map = Controls.createMap(mapdata);
		    this.wrapper.appendChild(map);
		    GUI.toggleInfoMsg(this.msg);
		}
		
		this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('phylogeny-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'phylogeny-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
			alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('phylogeny-alnslider');
			var nSlides = 0;
			for(var i in this.data[name].hsps) {
				var slide = Controls.createHSPSlide(this.data[name].hsps[i],
													name + ', HSP '+(parseInt(i,10)+1),
													this.data[name].source.name+' ('+this.data[name].source.organism+')',
													'phylogeny-content-wrapper',
													{scope: this, fnCallback: this.runBlast, args: [name, i]});
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#phylogeny-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
			alnwrapper.className = '';
		    this.lastShown.name = name;
			this.lastShown.index = index;
			GUI.scrollToElement(alnwrapper.id);
	    }
		
		this.runBlast = function(bLocal, name, index) {
			var hspdata = this.data[name].hsps[index];
			var strJobID = name+', HSP '+(parseInt(index,10)+1);
			var strSeq = hspdata.sequence.seq.replace(/-/g, '');
			strSeq = strSeq.replace(/\*/g, 'X');
			Viewer.blastSequence(bLocal, strSeq, 'blastx', 'refseq_protein', 'nucleotide', strJobID);
		}
	}
	
  	Views.registerEventHandler('view-phylogeny', new PhylogenyViewer());
})();