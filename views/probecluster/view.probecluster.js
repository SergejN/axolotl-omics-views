/*
	File:
		view.probecluster.js
		
	Description:
		Contains functions of the Probe Cluster View.
	
	Version:
        1.1.2
	
	Date:
		22.09.2014
*/

/* Retrieves and displays profiles probes with similar profiles */
(function() {
    function ProbeClusterViewer() {
    
		this.data = {};
	
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
            this.wrapper.id = 'probecluster-content-wrapper';
            content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'TimeCourse.listExperimentsForProbes',
										  params: {probes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		};
		
        this.parseData = function(data) {
			var sortByName = function(a,b) {
				if(a.getAttribute('name')<b.getAttribute('name')) {
					return -1;
				} else {
					if(a.getAttribute('name')>b.getAttribute('name')) {
						return 1;
					} else {
						return 0;
					}
				}
			};
			
            var xml = data.responseXML;
            var root = xml.documentElement;
            var experiments = root.getElementsByTagName('experiment');
            if(!experiments || experiments.length === 0) {
                GUI.displayErrorMsg('No profiles are available for this probe', this.wrapper);
                GUI.toggleInfoMsg(this.infomsg);
                return;
            }
			experiments = Array.prototype.slice.call(experiments, 0);
			experiments.sort(sortByName);
			var plotslist = document.createElement('ul');
			plotslist.className = 'probecluster-plotslist';
			var listdata = {style: Controls.GB_LISTSTYLE_RADIO,
			                groups: []};
			var group = {name: 'Experiments', items: []};
			for(var i=0;i<experiments.length;i++) {
				var exp_id = experiments[i].getAttribute('id');
				var item = {title: experiments[i].getAttribute('name'),
							description: Core.extractLongText(experiments[i]),
							id: 'probe-cluster-'+exp_id,
							attributes: [{name: 'exp_id', value: exp_id},
										 {name: 'hasData', value: 0},
										 {name: 'state', value: 0}],
							name: 'probe-cluster-experiment'};
				group.items.push(item);
				// Create a new entry in the plots list.
				var item_plotsblock = document.createElement('li');
				item_plotsblock.id = 'probecluster-plotsblock-'+exp_id;
				item_plotsblock.className = 'probecluster-invisible';
				var title = document.createElement('div');
				title.innerHTML = '<h1>'+item.title+'</h1>'+
								  '<h2>'+item.description+'</h2>'+
								  '<h3>('+experiments[i].getAttribute('date')+' by '+experiments[i].getAttribute('author')+')</h3>';
				item_plotsblock.appendChild(title);
				plotslist.appendChild(item_plotsblock);
			}
			listdata.groups.push(group);
			var list = Controls.createList(listdata);
			this.ddlist = Controls.createDropDownList({content: list,
													   title: 'No experiment selected. Click here to select the experiment',
													   cbClicked: this.onExpandList,
													   scope: this,
													   buttons: [{text: 'Apply',
															      style: Controls.GB_BTNSTYLE_SUBMIT,
																  cbClicked: this.onApply,
																  scope: this},
															     {text: 'Cancel',
															      style: Controls.GB_BTNSTYLE_NORMAL,
																  cbClicked: this.onCancel,
																  scope: this}]});
			this.wrapper.appendChild(this.ddlist);
			this.nSelected = 0;
			this.wrapper.appendChild(plotslist);
			GUI.toggleInfoMsg(this.infomsg);
		}
		
		this.onExpandList = function(ddlist) {
			if(ddlist.className == 'dropdown-list') {
				return;
			}
			var checkboxes = ddlist.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				checkboxes[i].checked = checkboxes[i].getAttribute('state')==1;
			}
			ddlist.className = 'dropdown-list';
		}

		this.onCancel = function(btn) {
			var checkboxes = this.ddlist.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				var bOldState = checkboxes[i].getAttribute('state')==1;
				if(checkboxes[i].checked != bOldState) {
					checkboxes[i].checked = bOldState;
					this.onClickItem(checkboxes[i]);
				}
			}
			this.ddlist.className = 'dropdown-list collapsed';
		}
        
        this.onApply = function(btn){
			GUI.toggleInfoMsg(this.infomsg);
			this.nRunning = 0;
			var checkboxes = this.ddlist.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				var bOldState = checkboxes[i].getAttribute('state')==1;
				if(checkboxes[i].checked != bOldState) {
					checkboxes[i].setAttribute('state', (checkboxes[i].checked) ? '1' : '');
					this.nRunning++;
					this.toggleExperiment(checkboxes[i]);
				}
			}
			this.ddlist.className = 'dropdown-list collapsed';
			if(this.nRunning === 0) {GUI.toggleInfoMsg(this.infomsg);}
		};
		
		this.toggleExperiment = function(cb) {
			var exp_id = cb.getAttribute('exp_id');
 			var plotsblock = document.getElementById('probecluster-plotsblock-'+exp_id);
			plotsblock.className = (cb.checked) ? '' : 'probecluster-invisible';
			// If the data was not fetched, yet, do it now. Otherwise, simple decrease the counter and return.
			if(cb.getAttribute('hasData')=='0') {
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'TimeCourse.getProbeData',
										      params: {experiment: exp_id,
								                       probes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseProbeData}});
				cb.setAttribute('hasData', '1');
			} else {
				this.nRunning--;
			}
		}
		
		this.parseProbeData = function(xmldata) {
			alert(xmldata.responseText)
			var xml = xmldata.responseXML;
			var root = xml.documentElement;
			var probe = root.getElementsByTagName('probe')[0];
			var strProbeName = probe.getAttribute('name');
			var exp = root.getElementsByTagName('experiment')[0];
			var strExpID = ''+exp.getAttribute('id');
			// If there are no data for the current experiment, yet, collect them.
			var expdata = this.data[strExpID];
			if(!expdata)
				expdata = this.collectExperimentDetails(exp);
			var probedata = {data: {},
			                 plots: {}};
			var timepoints = exp.getElementsByTagName('timepoint');
			for(var i=0;i<timepoints.length;i++) {
				var tp = timepoints[i];
				var samples = tp.getElementsByTagName('sample');
				for(var j=0;j<samples.length;j++) {
					var sample = samples[j];
					var s_data = probedata.data[sample.getAttribute('name')];
					if(!s_data)
						s_data = {};
					var replicates = sample.getElementsByTagName('replicate');
					for(var n=0;n<replicates.length;n++) {
						var replicate = replicates[n];
						var r_data = s_data[replicate.getAttribute('name')];
						if(!r_data)
							r_data = Core.fillArray(expdata.info.timepoints.length, NaN);
						var iIndex = expdata.info.map[tp.getAttribute('label')];
						r_data[iIndex] = parseFloat(Core.extractLongText(replicate));
						s_data[replicate.getAttribute('name')] = r_data;
					}
					probedata.data[sample.getAttribute('name')] = s_data;
				}
			}
			expdata.probes[strProbeName] = probedata;
			this.data[strExpID] = expdata;
			var plotsblock = document.getElementById('probecluster-plotsblock-'+strExpID);
			this.displayPreviews(strExpID, strProbeName, plotsblock);
		}
		
		this.collectExperimentDetails = function(experiment) {
			var expdata = {info: {timepoints: [],
				                  labels: [],
								  map: {}},
						   probes: {}};
			var timepoints = experiment.getElementsByTagName('timepoint');
			for(var i=0;i<timepoints.length;i++) {
				var tp = timepoints[i];
				expdata.info.timepoints.push(tp.getAttribute('time'));
				expdata.info.labels.push(tp.getAttribute('label'));
				expdata.info.map[tp.getAttribute('label')] = i;
			}
			return expdata;
		}
		
		this.displayPreviews = function(strExpID, strProbeName, parent) {
			var expdata = this.data[strExpID];
			var probedata = expdata.probes[strProbeName];
			for(var sample in probedata.data) {
				var s_data = probedata.data[sample];
				for(var replicate in s_data) {
					var r_data = s_data[replicate];
					var wrapper = document.createElement('div');
					wrapper.id = 'probecluster-preview-'+sample+'-'+replicate;
					this.createPreviewPlot(expdata.info.timepoints, expdata.info.labels, r_data, wrapper);
					parent.appendChild(wrapper);
				}
			}
		}
		
		this.createPreviewPlot = function(timepoints, labels, data, parent) {
			var options = {series: {lines: {show: true, width: 1},
									points: {show: true}},
						   colors: ['rgb(233,124,111)'],
						   grid:   {hoverable: true,
								    autoHighlight: true,
								    backgroundColor: {colors: ['rgba(229,229,229,0.7)', 'rgba(245,245,245,0.7)']},
								    borderColor: 'rgb(150,150,150)'},
						   xaxis:  {autoscaleMargin: 0.1}};
			var plotdata = {data: data};
			plotdata.data = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
			$.plot('#'+parent.id, plotdata, {});
		}
    }
	
    Views.registerEventHandler('view-probecluster', new ProbeClusterViewer());
})();	