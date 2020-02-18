/*
	File:
		view.sequence.js
		
	Description:
		Contains functions of the Sequence View.
	
	Version:
        1.12.7
		
	Date:
		17.09.2015
*/

/* Retrieves and displays the sequence details */
(function() {
	function SequenceViewer() {
		
		// CONSTANTS.
		const BASES_PER_LINE = 50;
		
		// Variables.
		this.strDNASeq = '';
		this.strORFSeq = '';
		this.strProteinSeq = '';
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
			this.wrapper.id = 'seq-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Contig.getSummary',
										  params: {values: 'sequence,orf',
								                   contigs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
		this.parseData = function(data) {
			// Read the data.
			var xml = data.responseXML;
			var root = xml.documentElement;
			// Contig.
			var contig = root.getElementsByTagName('contig')[0];
			if(!contig) {
				GUI.displayErrorMsg('No data available', this.wrapper);
				GUI.toggleInfoMsg(this.msg);
				return;
			}
			var node = contig.getElementsByTagName('sequence')[0];
			this.strDNASeq = Core.extractLongText(node);
			// ORF. If no ORF is annotated the DNA sequence can still be displayed.
			var orf = contig.getElementsByTagName('orf')[0];
			var iORFStart = 0;
			this.strProteinSeq = '';
			this.strORFSeq = '';
			var strClass = undefined;
			var nCodons = 0;
			var status_text = 'No ORF';
			var status_desc = 'No ORF is annotated to the contig.';
			var strProteinSeq = Core.fillArray(this.strDNASeq.length, ' ').join('');
			if(orf) {
				var iORFStart = parseInt(orf.getAttribute('start'), 10);
				this.strProteinSeq = Core.extractLongText(orf);
				strProteinSeq = this.strProteinSeq;
				// If the start is negative, then the ORF is on the opposite strand. Update the starting position and reverse
				// the protein sequence.
				var bRevCompl = false;
				if(iORFStart<0) {
					iORFStart = this.strDNASeq.length+iORFStart+1-this.strProteinSeq.length*3+1;
					strProteinSeq = strProteinSeq.split('').reverse().join('');
					bRevCompl = true;
				}
				iORFStart--;
				this.strORFSeq = this.strDNASeq.substring(iORFStart, iORFStart+this.strProteinSeq.length*3);
				if(bRevCompl) {
					this.strORFSeq = this.revcompl(this.strORFSeq);
				}
				// Construct the protein sequence padded with spaces.
				var tmp = Core.fillArray(this.strDNASeq.length, ' ');
				while(nCodons<this.strProteinSeq.length) {
					tmp[iORFStart+(nCodons*3)+1] = strProteinSeq.charAt(nCodons);
					nCodons++;
				}
				strProteinSeq = tmp.join('');
				status_text = orf.getAttribute('class');
				status_desc = orf.getAttribute('description');
				strClass = status_text.toLowerCase();
			}
			var status_class = 'label label-red';
			var seq_class = '';
			switch(strClass) {
				case 'predicted': 
					status_class = 'label';
					seq_class = (!bRevCompl) ? 'seq-fw' : 'seq-rv';
					break;
				case 'putative': 
					status_class = 'label label-green';
					seq_class = (!bRevCompl) ? 'seq-fw green' : 'seq-rv green';
					break;
				case 'n-terminal': 
					status_class = 'label label-yellow';
					seq_class = (!bRevCompl) ? 'seq-fw yellow' : 'seq-rv yellow';
					break;
				case 'c-terminal': 
					status_class = 'label label-yellow';
					seq_class = (!bRevCompl) ? 'seq-fw yellow' : 'seq-rv yellow';
					break;
				case 'partial': 
					status_class = 'label label-orange';
					seq_class = (!bRevCompl) ? 'seq-fw yellow' : 'seq-rv yellow';
					break;
				case 'ptc': 
					status_class = 'label label-red';
					seq_class = (!bRevCompl) ? 'seq-fw orange' : 'seq-rv orange';
					break;
			}
			var orf_status = document.createElement('div');
			orf_status.id = "seq_status";
			orf_status.innerHTML = '<span class="'+status_class+'" id="seq_statusname">'+status_text+'</span><span id="seq_statusdescr">'+status_desc+'</span>';
			this.wrapper.appendChild(orf_status);
			// Next, add links for viewing the FASTA sequence.
			var links = document.createElement('div');
			links.className = 'seq-links';
			var list = document.createElement('ul');
			// Label.
			var item = document.createElement('li');
			item.innerHTML = 'FASTA:';
			list.appendChild(item);
			// Complete sequence.
			item = document.createElement('li');
			var btn = this.createButton('Complete sequence', 'orf_showSeq', this.showSequence, this);
			item.appendChild(btn);
			list.appendChild(item);
			if(strClass) {
				// ORF sequence.
				item = document.createElement('li');
				btn = this.createButton('Open reading frame', 'orf_showORF', this.showSequence, this);
				item.appendChild(btn);
				list.appendChild(item);
				// Protein sequence.
				item = document.createElement('li');
				btn = this.createButton('Protein', 'orf_showProt', this.showSequence, this);
				item.appendChild(btn);
				list.appendChild(item);
			}
			links.appendChild(list);
			this.wrapper.appendChild(links);
			
			// BLAST links.
			var blastlinks = document.createElement('div');
			blastlinks.className = 'seq-blast seq-hidden';
			blastlinks.id = 'seq-blast';
			var txt = document.createElement('span');
			txt.innerHTML = 'You can also BLAST the selected sequence ';
			blastlinks.appendChild(txt);
			var locblast = document.createElement('span');
			locblast.className = 'actionlink';
			locblast.innerHTML = 'locally';
			(function(scope, fnCallback) {
                locblast.addEventListener('click', function(){fnCallback.apply(scope, [true]);});
			})(this, this.blastSequence);
			blastlinks.appendChild(locblast);
			txt = document.createElement('span');
			txt.innerHTML = ' or on ';
			blastlinks.appendChild(txt);
			var ncbi = document.createElement('span');
			ncbi.className = 'actionlink';
			ncbi.innerHTML = 'NCBI';
			(function(scope, fnCallback) {
                ncbi.addEventListener('click', function(){fnCallback.apply(scope, [false]);});
			})(this, this.blastSequence);
			blastlinks.appendChild(ncbi);
			this.wrapper.appendChild(blastlinks);
			
			// Sequence field.
			var seq = document.createElement('div');
			seq.id = 'seq-fasta';
			seq.className = 'seq-hidden';
			this.wrapper.appendChild(seq);
			// Add the table element.
			var iORFEnd = iORFStart+nCodons*3;
			var lines = document.createElement('table');
			lines.setAttribute('border', '0');
			this.wrapper.appendChild(lines);
			var pos = 0;
			while(pos<this.strDNASeq.length) {
				var line = document.createElement('tr');
				// Start position.
				var el_start = document.createElement('td');
				el_start.className = 'seq-seqstart';
				el_start.innerHTML = pos+1;
				line.appendChild(el_start);
				// Sequence.
				var el_seq = document.createElement('td');
				el_seq.className = 'seq-sequence';
				var fragments = document.createElement('ul');
				el_seq.appendChild(fragments);
				// Determine the index of the last character of the current line within the original sequence.
				var lastPos = Math.min(pos+BASES_PER_LINE, this.strDNASeq.length);
				while(pos<lastPos) {
					var strClassName = '';
					var seqs = [];
					if(pos<iORFStart) {
						seqs[0] = this.strDNASeq.substring(pos, Math.min(iORFStart, lastPos));
					} else if(pos<lastPos-1 && pos<iORFEnd) {
						seqs[0] = this.strDNASeq.substring(pos, Math.min(iORFEnd, lastPos));
						strClassName = seq_class;
					} else {
						seqs[0] = this.strDNASeq.substring(pos, lastPos);
					}
					seqs[1] = strProteinSeq.substr(pos, seqs[0].length);
					var el_block = document.createElement('li');
					el_block.className = strClassName;
					var el_fragment = document.createElement('ul');
					for(var i=0;i<2;i++) {
						var fragment = document.createElement('li');
						fragment.innerHTML = '<pre>'+seqs[i]+'</pre>';
						el_fragment.appendChild(fragment);
					}
					el_block.appendChild(el_fragment);
					fragments.appendChild(el_block);
					pos+=seqs[0].length;
				}
				line.appendChild(el_seq);
				// End position.
				var el_end = document.createElement('td');
				el_end.className = 'seq-seqend';
				el_end.innerHTML = pos;
				line.appendChild(el_end);
				// Add the line.
				lines.appendChild(line);
			}
			GUI.toggleInfoMsg(this.msg);
		}
		
		this.revcompl = function(strSequence) {
			var tmp = [];
			var pos = 0;
			for(var i=strSequence.length-1;i>=0;i--) {
				switch(strSequence.charAt(i)) {
					case 'A': tmp[pos]='T'; break;
					case 'C': tmp[pos]='G'; break;
					case 'G': tmp[pos]='C'; break;
					case 'T': tmp[pos]='A'; break;
				}
				pos++;
			}
			return tmp.join('');
		}
	
		this.showSequence = function(btn) {
			var field = document.getElementById('seq-fasta');
			var blastlinks = document.getElementById('seq-blast');
			// If the use clicked on the button, which is already pushed, hide the sequence field.
			if(btn.className=='push-button pushed') {
				btn.className='push-button';
				field.innerHTML = '';
				field.className = 'seq-hidden';
				blastlinks.className = 'seq-blast seq-hidden';
			} else {
				if(btn.id=='orf_showSeq') {
					field.innerHTML = this.strDNASeq;
				} else if(btn.id=='orf_showORF') {
					field.innerHTML = this.strORFSeq;
				} else if(btn.id=='orf_showProt') {
					field.innerHTML = this.strProteinSeq;
				} else {
					return;
				}
				var ids = ['orf_showSeq', 'orf_showORF', 'orf_showProt'];
				for(var i=0;i<ids.length;i++) {
					if(btn.id!=ids[i]) {
						var item = document.getElementById(ids[i]);
						if(item) {
							item.className = 'push-button';
						}
					}
				}
				field.className = '';
				btn.className = 'push-button pushed';
				blastlinks.className = 'seq-blast';
			}
		}
		
		this.blastSequence = function(bRunLocally) {
			var elems = [{id:'orf_showSeq',   local_alg: 'blastn',  ncbi_alg: 'blastx',  type: 'nucleotide', db: 'refseq_protein', seq: this.strDNASeq},
					     {id: 'orf_showORF',  local_alg: 'blastn',  ncbi_alg: 'blastx',  type: 'nucleotide', db: 'refseq_protein', seq: this.strORFSeq},
					     {id: 'orf_showProt', local_alg: 'tblastn', ncbi_alg: 'blastp',  type: 'protein',    db: 'refseq_protein', seq: this.strProteinSeq}];
			for(var i=0;i<elems.length;i++) {
				var item = document.getElementById(elems[i].id);
				if(item && (item.className == 'push-button pushed')) {
					var sequence = Core.getCurrentSequence();
					Viewer.blastSequence(bRunLocally,
										 elems[i].seq,
										 ((bRunLocally) ? elems[i].local_alg : elems[i].ncbi_alg),
										 elems[i].db,
										 elems[i].type,
										 'Ax_'+sequence.id);
					return;
				}
			}
		}
		
		this.createButton = function(text, id, fnCallback, scope) {
			var btn = document.createElement('span');
			btn.className = 'push-button';
			btn.id = id;
			btn.innerHTML = text;
			btn.addEventListener('click', function(){fnCallback.apply(scope, [btn]);});
			return btn;
		}
		
		this.predictORF = function() {
			var sequence = Core.getCurrentSequence();
			window.open('/tools/orfprediction?contigID='+sequence.id);
		}
		
		this.reverseComplement = function() {
			var sequence = Core.getCurrentSequence();
			window.open('/tools/revcomp?contigID='+sequence.id);
		}
	}
	
  	Views.registerEventHandler('view-sequence', new SequenceViewer());
})();