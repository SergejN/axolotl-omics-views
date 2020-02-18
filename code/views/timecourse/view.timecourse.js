/*
	File:
		view.timecourse.js
		
	Description:
		Contains functions of the TimeCourse View.
	
	Version:
        1.12.6
	
	Date:
		28.05.2013
*/

/* Retrieves and displays the timecourse data */
(function() {
	function TimecourseViewer() {

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
								 method: {name: 'TimeCourse.getExperimentsList',
										  params: {sequences: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
        }
        
		this.parseData = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
            var sequence = root.getElementsByTagName('sequence')[0];
			if(!sequence) {
				GUI.displayErrorMsg('No timecourse data are available', this.wrapper);
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
            var categories = sequence.getElementsByTagName('category');
			categories = Array.prototype.slice.call(categories, 0);
			categories.sort(sortByName);
			// Create an initially invisible list of plot placeholders.
			var plotslist = document.createElement('ul');
			plotslist.className = 'timecourse-plotslist';
			
			// Create the drop-down list of experiments grouped by category.
			var ddarea = document.createElement('div');
			ddarea.className = 'dropdown-area expanded';
			var hdr = document.createElement('div');
			var hdrtitle = document.createElement('span');
			hdrtitle.id = 'timecourse-expsummary';
			hdrtitle.className = 'dropdown-area-header';
			hdrtitle.innerHTML = 'No experiments selected. Click here to select experiments.';
			(function(scope, listarea, fnCallback) {
				hdrtitle.addEventListener('click', function(){fnCallback.apply(scope, [listarea]);});
			})(this, ddarea, this.onExpandList);
			hdr.appendChild(hdrtitle);
			ddarea.appendChild(hdr);
			var explist = document.createElement('ul');
            explist.id = 'timecourse-explist';
			// Iterate through the categories.
            for(var i=0;i<categories.length;i++) {
				var strCatName = categories[i].getAttribute('name');
				var item_cat = document.createElement('li');
                var expblock = document.createElement('div');
				expblock.className = 'dropdown-area-block';
                var expname = document.createElement('h2');
                expname.innerHTML = strCatName;
                expblock.appendChild(expname);
				// Iterate through the experiments. Additionally create a separate initially invisible table row for each
				// experiment. Also create a separate plot placeholder for each probe in the experiment (for microarray experiments only).
				var nameslist = document.createElement('ul');
                var experiments = categories[i].getElementsByTagName('experiment');
				experiments = Array.prototype.slice.call(experiments, 0);
				experiments.sort(sortByName);
                for(var j=0;j<experiments.length;j++) {
                    var strExpID = experiments[j].getAttribute('id');
					var strExpName = experiments[j].getAttribute('name');
					var strExpDescr = Core.extractLongText(experiments[j]);
					var item_exp = document.createElement('li');
					var checkbox = document.createElement('input');
					checkbox.setAttribute('type', 'checkbox');
					checkbox.setAttribute('id', 'timecourse-exp-'+strExpID);
					checkbox.setAttribute('expID', strExpID);
					checkbox.setAttribute('state', '0');
					checkbox.setAttribute('hasData', '0');
					// Make closure here, otherwise, checkbox will always be the last added checkbox.
					(function(scope, cb, fnCallback) {
						checkbox.addEventListener('change', function(){fnCallback.apply(scope, [cb]);});
					})(this, checkbox, this.onClickItem);
					var label = document.createElement('label');
					label.setAttribute('for', 'timecourse-exp-'+strExpID);
					label.innerHTML = '<span>'+strExpName + '</span><span class="dropdown-area-tooltip">'+strExpDescr+'</span>';
					item_exp.appendChild(checkbox);
					item_exp.appendChild(label);
					nameslist.appendChild(item_exp);
					
					// Create a new entry in the plots list.
					var item_plotsblock = document.createElement('li');
					item_plotsblock.id = 'timecourse-plotsblock-'+strExpID;
					item_plotsblock.className = 'timecourse-invisible';
					var title = document.createElement('div');
					title.innerHTML = '<h1>'+strExpName+'</h1>'+
									  '<h2>'+strExpDescr+'</h2>'+
									  '<h3>('+experiments[j].getAttribute('date')+' by '+experiments[j].getAttribute('author')+')</h3>';
					item_plotsblock.appendChild(title);
					plotslist.appendChild(item_plotsblock);
                }
				// "Toggle all" item.
				var toggleAll = document.createElement('li');
				toggleAll.className = 'timecourse-toggleall';
				toggleAll.innerHTML = '<span>Toggle all</span>';
				(function(scope, fnCallback, nameslist) {
					toggleAll.addEventListener('click', function(){fnCallback.apply(scope, [nameslist]);});
				})(this, this.onToggleAllClick, nameslist);
				nameslist.appendChild(toggleAll);
				// Add the items list.
				expblock.appendChild(nameslist);
				explist.appendChild(expblock);
            }
			ddarea.appendChild(explist);
			// Add "Apply" and "Cancel" buttons.
			var btnarea = document.createElement('div');
			btnarea.className = 'dropdown-area-btnarea';
			var btn = document.createElement('span');
			btn.className = 'button submit';
			(function(scope, fnCallback, listarea) {
				btn.addEventListener('click', function(){fnCallback.apply(scope, [listarea]);});
			})(this, this.onApply, ddarea);
			btn.innerHTML = 'Apply';
			btnarea.appendChild(btn);
			btn = document.createElement('span');
			btn.className = 'button';
			(function(scope, fnCallback, listarea) {
				btn.addEventListener('click', function(){fnCallback.apply(scope, [listarea]);});
			})(this, this.onCancel, ddarea);
			btn.innerHTML = 'Cancel';
			btnarea.appendChild(btn);
			ddarea.appendChild(btnarea);
			this.wrapper.appendChild(ddarea);
			this.wrapper.appendChild(plotslist);
			GUI.toggleInfoMsg(this.infomsg);
        }
        
        this.onExpandList = function(ddarea) {
			if(ddarea.className == 'dropdown-area expanded') {
				return;
			}
			var checkboxes = ddarea.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				checkboxes[i].checked = checkboxes[i].getAttribute('state')==1;
			}
			ddarea.className = 'dropdown-area expanded';
		}
        
        this.onClickItem = function(checkbox) {
			if(checkbox.checked) {
				this.nSelected++;
			} else {
				this.nSelected--;
			}
			var label = document.getElementById('timecourse-expsummary');
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
        
        this.onToggleAllClick = function(nameslist) {
			var children = nameslist.childNodes;
			for(var i=0;i<children.length;i++) {
				if(children[i].tagName.toLowerCase() == 'li') {
					var firstChild = children[i].firstChild;
					if(firstChild.tagName.toLowerCase() == 'input') {
						firstChild.checked = !firstChild.checked;
						this.onClickItem(firstChild);
					}
				}
			}
		}
        
        this.onCancel = function(ddarea) {
			var checkboxes = ddarea.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				var bOldState = checkboxes[i].getAttribute('state')==1;
				if(checkboxes[i].checked != bOldState) {
					checkboxes[i].checked = bOldState;
					this.onClickItem(checkboxes[i]);
				}
			}
			ddarea.className = 'dropdown-area collapsed';
		}
        
        this.onApply = function(ddarea){
			GUI.toggleInfoMsg(this.infomsg);
			var checkboxes = ddarea.getElementsByTagName('input');
			for(var i=0;i<checkboxes.length;i++) {
				var bOldState = checkboxes[i].getAttribute('state')==1;
				if(checkboxes[i].checked != bOldState) {
					checkboxes[i].setAttribute('state', (checkboxes[i].checked) ? '1' : '');
					this.nRunning++;
					this.toggleExperiment(checkboxes[i]);
				}
			}
			ddarea.className = 'dropdown-area collapsed';
			if(this.nRunning==0) {GUI.toggleInfoMsg(this.infomsg);}
		}
		
		this.toggleExperiment = function(cb) {
			var strExpID = cb.getAttribute('expID');
 			var plotsblock = document.getElementById('timecourse-plotsblock-'+strExpID);
			plotsblock.className = (cb.checked) ? '' : 'timecourse-invisible';
			// If the data was not fetched, yet, do it now. Otherwise, simple decrease the counter and return.
			if(cb.getAttribute('hasData')=='0') {
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'TimeCourse.getExperimentData',
										      params: {experiment: strExpID,
								                       sequence: this.sequence.id}},
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
			var bUseLog = (exp.getAttribute('type').toLowerCase() == 'microarray');
			// 2019-09-02: Prayag asked to label the axis with the natural values instead of the
			// log values.
			bUseLog = false;
			var fnRescale = (bUseLog) ? function(value) {return Math.exp(value)} : function(value) {return value};

			var strExpID = exp.getAttribute('id');
			var plotsblock = document.getElementById('timecourse-plotsblock-'+strExpID);
			var items = root.getElementsByTagName('item');
			for(var i=0;i<items.length;i++) {
				var expplotblock = document.createElement('div');
				expplotblock.className = 'timecourse-expplotblock';
				var title = document.createElement('h4');
				var strItemName = items[i].getAttribute('name');
				if(strItemName) {
					title.innerHTML = strItemName + ' (' + items[i].getAttribute('details') +')';
					expplotblock.appendChild(title);
				}
				var plotWrapper = document.createElement('div');
				plotWrapper.className = 'timecourse-plot-wrapper';
				// Plot placeholder.
				var plot = document.createElement('div');
				plot.id = (strItemName) ? 'timecourse-plot-'+strExpID+'-'+strItemName
										: 'timecourse-plot-'+strExpID;
				plot.className = 'timecourse-plot';
				plotWrapper.appendChild(plot);
				expplotblock.appendChild(plotWrapper);
				plotsblock.appendChild(expplotblock);
				var timepoints = items[i].getElementsByTagName('timepoint');
				var data = {samples: {},
							ticks: []};
				var itemData = [];
				for(var j=0;j<timepoints.length;j++) {
					data.ticks.push([j+1, timepoints[j].getAttribute('label')]);
					var samples = timepoints[j].getElementsByTagName('sample');
					for(var n=0;n<samples.length;n++) {
						var strSample = samples[n].getAttribute('name');
						if(data.samples[strSample] == undefined) {
							data.samples[strSample] = {means: [],
													   top: [],
													   bottom: []};
						}
						var stats = this.calculateStats(samples[n], fnRescale);
						data.samples[strSample].means.push([j+1, stats.mean]);
						data.samples[strSample].top.push([j+1, stats.mean+stats.std]);
						data.samples[strSample].bottom.push([j+1, stats.mean-stats.std]);
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
				options.yaxes = [{position: 'left',
								  axisLabel: items[i].getAttribute('unit'),
								  tickFormatter: function(value, axis){return (new Number(fnRescale(value))).toFixed(1)}}];
				options.pan = {interactive: true};
				$.plot('#'+plot.id,
						   itemData,
					       options);
				(function(scope, fnDisplayValue, bLog) {
					$('#'+plot.id).bind("plothover", function(event, pos, item){fnDisplayValue.apply(scope, [item, fnRescale]);});
				})(this, this.displayValue, fnRescale);
			}
			this.nRunning--;
			if(this.nRunning==0) {GUI.toggleInfoMsg(this.infomsg);}
		}
		
		this.calculateStats = function(sample, fnRescale) {
			var replicates = sample.getElementsByTagName('replicate');
			var values = [];
			var fSum = 0.0;
			for(var i=0;i<replicates.length;i++) {
				let strValue = replicates[i].getAttribute('value');
				if(strValue != "NA") {
					let f = parseFloat(strValue);
					fSum += f;
					values.push(f);
				}
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
		
		this.displayValue = function(item, fnRescale) {
			$("#timecourse-tooltip").remove();
			if(item && item.series.label) {
				var x = item.datapoint[0].toFixed(2),
				y = fnRescale(item.datapoint[1]).toFixed(2);
				showTooltip(item.pageX, item.pageY,	item.series.label + ": " + y);
			}
		}
		
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
		
		this.stringToFloat = function(array) {
			var result = [];
			for(var i=0;i<array.length;i++) {
				result.push(parseFloat(array[i]));
			}
			return result;
		}
    }
    
    Views.registerEventHandler('view-timecourse', new TimecourseViewer());
})();