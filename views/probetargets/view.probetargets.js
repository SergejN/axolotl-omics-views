/*
	File:
		view.probetargets.js
		
	Description:
		Contains functions of the Probe Targets View.
	
	Version:
        1.2.6
	
	Date:
		18.09.2014
*/

/* Retrieves and displays the mapping details of the microarray probe targets */
(function() {
    function ProbeTargetsViewer() {

		this.colors = {'55-60': '#29B34B',
					   '50-54': '#8FD124',
					   '45-49': '#D2B21F',
					   '40-44': '#EEFAB5',
					   '35-39': '#FA9005',
					   '30-34': '#FA2605',
					   'default': '#FA2605'};
	
	
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
            this.wrapper.id = 'probetargets-content-wrapper';
            content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Microarray.getMicroarrayProbeTargets',
										  params: {probes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
        this.parseData = function(data) {
            var xml = data.responseXML;
            var root = xml.documentElement;
            var probe = root.getElementsByTagName('probe')[0];
            if(!probe) {
                GUI.displayErrorMsg('No targets are available for this probe', this.wrapper);
                GUI.toggleInfoMsg(this.msg);
                return;
            }
			var listdata = {style: Controls.GB_LISTSTYLE_NONE,
			                groups: []};
			var categories = probe.getElementsByTagName('category');
			var catdetails = {transcripts: {name: 'Transcripts',
			                                baseURL: '/transcripts/'},
			                  libraries: {name: 'Library sequences',
							              baseURL: '/libraries/sequence/'}};
			for(var i=0;i<categories.length;i++) {
				var cd = catdetails[categories[i].getAttribute('type')];
				if(cd) {
					var group = {name: cd.name,
								 items: []};
					var targets = categories[i].childNodes;
					for(var j=0;j<targets.length;j++) {
						var strTargetName = targets[j].getAttribute('name');
						var nMatches = parseInt(targets[j].getAttribute('matches'), 10);
						var bg = this.createGradient(nMatches);
						var strLabel = '<span class="label" style="background: '+bg+'" title="Matches: '+nMatches+'">'+nMatches+'</span>';
						var strTitle = '<a target="_blank" href="'+cd.baseURL+strTargetName+'">'+strTargetName+'</a>';
						var item = {title: strLabel+strTitle,
									description: ''};
						var strDesc = Core.extractLongText(targets[j]);
						if(strDesc.length>0)
							item.description = strDesc;
						else
							item.description = 'No annotation available';
						if(strDesc.length>100) {
							item.tooltip = strDesc;
							item.description = item.description.substring(0,100) + '&hellip;';
						}
						group.items.push(item);
					}
					listdata.groups.push(group);
				}
			}
			var list = Controls.createList(listdata);
			this.wrapper.appendChild(list);
			GUI.toggleInfoMsg(this.infomsg);
		}
		
		this.createGradient = function(nMatches) {
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
    }
	
    Views.registerEventHandler('view-probetargets', new ProbeTargetsViewer());
})();	