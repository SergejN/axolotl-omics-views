/*
	File:
		view.microarraydata.js
		
	Description:
		Contains functions of the MicroarrayData View.
	
	Version:
        1.0.1
	
	Date:
		22.02.2018
*/

/* Retrieves and displays the static microarray data */
(function() {
	function MicroarrayDataViewer() {

        this.nSelected = 0;
        this.nRunning = 0;

        this.toggleView = function(view, state, msg) {
			if(state!='expanded') {
				return;
			}
			if(this.wrapper) {
				return;
			}
			this.infomsg = msg;
			GUI.toggleInfoMsg(msg);
			// Create the wrapper element and the content.
			var parent = view.parentNode;
			var content = parent.getElementsByClassName('view-expanded')[0];
			this.wrapper = document.createElement('div');
			this.wrapper.id = 'timecourse-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'MicroarrayData.getExperimentsList',
										  params: {sequences: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
        };
        
		this.parseData = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
            var sequence = root.getElementsByTagName('sequence')[0];
			if(!sequence) {
				GUI.displayErrorMsg('No microarray data are available', this.wrapper);
				GUI.toggleInfoMsg(this.infomsg);
				return;
			}
			var experiments = sequence.getElementsByTagName('experiment');
            if(!experiments || experiments.length === 0) {
                GUI.displayErrorMsg('No microarray data are available for this sequence', this.wrapper);
                GUI.toggleInfoMsg(this.infomsg);
                return;
            }
			
			// Sorting function.
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
			
			experiments = Array.prototype.slice.call(experiments, 0);
			experiments.sort(sortByName);
			
			var plotslist = document.createElement('ul');
			plotslist.className = 'microarraydata-plotslist';
			var listdata = {style: Controls.GB_LISTSTYLE_CHECKBOX,
			                groups: []};
			var group = {name: 'Static microarray experiments',
			             items: [],
						 toggle: {title: 'Toggle all',
						          cbClicked: this.onToggleAll,
								  scope: this}};
			this.exp_items = [];
			for(var i=0;i<experiments.length;i++) {
				var exp_id = experiments[i].getAttribute('id');
				var item = {title: experiments[i].getAttribute('name'),
							description: Core.extractLongText(experiments[i]),
							id: 'microarraydata-'+exp_id,
							attributes: [{name: 'exp_id', value: exp_id},
										 {name: 'hasData', value: 0},
										 {name: 'state', value: 0}],
							name: 'microarraydata-experiment',
							cbChange: this.onClickItem,
							scope: this};
				group.items.push(item);
				this.exp_items.push(item.id);
				// Create a new entry in the plots list.
				var item_plotsblock = document.createElement('li');
				item_plotsblock.id = 'microarraydata-plotsblock-'+exp_id;
				item_plotsblock.className = 'microarraydata-invisible';
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
													   title: '<span id="microarraydata-listheader">No experiment selected. Click here to select the experiment</span>',
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
        };
        
        this.onExpandList = function(ddlist) {
			if(ddlist.className == 'dropdown-list') {
				return;
			}
			var checkboxes = ddlist.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				checkboxes[i].checked = checkboxes[i].getAttribute('state')==1;
			}
			ddlist.className = 'dropdown-list';
		};
        
        this.onClickItem = function(checkbox) {
			if(checkbox.checked) {
				this.nSelected++;
			} else {
				this.nSelected--;
			}
			var label = document.getElementById('microarraydata-listheader');
			if(this.nSelected === 0) {
				label.innerHTML = 'No experiments selected. Click here to select experiments.';
			} else {
				if(this.nSelected == 1) {
					label.innerHTML = 'Single experiment selected. Click here to add more experiments.';
				} else {
					label.innerHTML = this.nSelected + ' experiments selected. Click here to add/remove experiments.';
				}
			}
		};
        
        this.onToggleAll = function() {
			for(var i=0;i<this.exp_items.length;i++) {
				var item = document.getElementById(this.exp_items[i]);
				if(item) {
					item.checked = !item.checked;
					this.onClickItem(item);
				}
			}
		};
        
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
		};
        
        this.onApply = function(btn){
			GUI.toggleInfoMsg(this.infomsg);
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
			var strExpID = cb.getAttribute('exp_id');
 			var plotsblock = document.getElementById('microarraydata-plotsblock-'+strExpID);
			plotsblock.className = (cb.checked) ? '' : 'microarraydata-invisible';
			// If the data was not fetched, yet, do it now. Otherwise, simple decrease the counter and return.
			if(cb.getAttribute('hasData') == '0') {
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'MicroarrayData.getExperimentData',
										      params: {experiment: strExpID,
								                       sequence: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.displayPlots}});
				cb.setAttribute('hasData', '1');
			} else {
				this.nRunning--;
			}
		};
		
		this.displayPlots = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
            var sequence = root.getElementsByTagName('sequence')[0];
			var experiment = sequence.getElementsByTagName('experiment')[0];
			var exp_id = experiment.getAttribute('id');
			var plotsblock = document.getElementById('microarraydata-plotsblock-'+exp_id);
			var probes = experiment.getElementsByTagName('probe');
			// First, collect the list of all possible groups and their respective samples.
			var groupdata = {};
			var groups = experiment.getElementsByTagName('group');
			for(var iGrp=0;iGrp<groups.length;iGrp++) {
				var strGrpName = groups[iGrp].getAttribute('name');
				var _grpdata = groupdata[strGrpName];
				if(!_grpdata)
					_grpdata = {samples: {}};
				var samples = groups[iGrp].getElementsByTagName('sample');
				for(var iSample=0;iSample<samples.length;iSample++) {
					_grpdata.samples[samples[iSample].getAttribute('name')] = parseInt(samples[iSample].getAttribute('index'), 10);
				}
				groupdata[strGrpName] = _grpdata;
			}
			
			var groupNames = Object.keys(groupdata);
			for(var i=0;i<groupNames.length;i++) {
				var tmp = Object.keys(groupdata[groupNames[i]].samples);
				tmp = tmp.sort(function(a,b){return groupdata[groupNames[i]][a] - groupdata[groupNames[i]][b];});
				var tmp2 = {names: tmp, indices: {}};
				for(var j=0;j<tmp.length;j++) {
					tmp2.indices[tmp[j]] = groupdata[groupNames[i]].samples[tmp[j]];
				}
				groupdata[groupNames[i]].samples = tmp2;
			}
			
			for(var iProbe=0;iProbe<probes.length;iProbe++) {
				var probe = probes[iProbe];
				var strProbeName = probe.getAttribute('name');
				var strProbeStrand = probe.getAttribute('strand');
				
				var probeArea = document.createElement('div');
				probeArea.className = 'microarraydata-probe';
				var h4 = document.createElement('h4');
				h4.innerHTML = strProbeName + ' (' + strProbeStrand + ')';
				probeArea.appendChild(h4);
				
				var container = document.createElement('div');
				container.appendChild(probeArea);
				plotsblock.appendChild(container);
				var groupCharts = document.createElement('ul');
				groupCharts.className = 'microarraydata-groupcharts';
				probeArea.appendChild(groupCharts);
				for(i=0;i<groupNames.length;i++) {
					var grpChart = document.createElement('li');
					var grpChartTitle = document.createElement('h4');
					grpChartTitle.innerHTML = groupNames[i];
					grpChart.appendChild(grpChartTitle);
					groupCharts.appendChild(grpChart);
					this.plotGroup(grpChart, 'microarraydata-plot-pr'+iProbe+'_grp'+i, probes[iProbe].childNodes[i], groupdata[groupNames[i]].samples);
				}
			}
			this.nRunning--;
			if(this.nRunning === 0) {GUI.toggleInfoMsg(this.infomsg);}
		};
		
		this.plotGroup = function(grpChart, id, grpData, grpSamples) {
			var options = {series:  {lines: {show: true, width: 1}, points: {show: true, radius: 5}},
						   grid: {hoverable: true, autoHighlight: true, backgroundColor: {colors: ['rgba(229,229,229,0.7)', 'rgba(245,245,245,0.7)']}, borderColor: 'rgb(150,150,150)'},
						   xaxis: {autoscaleMargin: 0.1, ticks: []},
						   legend: {backgroundOpacity: 0},
						   xaxes: [{axisLabel: 'Sample'}],
						   yaxes: [{position: 'left', axisLabel: 'Intensity'}]};
			
			var plotdata = []; 
			var replicates = grpData.childNodes;
			for(var i=0;i<replicates.length;i++) {
				var repdata = [];
				var samples = replicates[i].childNodes;
				for(var j=0;j<samples.length;j++) {
					var strName = samples[j].getAttribute('name');
					var index = grpSamples.indices[strName];
					repdata[index-1] = [index, parseFloat(samples[j].getAttribute('value'))];
					options.xaxis.ticks[index-1] = [index, strName];
				}
				plotdata.push({data:  repdata,
							   label: replicates[i].getAttribute('name')});
			}
			var plot = document.createElement('div');
			plot.id = id;
			plot.className = 'microarraydata-plot';
			grpChart.appendChild(plot);
			$.plot('#'+id, plotdata, options);
			(function(scope, fnDisplayValue) {
				$('#'+id).bind("plothover", function(event, pos, item){fnDisplayValue.apply(scope, [item]);});
			})(this, this.displayValue);
		};
		
		this.displayValue = function(item) {
			$("#timecourse-tooltip").remove();
			if(item && item.series.label) {
				var y = item.datapoint[1].toFixed(2);
				showTooltip(item.pageX, item.pageY,	item.series.label + ": " + y);
			}
		};
		
		function showTooltip(x, y, contents) {
			$("<div id='timecourse-tooltip'>" + contents + "</div>").css({
				position: "absolute",
				display: "none",
				top: y + 5,
				left: x + 5,
				border: "1px solid #fdd",
				padding: "2px",
				"background-color": "#fee",
				opacity: 0.80
			}).appendTo("body").fadeIn(200);
		}
    }
    
    Views.registerEventHandler('view-microarraydata', new MicroarrayDataViewer());
})();