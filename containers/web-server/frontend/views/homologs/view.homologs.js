/*
	File:
		view.homologs.js
		
	Description:
		Contains functions of the Homologs View.
		
	Version:
        1.8.2	
		
	Date:
		11.02.2013
*/

(function() {
	function HomologsViewer() {

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
			this.wrapper.id = 'homologs-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Contig.getSummary',
										  params: {values: 'orf',
								                   contigs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData,
									        args: ['orf']}});
		}
		
		this.parseData = function(data, step) {
			var xml = data.responseXML;
			var root = xml.documentElement;
			if(step == 'homologs') {
				var contig = root.getElementsByTagName('sequence')[0];
				if(!contig) {
					GUI.displayErrorMsg('No homologs are annotated', this.wrapper);
					GUI.toggleInfoMsg(this.msg);
					return;
				}
				var homologs = contig.getElementsByTagName('homolog');
				for(var i=0;i<homologs.length;i++) {
					var homolog = homologs[i];
					var annotation = homolog.getElementsByTagName('annotation')[0];
					var name = homolog.getAttribute('name');
					var organism = annotation.getAttribute('organism');
					var symbol = annotation.getAttribute('symbol');
					var description = Core.extractLongText(annotation);
					var line = {title: '<a href="http://www.ncbi.nlm.nih.gov/nuccore/'+name+'" target="_blank">'+name+'</a>'+
					                   ' ('+symbol+', '+organism+')',
								fragments: []};
					this.data[name] = {annotation: description + ' ('+symbol+')', hsps: {}};
					var alndata = homolog.getElementsByTagName('alignment')[0];
					var hsps = alndata.getElementsByTagName('hsp');
					for(var j=0;j<hsps.length;j++) {
						var hsp = Core.parseHSPdata(hsps[j], 'Sequence', 'RefSeq');
						var tframe = hsp.sequence.frame;
						var strClassName = undefined;
						var strTooltip = 'Bitscore: ' + hsp.score + ' E-value: ' + hsp.evalue;
						if(this.orf) {
							if(this.orf == tframe) {
								strClassName = 'homology-sameframe';
								strTooltip = 'Bitscore: ' + hsp.score + ' E-value: ' + hsp.evalue + ' (same frame as ORF)';
							} else {
								strClassName = 'homology-otherframe';
								strTooltip = 'Bitscore: ' + hsp.score + ' E-value: ' + hsp.evalue + ' (different frame than ORF)';
							}
						}
						var fragment = {position: {start: hsp.sequence.start, end: hsp.sequence.end},
										type: Controls.GB_SMFRAGMENT_NONE,
										tooltip: strTooltip,
										className: strClassName,
										callback: {scope: this,
												   cbClicked: this.toggleAlignment,
												   cbParams: [name, j]}};
						line.fragments.push(fragment);
						this.data[name].hsps[j]  = hsp;
					}
					this.mapdata.lines.push(line);
				}
				var map = Controls.createMap(this.mapdata);
				this.wrapper.appendChild(map);
				GUI.toggleInfoMsg(this.msg);
			} else {
				var contig = root.getElementsByTagName('contig')[0];
				this.mapdata = {length: parseInt(contig.getAttribute('length'), 10),
				                nTicks: 10,
				                lines: [],
				                sort: Controls.GB_SMSORT_NONE};
				var orf = contig.getElementsByTagName('orf')[0];
				if(orf) {
					var iStart = parseInt(orf.getAttribute('start'), 10);
					var iORFlen = (Core.extractLongText(orf)).length*3;
					var strORFClass = orf.getAttribute('class');
					var strORFDescription = orf.getAttribute('description');
					var fragment = Controls.createORFFragment(strORFClass, strORFDescription, iStart, iORFlen, this.mapdata.length);
					var line = {title: 'ORF outline',
								fragments: [fragment]};
					this.mapdata.lines.push(line);
					this.orf = iStart % 3;
					if((iStart<0) && (Math.abs(this.orf)==0))
						this.orf = -3;
					if(this.orf==0)
						this.orf = 3;
				}
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'Homology.listHomologs',
										      params: {type: 'RefSeq',
								                       values: 'alignment',
													   seqIDs: this.sequence.id}},
								     callback: {scope: this,
								                fn: this.parseData,
									            args: ['homologs']}});
			}
		}
		
		this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('homologs-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'homologs-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
		    alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('homologs-alnslider');
			var nSlides = 0;
			for(var i in this.data[name].hsps) {
				var slide = Controls.createHSPSlide(this.data[name].hsps[i],
													name + ', HSP '+(parseInt(i,10)+1),
													this.data[name].annotation,
													'homologs-content-wrapper',
													{scope: this, fnCallback: this.runBlast, args: [name, i]});
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#homologs-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
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
			Viewer.blastSequence(bLocal, strSeq, 'blastp', 'refseq_protein', 'protein', strJobID);
		}
	}
	
	Views.registerEventHandler('view-homologs', new HomologsViewer());
})();