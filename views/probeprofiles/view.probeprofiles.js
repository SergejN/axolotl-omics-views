/*
	File:
		view.probeprofiles.js
		
	Description:
		Contains functions of the Probe Profiles View.
	
	Version:
        1.4.6
		
	Date:
		18.09.2014
*/

/* Retrieves and displays the mapping details of the microarray probe profiles */
(function() {
    function ProbeProfilesViewer() {
    
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
            this.wrapper.id = 'probeprofiles-content-wrapper';
            content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'TimeCourse.listExperimentsForProbes',
										  params: {probes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
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
            if(!experiments || experiments.length==0) {
                GUI.displayErrorMsg('No profiles are available for this probe', this.wrapper);
                GUI.toggleInfoMsg(this.infomsg);
                return;
            }
			experiments = Array.prototype.slice.call(experiments, 0);
			experiments.sort(sortByName);
			var plotslist = document.createElement('ul');
			plotslist.className = 'probeprofiles-plotslist';
			var listdata = {style: Controls.GB_LISTSTYLE_CHECKBOX,
			                groups: []};
			var group = {name: 'Experiments', items: []};
			for(var i=0;i<experiments.length;i++) {
				var exp_id = experiments[i].getAttribute('id');
				var item = {title: experiments[i].getAttribute('name'),
							description: Core.extractLongText(experiments[i]),
							id: 'probe-profile-'+exp_id,
							attributes: [{name: 'exp_id', value: exp_id},
										 {name: 'hasData', value: 0},
										 {name: 'state', value: 0}],
							name: 'probe-profile-'+exp_id,
							cbChange: this.onClickItem,
							scope: this};
				group.items.push(item);
				// Create a new entry in the plots list.
				var item_plotsblock = document.createElement('li');
				item_plotsblock.id = 'probeprofiles-plotsblock-'+exp_id;
				item_plotsblock.className = 'probeprofiles-invisible';
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
													   title: 'No experiment selected. Click here to select experiments',
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
		
		this.onClickItem = function(checkbox) {
			if(checkbox.checked) {
				this.nSelected++;
			} else {
				this.nSelected--;
			}
			var label = this.ddlist.getElementsByTagName('h3')[0];
			if(this.nSelected==0) {
				label.innerHTML = 'No experiments selected. Click here to select experiments.';
			} else {
				if(this.nSelected==1) {
					label.innerHTML = 'Single experiment selected. Click here to add more experiments.';
				} else {
					label.innerHTML = this.nSelected + ' experiments selected. Click here to add/remove experiments.';
				}
			}
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
			if(this.nRunning==0) {GUI.toggleInfoMsg(this.infomsg);}
		}
		
		this.toggleExperiment = function(cb) {
			var exp_id = cb.getAttribute('exp_id');
 			var plotsblock = document.getElementById('probeprofiles-plotsblock-'+exp_id);
			plotsblock.className = (cb.checked) ? '' : 'probeprofiles-invisible';
			// If the data was not fetched, yet, do it now. Otherwise, simple decrease the counter and return.
			if(cb.getAttribute('hasData')=='0') {
				Core.sendAPIRequest2({format: 'xml',
				                      requestID: 1,
								      method: {name: 'TimeCourse.getProbeData',
										       params: {experiment: exp_id,
								                        probes: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.displayPlots}});
				cb.setAttribute('hasData', '1');
			} else {
				this.nRunning--;
			}
		}
		
		this.displayPlots = function(xmldata) {
			// General plot options.
			var options = {series:  {
									 lines: {
												show: true,
												width: 1
											},
									 points: {
										        show: true
											 }
								    },
						   colors: ['rgb(233,124,111)', 'rgb(82,189,195)'],
						   grid: {
									hoverable: true,
									autoHighlight: true,
									backgroundColor: {colors: ['rgba(229,229,229,0.7)', 'rgba(245,245,245,0.7)']},
									borderColor: 'rgb(150,150,150)'
								 },
						   xaxis: {
									autoscaleMargin: 0.1
								  },
						   legend: {
									backgroundOpacity: 0
								   }};
			var xml = xmldata.responseXML;
			var root = xml.documentElement;
			var exp = root.getElementsByTagName('experiment')[0];
			var strExpID = exp.getAttribute('id');
			var plotsblock = document.getElementById('probeprofiles-plotsblock-'+strExpID);
			var plotWrapper = document.createElement('div');
			plotWrapper.className = 'probeprofiles-plot-wrapper';
			// Plot placeholder.
			var plot = document.createElement('div');
			plot.id = 'probeprofiles-plot-'+strExpID;
			plot.className = 'probeprofiles-plot';
			plotWrapper.appendChild(plot);
			plotsblock.appendChild(plotWrapper);
			var data = {samples: {},
						ticks: []};
			var itemData = [];
			var timepoints = exp.getElementsByTagName('timepoint');
			for(var i=0;i<timepoints.length;i++) {
				data.ticks.push([i+1, timepoints[i].getAttribute('label')]);
				var samples = timepoints[i].getElementsByTagName('sample');
				for(var j=0;j<samples.length;j++) {
					var strSample = samples[j].getAttribute('name');
					if(data.samples[strSample] == undefined) {
					data.samples[strSample] = {means: [],
											   top: [],
											   bottom: []};
					}
					var stats = this.calculateStats(samples[j]);
					data.samples[strSample].means.push([i+1, stats.mean]);
					data.samples[strSample].top.push([i+1, stats.mean+stats.std]);
					data.samples[strSample].bottom.push([i+1, stats.mean-stats.std]);
				}
			}
			for(var strSample in data.samples) {
				itemData.push({'data': data.samples[strSample].means,
							   'label': strSample});
				itemData.push({'id': 'bottom_'+strSample,
							   'data': data.samples[strSample].bottom,
							   'points': {'show': false},
							   'lines': {'show': false}});
				itemData.push({'data': data.samples[strSample].top,
							   'lines': {'lineWidth': 0, 'fill': 0.4},
							   'points': {'show': false},
							   'hoverable': false,
							   'fillBetween': 'bottom_'+strSample});
			}
			options.xaxis.ticks = data.ticks;
			options.xaxes = [{axisLabel: 'Timepoint'}];
			options.yaxes = [{position: 'left', axisLabel: 'Intensity (log)'}];
			options.yaxis = {tickFormatter: function(value, axis){return Math.round(Math.exp(value))}};
			options.pan = {interactive: true};
			$.plot('#'+plot.id,
					   itemData,
					   options);
			(function(scope, fnDisplayValue) {
				$('#'+plot.id).bind("plothover", function(event, pos, item){fnDisplayValue.apply(scope, [item]);});
			})(this, this.displayValue);
			this.nRunning--;
			if(this.nRunning==0) {GUI.toggleInfoMsg(this.infomsg);}
		}
		
		this.calculateStats = function(sample) {
			var replicates = sample.getElementsByTagName('replicate');
			var values = [];
			var fSum = 0.0;
			for(var i=0;i<replicates.length;i++) {
				var f = Math.log(parseFloat(Core.extractLongText(replicates[i])));
				fSum += f;
				values.push(f);
			}
			var fMean = fSum/values.length;
			var fStd = 0;
			if(values.length>1) {
				var fSqSum = 0.0;
				for(var i=0;i<values.length;i++) {
					var a = values[i]-fMean;
					fSqSum += a*a;
				}
				fStd = Math.sqrt(fSqSum/(values.length-1));
			}
			return {mean: fMean, std: fStd};
		}
		
		this.displayValue = function(item) {
			$("#probeprofiles-tooltip").remove();
			if(item && item.series.label) {
				var x = item.datapoint[0].toFixed(2),
				y = Math.exp(item.datapoint[1]).toFixed(2);
				showTooltip(item.pageX, item.pageY,	item.series.label + ": " + y);
			}
		}
		
		function showTooltip(x, y, contents) {
			$("<div id='probeprofiles-tooltip'>" + contents + "</div>").css({
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
		
		this.stringToFloat = function(array) {
			var result = [];
			for(var i=0;i<array.length;i++) {
				result.push(parseFloat(array[i]));
			}
			return result;
		}
    }
	
    Views.registerEventHandler('view-probeprofiles', new ProbeProfilesViewer());
})();	