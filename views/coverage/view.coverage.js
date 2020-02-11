/*
	File:
		view.coverage.js
		
	Description:
		Contains functions of the Isoforms View.
		
	Version:
        1.2.4		
		
	Date:
		21.03.2013
*/

/* Retrieves and displays the coverage information */
(function() {
    function CoverageViewer() {
        
	var PLOT_WIDTH = 650;
	var PLOT_HEIGHT = 200;

	this.nSelected = 0;
	this.nRunning = 0;
		
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
	    this.wrapper.id = 'coverage-content-wrapper';
	    content.appendChild(this.wrapper);
		this.sequence = Core.getCurrentSequence();
		Core.sendAPIRequest2({format: 'xml',
				             requestID: 1,
							 method: {name: 'Mapping.getDatasetsList',
									  params: {sequences: this.sequence.id}},
							 callback: {scope: this,
								        fn: this.parseData}});
    }
	    
	this.parseData = function(data) {
	    var xml = data.responseXML;
	    var root = xml.documentElement;
	    var sequence = root.getElementsByTagName('sequence')[0];
	    if(!sequence) {
			GUI.displayErrorMsg('No mapping details are available', this.wrapper);
			GUI.toggleInfoMsg(this.msg);
			return;
	    }
	    var src = sequence.getAttribute('assembly');
		if(!src)
			src = 'lib';
	    var datasets = sequence.getElementsByTagName('dataset');
	    datasets = Array.prototype.slice.call(datasets, 0);
	    datasets.sort(function(dsA, dsB) {
			// First, compare the experiment name.
			if(dsA.getAttribute('experiment')<dsB.getAttribute('experiment')) {
				return -1;
			} else {
				if(dsA.getAttribute('experiment')>dsB.getAttribute('experiment')) {
					return 1;
				} else {
					return parseInt(dsA.getAttribute('sortindex'),10)-parseInt(dsB.getAttribute('sortindex'),10);
				}
			}});
	    // Create the list of datasets.
	    var ddarea = document.createElement('div');
	    ddarea.className = 'dropdown-area expanded';
	    var hdr = document.createElement('div');
	    var hdrtitle = document.createElement('span');
	    hdrtitle.id = 'coverage-dssummary';
	    hdrtitle.className = 'dropdown-area-header';
	    hdrtitle.innerHTML = 'No datasets selected. Click here to select datasets.';
	    (function(scope, listarea, fnCallback) {
			hdrtitle.addEventListener('click', function(){fnCallback.apply(scope, [listarea]);});
	    })(this, ddarea, this.onExpandList);
	    hdr.appendChild(hdrtitle);
	    ddarea.appendChild(hdr);
	    // First, iterate through the list of datasets and group the datasets by the experiment name. Additionally, also
	    // create a separate initially invisible table row for each dataset plot.
	    var table = document.createElement('table');
	    table.setAttribute('border', '0');
	    table.setAttribute('width', '90%');
	    table.setAttribute('cellspacing', '0');
	    table.setAttribute('cellpadding', '0');
	    table.id = 'coverage-table';
	    table.className = 'coverage-invisible';
	    var header = document.createElement('thead');
	    header.innerHTML = '<tr>'+
			       '<th width="10%">Dataset</th>'+
			       '<th width="75%">Coverage plot</th>'+
			       '<th width="10%">FPKM</th>'+
			       '</tr>';
	    table.appendChild(header);
	    // Dropdown list.
	    var dslist = document.createElement('ul');
	    dslist.id = 'coverage-dslist';
	    var item_exp = undefined;
	    var strCurrentExp = undefined;
	    var nameslist = undefined;
	    var toggleAll = undefined;
	    for(var i=0;i<datasets.length;i++) {
		var strExpName = datasets[i].getAttribute('experiment');
		var strTissue = datasets[i].getAttribute('tissue');
		var strDSName = datasets[i].getAttribute('name');
		var strDSDescr = Core.extractLongText(datasets[i]);
		// Table row.
		var row = document.createElement('tr');
		row.className = 'coverage-invisible';
		row.id = 'coverage-details-'+strDSName;
		// Dataset name.
		var cell = document.createElement('td');
		cell.innerHTML = '<a target="_blank" href="/dataset/'+strDSName+'">'+strDSName+'</a>';
		row.appendChild(cell);
		// Coverage plot.
		cell = document.createElement('td');
		cell.setAttribute('valign', 'middle');
		// Plot.
		var plotWrapper = document.createElement('div');
		plotWrapper.className = 'coverage-plot-wrapper';
		// Plot placeholder.
		var plot = document.createElement('div');
		plot.id = 'coverage-plot-'+strDSName;
		plot.className = 'coverage-plot';
		(function(scope, fnDisplay, strDSName, src) {
			plot.addEventListener('click', function(){fnDisplay.apply(scope, [strDSName, src]);});
		})(this, this.displayMapping, strDSName, src);
		var img = document.createElement('div');
		img.className = 'coverage-plot-placeholder';
		plot.appendChild(img);
		plotWrapper.appendChild(plot);
		cell.appendChild(plotWrapper);
		row.appendChild(cell);
		// FPKM.
		var strFPKM = 'N/A';
		if(datasets[i].getAttribute('fpkm').length>0) {
		    strFPKM = new Number(datasets[i].getAttribute('fpkm')).toFixed(2);
		}
		cell = document.createElement('td');
		cell.innerHTML = strFPKM;
		row.appendChild(cell);
		table.appendChild(row);
		// Since the list of datasets is sorted, create a new block and append the existing one, if any,
		// each time a new experiment name is encountered.
		if(strCurrentExp!=strExpName) {
		    strCurrentExp = strExpName;
		    item_exp = document.createElement('li');
		    var expblock = document.createElement('div');
		    expblock.className = 'dropdown-area-block';
		    var expname = document.createElement('h2');
		    expname.innerHTML = strExpName;
		    expblock.appendChild(expname);
		    nameslist = document.createElement('ul');
		    expblock.appendChild(nameslist);
		    item_exp.appendChild(expblock);
		    dslist.appendChild(item_exp);
		    // Add "Toggle all" element and insert all datasets before it.
		    toggleAll = document.createElement('li');
		    toggleAll.className = 'coverage-toggleall';
		    toggleAll.innerHTML = '<span>Toggle all</span>';
		    (function(scope, fnCallback, nameslist) {
				toggleAll.addEventListener('click', function(){fnCallback.apply(scope, [nameslist]);});
		    })(this, this.onToggleAllClick, nameslist);
		    nameslist.appendChild(toggleAll);
		}
		var item_ds = document.createElement('li');
		var checkbox = document.createElement('input');
		checkbox.setAttribute('type', 'checkbox');
		checkbox.setAttribute('id', 'coverage-ds-'+strDSName);
		checkbox.setAttribute('value', strDSName);
		checkbox.setAttribute('state', '0');
		checkbox.setAttribute('hasData', '0');
		(function(scope, cb, fnCallback) {
		    checkbox.addEventListener('change', function(){fnCallback.apply(scope, [cb]);});
		})(this, checkbox, this.onDatasetClick);
		var label = document.createElement('label');
		label.setAttribute('for', 'coverage-ds-'+strDSName);
		label.innerHTML = '<span>'+strDSDescr+'</span><span class="dropdown-area-tooltip">Tissue: '+strTissue+' (FPKM: '+strFPKM+')</span>';
		item_ds.appendChild(checkbox);
		item_ds.appendChild(label);
		nameslist.insertBefore(item_ds, toggleAll);
	    }
	    ddarea.appendChild(dslist);
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
	    btn.className = 'button cancel';
	    (function(scope, fnCallback, listarea) {
			btn.addEventListener('click', function(){fnCallback.apply(scope, [listarea]);});
	    })(this, this.onCancel, ddarea);
	    btn.innerHTML = 'Cancel';
	    btnarea.appendChild(btn);
	    ddarea.appendChild(btnarea);
	    this.wrapper.appendChild(ddarea);
	    this.wrapper.appendChild(table);
	    GUI.toggleInfoMsg(this.msg);
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
	
	this.onDatasetClick = function(checkbox) {
	    if(checkbox.checked) {
			this.nSelected++;
	    } else {
			this.nSelected--;
	    }
	    var label = document.getElementById('coverage-dssummary');
	    if(this.nSelected==0) {
			label.innerHTML = 'No datasets selected. Click here to select datasets.';
	    } else {
			if(this.nSelected==1) {
				label.innerHTML = 'Single dataset selected. Click here to add more datasets.';
			} else {
			    label.innerHTML = this.nSelected + ' datasets selected. Click here to add/remove datasets.';
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
					this.onDatasetClick(firstChild);
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
			    this.onDatasetClick(checkboxes[i]);
			}
		}
	    ddarea.className = 'dropdown-area collapsed';
	}
	
	this.onApply = function(ddarea){
	    if(this.nRunning==0) {GUI.toggleInfoMsg(this.msg);}
	    var checkboxes = ddarea.getElementsByTagName('input');
	    for(var i=0;i<checkboxes.length;i++) {
			var bOldState = checkboxes[i].getAttribute('state')==1;
			if(checkboxes[i].checked != bOldState) {
				checkboxes[i].setAttribute('state', (checkboxes[i].checked) ? '1' : '');
				this.nRunning++;
				this.togglePlot(checkboxes[i]);
			}
	    }
	    document.getElementById('coverage-table').className = (this.nSelected==0) ? 'coverage-invisible' : '';
	    ddarea.className = 'dropdown-area collapsed';
	    if(this.nRunning==0) {GUI.toggleInfoMsg(this.msg);}
	}
	
	this.togglePlot = function(cb) {
	    var row = document.getElementById('coverage-details-'+cb.value);
	    row.className = (cb.checked) ? '' : 'coverage-invisible';
	    if(cb.getAttribute('hasData')==0) {
			Core.sendAPIRequest2({format: 'xml',
				                  requestID: 1,
								  method: {name: 'Mapping.getCoverageData',
								  		   params: {sequence: this.sequence.id,
										            dataset: cb.value}},
								  callback: {scope: this,
								             fn: this.displayPlot}});
		cb.setAttribute('hasData', '1');
	    } else {
			this.nRunning--;
	    }
	}
	
	this.displayPlot = function(xmldata) {
	    var xml = xmldata.responseXML;
	    var root = xml.documentElement;
		var data = [];
	    var sequence = root.getElementsByTagName('sequence')[0];
		var strDSName = sequence.getAttribute('dataset');
		var tmp = Core.extractLongText(sequence).split(' ');
		for(var i=0;i<tmp.length;i++) {
			data.push([i+1, parseInt(tmp[i])]);
		}
	    document.getElementById('coverage-plot-'+strDSName).innerHTML = '';
	    var options = {series:  {lines: {show: true,
					                     fill: true,
					                     fillColor: {colors: ['rgba(137,137,137,0.7)', 'rgba(120,120,120, 0.5)']},
					                     width: 1}},
			                     colors: ["#5E5E5E"],
			                     grid: {hoverable: true,
				                        autoHighlight: false,
				                        backgroundColor: {colors: ['rgba(229,229,229,0.7)', 'rgba(245,245,245,0.7)']},
				                        borderColor: 'rgb(150,150,150)'},
			                     legend: {backgroundOpacity: 0},
			                     crosshair: {mode: 'x'}};
	    var plot = $.plot('#coverage-plot-'+strDSName,
			      [{data: data, fill: true, label: ' '}],
			      options);
	    var legend = $('#coverage-plot-'+strDSName+' .legendLabel').eq(0);
	    (function(scope, fnDisplayValue, plot, legend) {
			$('#coverage-plot-'+strDSName).bind("plothover", function(event, pos, item){fnDisplayValue.apply(scope, [plot, pos, legend]);});
	    })(this, this.displayValue, plot, legend);
	    this.nRunning--;
	    if(this.nRunning==0) {GUI.toggleInfoMsg(this.msg);}
	}
	
	this.displayMapping = function(dsname, src) {
	    var wrapper = document.createElement('div');
	    wrapper.className = 'coverage-popup';
	    wrapper.innerHTML = '<iframe src="/jbrowse/index.html?tracklist=0&nav=0&loc='+this.sequence.id+':1..200&tracks=DNA,'+src+'_'+dsname+'_coverage,'+src+'_'+dsname+'" />';
		Core.showPopup(wrapper);
	}
	
	this.displayValue = function(plot, pos, legend) {
	    var axes = plot.getAxes();
	    if (pos.x < axes.xaxis.min || pos.x > axes.xaxis.max ||
		pos.y < axes.yaxis.min || pos.y > axes.yaxis.max) {
		return;
	    }
	    var x = Math.round(pos.x)-1;
	    var data = (plot.getData()[0]).data;
	    legend.text('Coverage at position '+x+': '+data[x][1]);
	}
    }
	
    Views.registerEventHandler('view-coverage', new CoverageViewer());
})();
