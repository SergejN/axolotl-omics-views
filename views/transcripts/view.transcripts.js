/*
	File:
		view.transcripts.js
		
	Description:
		Contains functions of the Transcripts viewer.
	
	Version:
        1.2.2
	
	Date:
		25.10.2014
*/

/* Retrieves and displays the gene regions details */
(function() {
	function TranscriptsViewer() {
		
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
		    this.wrapper.id = 'transcripts-content-wrapper';
		    content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Gene.listRegions',
										  params: {genes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData,
									        args: ['transcripts']}});
	    }
		
	    this.parseData = function(data, type) {
		    var xml = data.responseXML;
		    var root = xml.documentElement;
			if(type == 'transcripts') {
				var gene = root.getElementsByTagName('gene')[0];
				if(!gene) {
					GUI.displayErrorMsg('No transcripts are annotated for this gene', this.wrapper);
					GUI.toggleInfoMsg(this.msg);
					return;
				}
				var nLength = parseInt(gene.getAttribute('length'), 10);
				var mapdata = {length: nLength,
							   nTicks: 10,
							   lines: []};
				this.transcripts = [];
				var transcripts = gene.getElementsByTagName('region');
				for(var i=0;i<transcripts.length;i++) {
					var tmp = Core.fillArray(nLength, '-');
					this.transcripts.push({name: transcripts[i].getAttribute('name'),
										   start: 1,
										   end: nLength,
										   sequence: tmp.join('')});
					var strRegName = transcripts[i].getAttribute('name');
					if(transcripts[i].getAttribute('type') == 'transcript') {
						var line = {title: '<a target="_blank" href="/transcripts/'+strRegName+'">'+strRegName+'</a>',
									fragments: []};
						var fragments = transcripts[i].getElementsByTagName('fragment');
						for(var j=0;j<fragments.length;j++) {
							var iStart = parseInt(fragments[j].getAttribute('start'), 10);
							var iEnd = parseInt(fragments[j].getAttribute('end'), 10);
							var fragment = {position: {start: iStart, end: iEnd},
											tooltip: 'Fragment: '+iStart+'-'+iEnd};
							line.fragments.push(fragment);
							var tmp = '';
							if(iStart>1)
								tmp += this.transcripts[i].sequence.substring(0, iStart-1);
							tmp += Core.extractLongText(fragments[j]);
							if(iEnd<nLength)
								tmp += this.transcripts[i].sequence.substring(iEnd-1, nLength);
							this.transcripts[i].sequence = tmp;
						}
						mapdata.lines.push(line);
					}
				}
				if(mapdata.lines.length==0) {
					this.displayErrorMsg('No transcripts are annotated for this gene');
					GUI.toggleInfoMsg(this.msg);
				} else {
					var map = Controls.createMap(mapdata);
					this.wrapper.appendChild(map);
					Core.sendAPIRequest2({format: 'xml',
				                         requestID: 1,
								         method: {name: 'Gene.getSummary',
										          params: {genes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData,
									        args: ['gene']}});
				}
			} else if(type == 'gene') {
				var gene = root.getElementsByTagName('gene')[0];
				var msadata = {sequences: this.transcripts,
				               consensus: Core.extractLongText(gene)};
				var msa = Controls.createMultipleAlignment(msadata);
				this.wrapper.appendChild(msa);
				GUI.toggleInfoMsg(this.msg);
			}
	    }
	}
	
  	Views.registerEventHandler('view-transcripts', new TranscriptsViewer());
})();