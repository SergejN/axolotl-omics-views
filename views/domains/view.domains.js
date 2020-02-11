/*
	File:
		view.domain.js
		
	Description:
		Contains functions of the Domains View.
		
	Version:
        1.5.4
        
	Date:
		05.06.2014
*/

/* Retrieves and displays the domains annotation */
(function() {
    function DomainsViewer() {
	
		// Variables.
		this.msg = undefined;
		this.wrapper = undefined;
	
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
			this.wrapper.id = 'domains-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Domains.listDomains',
										  params: {sequences: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
		this.parseData = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
			var sequence = root.getElementsByTagName('sequence')[0];
			if(!sequence) {
				GUI.displayErrorMsg('There are no annotated domains for this sequence', this.wrapper);
				GUI.toggleInfoMsg(this.msg);
				return;
			}
			var mapdata = {length: parseInt(sequence.getAttribute('length'), 10),
						   nTicks: 10,
						   lines: [],
						   sort: Controls.GB_SMSORT_NONE};
			// First, add the ORF outline if available.
			var orf = sequence.getElementsByTagName('orf')[0];
			var orfDetails = undefined;
			if(orf) {
				var iStart = parseInt(orf.getAttribute('start'), 10);
				var iORFlen = parseInt(orf.getAttribute('length'), 10)*3;
				var strORFClass = orf.getAttribute('class');
				var strORFDescription = Core.extractLongText(orf);
				var fragment = Controls.createORFFragment(strORFClass, strORFDescription, iStart, iORFlen, mapdata.length);
				var line = {title: 'ORF outline',
							fragments: [fragment],
							className: 'domains-line'};
				mapdata.lines.push(line);
				orfDetails = Core.getORFDetails(iStart);
			}
			// Domains.
			var analyses = sequence.getElementsByTagName('analysis');
			for(var i=0;i<analyses.length;i++) {
				var analysis = analyses[i];
				var domains = analysis.getElementsByTagName('domain');
				for(var j=0;j<domains.length;j++) {
					var domain = domains[j];
					var signature = domain.getElementsByTagName('signature')[0];
					var ips = domain.getElementsByTagName('interpro')[0];
					var strAnalysis = analysis.getAttribute('name');
					var strSigAcc = signature.getAttribute('accession');
					var line = {title: strSigAcc,
								fragments: []};
					var link = this.formatURL(strAnalysis, strSigAcc);
					if(link)
						line.title = '<a target="_blank" href="'+link+'">'+strSigAcc+'</a>';
					line.title += ' (' + strAnalysis + ')';
					var fragment = {position: {start: 0, end: 0},
									type: Controls.GB_SMFRAGMENT_NONE};
					if(ips) {
						fragment.tooltip = Core.extractLongText(ips) + ' (e-value: ' + domain.getAttribute('evalue') + ')';
						fragment.callback = {cbScope: this,
											 cbClicked: this.gotoInterPro,
											 cbParams: [ips.getAttribute('accession')]};
					} else {
						fragment.tooltip = 'Unintegrated signature (e-value: ' + domain.getAttribute('evalue') + ')';
					}
					// Domain position is counted from the beginning of the sequence in a particular frame. Therefore, if the
					// frame is 1-3, simply multiply the start position minus 1 by 3.
					var frame = parseInt(domain.getAttribute('frame'), 10);
					if(frame>0) {
						var ds = parseInt(domain.getAttribute('start'), 10);
						var de = parseInt(domain.getAttribute('end'), 10);
						fragment.position.start = (ds-1)*3+frame-1;
						fragment.position.end = fragment.position.start + (de-ds+1)*3;
					} else {
						var ds = parseInt(domain.getAttribute('start'), 10);
						var de = parseInt(domain.getAttribute('end'), 10);
						fragment.position.start = mapdata.length-(ds-1)*3-(de-ds+1)*3+(-frame-1);
						fragment.position.end = fragment.position.start + (de-ds+1)*3;
					}
					if(orfDetails && ((orfDetails.sense != (frame>0)) || (Math.abs(frame) != orfDetails.frame))) {
						fragment.className = 'domains-difframe';
						if(fragment.tooltip)
							fragment.tooltip = 'Warning: the domain ('+fragment.tooltip+') and the ORF frames do not match';
						else
							fragment.tooltip = 'Warning: the domain and the ORF frames do not match';
					}
					line.fragments.push(fragment);
					mapdata.lines.push(line);
				}
			}
			var map = Controls.createMap(mapdata);
			this.wrapper.appendChild(map);
			GUI.toggleInfoMsg(this.msg);
		}
		
		this.formatURL = function(analysis, accession) {
			analysis = analysis.toLowerCase();
			if(analysis == 'gene3d') {
				return 'http://www.cathdb.info/superfamily/'+accession.replace(/G3DSA:/, '');
			} else if(analysis == 'smart') {
				return 'http://smart.embl-heidelberg.de/smart/do_annotation.pl?BLAST=DUMMY&ACC='+accession;
			} else if(analysis == 'superfamily') {
				return 'http://supfam.cs.bris.ac.uk/SUPERFAMILY/cgi-bin/scop.cgi?ipid='+accession;
			} else if(analysis == 'panther') {
				return 'http://www.pantherdb.org/panther/family.do?clsAccession='+accession;
			} else if(analysis == 'pfam') {
				return 'http://pfam.sanger.ac.uk/family/'+accession;
			} else if(analysis == 'prints') {
				return 'http://www.bioinf.manchester.ac.uk/cgi-bin/dbbrowser/sprint/searchprintss.cgi?display_opts=Prints&category=None&queryform=false&regexpr=off&prints_accn='+accession;
			} else if(analysis == 'prositeprofiles' || analysis == 'prositepatterns') {
				return 'http://www.expasy.org/prosite/'+accession;
			} else {
				return undefined;
			}
		}
		
		this.gotoInterPro = function(acc) {
			window.open('http://www.ebi.ac.uk/interpro/entry/'+acc, '_blank');
		}
	
    }
	
    Views.registerEventHandler('view-domains', new DomainsViewer());
})();