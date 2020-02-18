/*
	File:
		view.microarrayprobes.js
		
	Description:
		Contains functions of the MicroarrayProbes View.
	
	Version:
        1.4.4
        
	Date:
		13.04.2014
*/

/* Retrieves and displays the microarray details */
(function() {
	function MicroarrayProbesViewer() {

		this.colors = {'55-60': '#29B34B',
					   '50-54': '#8FD124',
					   '45-49': '#D2B21F',
					   '40-44': '#EEFAB5',
					   '35-39': '#FA9005',
					   '30-34': '#FA2605',
					   'default': '#FA2605'};
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
			this.wrapper.id = 'microarrayprobes-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Homology.listHomologs',
										  params: {values: 'alignment',
										           type: 'microarray',
								                   seqIDs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData,
									        args: ['probes']}});
		}
		
		this.parseData = function(data, step) {
			var xml = data.responseXML;
		    var root = xml.documentElement;
			if(step == 'probes') {
				var sequence = root.getElementsByTagName('sequence')[0];
				if(!sequence) {
					GUI.displayErrorMsg('No microarray probes mapping data are available', this.wrapper);
					GUI.toggleInfoMsg(this.msg);
					return;
				}
				this.mapdata = {length: parseInt(sequence.getAttribute('length'), 10),
							    nTicks: 10,
							    lines: [],
								sort: Controls.GB_SMSORT_BYLEFTMOST,
								topLine: 0};
				var homologs = sequence.getElementsByTagName('homolog');
				for(var i=0;i<homologs.length;i++) {
					var homolog = homologs[i];
					var name = homolog.getAttribute('name');
					var line = {title: '<a target="_blank" href="/microarray/probe/'+name+'">'+name+'</a>',
								fragments: []};
					this.data[name] = {hsps: {}};
					var alndata = homolog.getElementsByTagName('alignment')[0];
					var hsps = alndata.getElementsByTagName('hsp');
					for(var j=0;j<hsps.length;j++) {
						var hsp = Core.parseHSPdata(hsps[j], 'Sequence', 'Probe');
						var nMatches = hsp.midline.replace(/ /g, '').length;
						var fragment = {position: {start: hsp.sequence.start, end: hsp.sequence.end},
										type: (hsp.hit.frame>0) ? Controls.GB_SMFRAGMENT_FORWARD : Controls.GB_SMFRAGMENT_REVERSE,
										tooltip: 'Matches: '+nMatches,
										callback: {scope: this,
												   cbClicked: this.toggleAlignment,
												   cbParams: [name, j]},
										background: this.generateFragmentBgColor(nMatches)};
						line.fragments.push(fragment);
						this.data[name].hsps[j]  = hsp;	
					}
					this.mapdata.lines.push(line);
				}
				if(this.sequence.type==Core.SequenceType.ST_TRANSCRIPT)
					Core.sendAPIRequest2({format: 'xml',
									     requestID: 1,
									     method: {name: 'Contig.getSummary',
											      params: {values: 'orf',
													       contigs: this.sequence.id}},
									     callback: {scope: this,
												    fn: this.parseData,
												    args: ['orf']}});
				else
				    Core.sendAPIRequest2({format: 'xml',
									     requestID: 1,
									     method: {name: 'Library.getDetails',
											      params: {seqIDs: this.sequence.id}},
									     callback: {scope: this,
												    fn: this.parseData,
												    args: ['orf']}});
			} else {
				var contig = root.getElementsByTagName('contig')[0];
				var orf = (contig) ? contig.getElementsByTagName('orf')[0] : undefined;
				if(orf) {
					var iStart = parseInt(orf.getAttribute('start'), 10);
					var iORFlen = (Core.extractLongText(orf)).length*3;
					var strORFClass = orf.getAttribute('class');
					var strORFDescription = orf.getAttribute('description');
					var fragment = Controls.createORFFragment(strORFClass, strORFDescription, iStart, iORFlen, this.mapdata.length);
					var line = {title: 'ORF outline',
								fragments: [fragment]};
					this.mapdata.lines.unshift(line);
					this.orf = iStart % 3;
					if((iStart<0) && (Math.abs(this.orf)==0))
						this.orf = -3;
					if(this.orf==0)
						this.orf = 3;
				}
				var map = Controls.createMap(this.mapdata);
				this.wrapper.appendChild(map);
				GUI.toggleInfoMsg(this.msg);
			}
		}
		
		this.generateFragmentBgColor = function(nMatches) {
			var color = this.colors['default'];
			if(nMatches>=55)
				color = this.colors['55-60'];
			else if(nMatches>=50)
				color = this.colors['50-54'];
			else if(nMatches>=45)
				color = this.colors['45-49'];
			else if(nMatches>=40)
				color = this.colors['40-44'];
			else if(nMatches>=35)
				color = this.colors['35-39'];
			else if(nMatches>=30)
				color = this.colors['30-34'];
			return 'linear-gradient(to top, '+color+', #FEFEFE) repeat scroll 0% 0% transparent';
		}
		
		this.toggleAlignment = function(name, index) {
		    var alnwrapper = document.getElementById('microarrayprobes-alnwrapper');
		    if(!alnwrapper) {
			    alnwrapper = document.createElement('div');
			    alnwrapper.id = 'microarrayprobes-alnwrapper';
			    this.wrapper.appendChild(alnwrapper);
		    } else if(this.lastShown.name == name && this.lastShown.index == index) {
				alnwrapper.className = 'hidden';
				this.lastShown.name = this.lastShown.index = undefined;
				return;
		    }
			alnwrapper.innerHTML = '';
			var slider = Controls.createSlider('microarrayprobes-alnslider');
			var nSlides = 0;
			for(var i in this.data[name].hsps) {
				var slide = Controls.createHSPSlide(this.data[name].hsps[i],
													name + ', HSP '+(parseInt(i,10)+1),
													this.data[name].annotation,
													'microarrayprobes-content-wrapper');
				slider.appendChild(slide);
				nSlides++;
			}
		    alnwrapper.appendChild(slider);
			$('#microarrayprobes-alnslider').bxSlider({adaptiveHeight: true, startSlide: index, pager: (nSlides>1)});
			alnwrapper.className = '';
		    this.lastShown.name = name;
			this.lastShown.index = index;
			GUI.scrollToElement(alnwrapper.id);
	    }
	}
	
  	Views.registerEventHandler('view-microarrayprobes', new MicroarrayProbesViewer());
})();