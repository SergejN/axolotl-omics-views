/*
	File:
		view.tsne.js
		
	Description:
		Contains functions of the tSNE viewer.
	
	Version:
        1.0.1
	
	Date:
		13.08.2019
*/


(function() {
	function TSNEViewer() {
		
	    this.wrapper = undefined;
	    this.msg = undefined;

	    this.nSelected = 0;
        this.nRunning = 0;

        this.EMPTY_MSG = 'No experiment selected. Click here to select the experiment';
        this.CLUSTER_COLORS = ["#A6CEE3", "#1F78B4", "#12486B", "#B2DF8A",
                               "#33A02C", "#FB9A99", "#E31A1C", "#660B0C",
                               "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A",
                               "#FFFF99", "#B15928"];
	    
	    // Methods.
	    this.toggleView = function(view, state, msg) {
		    // First, toggle the view content visibility. If the visibility was not turned on, simply return.
		    if(state != 'expanded') {
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
			this.wrapper.id = 'tsne-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                  requestID: 1,
								  method: {name: 'tSNE.getExperimentList',
										   params: {contig: this.sequence.id}},
								  callback: {scope: this,
								             fn: this.parseListData}});
	    }

	    this.parseListData = function(data) {
			// Read the data.
			var xml = data.responseXML;
			var root = xml.documentElement;
			var experiments = root.getElementsByTagName('experiment');
			if(experiments.length == 0) {
				GUI.displayErrorMsg('No tSNE plots are available', this.wrapper);
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
			plotslist.className = 'tsne-plotslist';
			var listdata = {style: Controls.GB_LISTSTYLE_CHECKBOX,
			                groups: []};
			var group = {name: '10X Genomics',
			             items: [],
						 toggle: {title: 'Toggle all',
						          cbClicked: this.onToggleAll,
								  scope: this}};
			this.exp_items = [];
			for(var i=0;i<experiments.length;i++) {
				var exp_id = experiments[i].getAttribute('id');
				var item = {title: experiments[i].getAttribute('name'),
							description: Core.extractLongText(experiments[i]),
							id: 'tsne-'+exp_id,
							attributes: [{name: 'exp_id', value: exp_id},
										 {name: 'hasData', value: 0},
										 {name: 'state', value: 0}],
							name: 'tsne-plot',
							cbChange: this.onClickItem,
							scope: this};
				group.items.push(item);
				this.exp_items.push(item.id);
				// Create a new entry in the plots list.
				var item_plotsblock = document.createElement('li');
				item_plotsblock.id = 'tsne-plotsblock-'+exp_id;
				item_plotsblock.className = 'tsne-invisible';
				var title = document.createElement('div');
				title.innerHTML = '<h1>'+item.title+' ('+experiments[i].getAttribute('reference')+')</h1>'+
								  '<h2>'+item.description+'</h2>'+
								  '<h3>('+experiments[i].getAttribute('date')+' by '+experiments[i].getAttribute('author')+')</h3>';
				item_plotsblock.appendChild(title);
				plotslist.appendChild(item_plotsblock);
			}
			listdata.groups.push(group);
			var list = Controls.createList(listdata);
			this.ddlist = Controls.createDropDownList({content: list,
													   title: '<span id="tsne-listheader">'+this.EMPTY_MSG+'</span>',
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
			var label = document.getElementById('tsne-listheader');
			if(this.nSelected === 0) {
				label.innerHTML = this.EMPTY_MSG;
			} else {
				if(this.nSelected == 1) {
					label.innerHTML = 'Single experiment selected. Click here to add more experiments.';
				} else {
					label.innerHTML = this.nSelected + ' experiments selected. Click here to add/remove experiments.';
				}
			}
		}

		this.onToggleAll = function() {
			for(var i=0;i<this.exp_items.length;i++) {
				var item = document.getElementById(this.exp_items[i]);
				if(item) {
					item.checked = !item.checked;
					this.onClickItem(item);
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
		}

		this.toggleExperiment = function(cb) {
			var strExpID = cb.getAttribute('exp_id');
 			var plotsblock = document.getElementById('tsne-plotsblock-'+strExpID);
			plotsblock.className = (cb.checked) ? '' : 'tsne-invisible';
			// If the data was not fetched, yet, do it now. Otherwise, simple decrease the counter and return.
			if(cb.getAttribute('hasData') == '0') {
				Core.sendAPIRequest2({format: 'xml',
				                      requestID: 1,
								      method: {name: 'tSNE.getCellData',
										      params: {experiment: strExpID,
								                       contig: this.sequence.id}},
								      callback: {scope: this,
								                 fn: this.displayPlot}});
				cb.setAttribute('hasData', '1');
			} else {
				this.nRunning--;
			}
		}

		this.displayPlot = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
			var tmp = root.getElementsByTagName('cells')[0];
			var cells = tmp.getElementsByTagName('cell');
			var strExpID = tmp.getAttribute('experiment');
			tmp = root.getElementsByTagName('clusters')[0];
			tmp = tmp.getElementsByTagName('cluster');
			var clusters = {};
			for(var i=0;i<tmp.length;i++) {
				var color = 'grey';
				var iIndex = Number.parseInt(tmp[i].getAttribute('index'));
				if(iIndex < this.CLUSTER_COLORS.length)
					color = this.CLUSTER_COLORS[iIndex];
				clusters[iIndex] = {name: Core.extractLongText(tmp[i]), 
					                color: color, 
					                count: 0};
			}

			var NUMBER_OF_EXPR_CLASSES = 8;

			var plotarea = document.createElement('div');
			plotarea.className = 'tsne-plotarea';

			var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
			svg.setAttribute('xmlns:svg', "http://www.w3.org/2000/svg");
			svg.setAttribute('xmlns', "http://www.w3.org/2000/svg"); 
			var svgNS = svg.namespaceURI;
			var svgStyles = document.createElementNS(svgNS, 'style');
			svgStyles.setAttribute('type', 'text/css');
			svgStyles.innerHTML = 'circle {r:0.5; stroke-width:0}' +
								  '.e-'+strExpID+'-0 {fill: #ffffff; stroke-width:0.1; stroke: #DADADA}' +
								  '.e-'+strExpID+'-1 {fill: #ffeda0}' +
								  '.e-'+strExpID+'-2 {fill: #fed976}' + 
								  '.e-'+strExpID+'-3 {fill: #feb24c}' + 
								  '.e-'+strExpID+'-4 {fill: #fd8d3c}' + 
								  '.e-'+strExpID+'-5 {fill: #fc4e2a}' + 
								  '.e-'+strExpID+'-6 {fill: #e31a1c}' +
								  '.e-'+strExpID+'-7 {fill: #bd0026}' + 
								  '.e-'+strExpID+'-8 {fill: #800026}';
			var viewbox = {min_x: Number.MAX_VALUE, min_y: Number.MAX_VALUE, max_x: Number.MIN_VALUE, max_y: Number.MIN_VALUE};
			var plotsblock = document.getElementById('tsne-plotsblock-'+strExpID);

			// Sorting function.
			var sortByValue = function(a,b) {
				var valA = Number.parseFloat(a.getAttribute('value'));
				var valB = Number.parseFloat(b.getAttribute('value'));
				return valA - valB;
			};
			cells = Array.prototype.slice.call(cells, 0);
			cells.sort(sortByValue);
			var fMax = Number.parseFloat(cells[cells.length-1].getAttribute('value'));
			var identities = {};

			for(var i=0;i<cells.length;i++) {
				// Determine the max and min X and Y coordinates in order to set up the view box correctly
				if(x < viewbox.min_x)
					viewbox.min_x = x;
				if(x > viewbox.max_x)
					viewbox.max_x = x;
				if(y < viewbox.min_y)
					viewbox.min_y = y;
				if(y > viewbox.max_y)
					viewbox.max_y = y;

				var iCluster = Number.parseInt(cells[i].getAttribute('cluster'));
				clusters[iCluster].count++;
				var x = Number.parseFloat(cells[i].getAttribute('tsne1'));
				var y = Number.parseFloat(cells[i].getAttribute('tsne2'));
				var expr_class = 'e-' + strExpID + '-0';
				var f = Number.parseFloat(cells[i].getAttribute('value'));
				if(f > 0) {
					expr_class = 'e-' + strExpID + '-' + Math.ceil(f*NUMBER_OF_EXPR_CLASSES/fMax);
				}
				var circle = document.createElementNS(svgNS, 'circle');
				circle.setAttribute('cx', x);
				circle.setAttribute('cy', y);
				var strIdentity = cells[i].getAttribute('identity');
				if(!identities[strIdentity])
					identities[strIdentity] = 0;
				identities[strIdentity]++;
				circle.setAttribute('class', 'c-'+strExpID+'-'+iCluster+' ' + expr_class + ' ident-'+strExpID+strIdentity);
				circle.setAttribute('title', 'Cell identity: ' + strIdentity + 
					                         '<br/>' + 
					                         'Cell cluster: ' + clusters[iCluster].name + 
					                         '<br/>' + 
					                         'Cell ID: ' + cells[i].getAttribute('name') + 
					                         '<br/>' +  
					                         'Expression value: ' + f);
				svg.appendChild(circle);
			}

			// Viewbox
			PLOT_MARGIN = 10;
			svg.setAttribute('width', '100%');
			svg.setAttribute('height', 500);
			var vbw = viewbox.max_x - viewbox.min_x + 2*PLOT_MARGIN; // View box width
			var vbh = viewbox.max_y - viewbox.min_y + 2*PLOT_MARGIN; // View box height
			svg.setAttribute('viewBox', '-'+(vbw/2)+' -'+(vbh/2)+' '+vbw+' '+vbh);
			svg.appendChild(svgStyles);
			plotarea.appendChild(svg);
			plotsblock.appendChild(plotarea);

			// Legend
			var plotlegend = document.createElement('div');
			plotlegend.className = 'tsne-plotlegend';
			var title = document.createElement('h3');
			title.innerHTML = 'Clusters';
			plotlegend.appendChild(title);
			var list = document.createElement('ul');
			tmp = Object.keys(clusters).sort(function(a,b) {
								return clusters[a].name.localeCompare(clusters[b].name);
							});
			for(var i=0;i<tmp.length;i++) {
				var legenditem = document.createElement('li');
				legenditem.setAttribute('title', 'Cells in cluster: '+clusters[tmp[i]].count);
				var circle = document.createElement('div');
				circle.className = 'tsne-legend-symbol';
				circle.style.backgroundColor = clusters[tmp[i]].color;
				legenditem.appendChild(circle);
				var text = document.createElement("div");
				text.className = 'tsne-legend-text';
				text.innerHTML = clusters[tmp[i]].name;
				legenditem.appendChild(text);
				legenditem.addEventListener("mouseover", (function(strExpID, c_index, color, svgStyles) { 
												return function(){
													svgStyles.innerHTML += ' .c-' + strExpID+ '-' + c_index + ' {fill:' + color + '}';
												}
											})(strExpID, tmp[i], clusters[tmp[i]].color, svgStyles));
				legenditem.addEventListener("mouseout", (function(strExpID, c_index, color, svgStyles) {
												return function(){
													var regex = ' .c-' + strExpID + '-' + c_index + ' {fill:' + color + '}';
													svgStyles.innerHTML = svgStyles.innerHTML.replace(regex, '');
												}
											})(strExpID, tmp[i], clusters[tmp[i]].color, svgStyles));
				list.appendChild(legenditem);
			}
			plotlegend.appendChild(list);
			// Gradient
			title = document.createElement('h3');
			title.innerHTML = 'Expression gradient';
			plotlegend.appendChild(title);
			var scale = document.createElement('div');
			scale.className = "tsne-scale";
			var minval = document.createElement('div');
			minval.innerHTML = '0';
			scale.appendChild(minval);
			var gradient = document.createElement('div');
			gradient.className = 'tsne-gradient';
			scale.appendChild(gradient);
			var maxval = document.createElement('div');
			maxval.innerHTML = fMax;
			scale.appendChild(maxval);
			plotlegend.appendChild(scale);

			// Identities
			title = document.createElement('h3');
			title.innerHTML = 'Cell Identities';
			plotlegend.appendChild(title);
			var identNames = Object.keys(identities).sort();
			list = document.createElement('ul');
			for(var i=0;i<identNames.length;i++) {
				var item = document.createElement('li');
				item.setAttribute('title', 'Cell number: '+identities[identNames[i]]);
				item.innerHTML = identNames[i];
				item.addEventListener("mouseover", (function(strExpID, strIdentity, svgStyles) { 
											return function(){
												svgStyles.innerHTML += ' .ident-' + strExpID + strIdentity + ' {fill:black;stroke:red}';
											}
										})(strExpID, identNames[i], svgStyles));
				item.addEventListener("mouseout", (function(strExpID, strIdentity, svgStyles) {
											return function(){
												var regex = ' .ident-' + strExpID + strIdentity + ' {fill:black;stroke:red}';
												svgStyles.innerHTML = svgStyles.innerHTML.replace(regex, '');
											}
										})(strExpID, identNames[i], svgStyles));
				list.appendChild(item);
			}
			plotlegend.appendChild(list);

			plotsblock.appendChild(plotlegend);

			$('circle').tooltip({content: function() {return $(this).attr('title');}});
			this.nRunning--;
			if(this.nRunning==0) {GUI.toggleInfoMsg(this.infomsg);}
		}



	}
	
  	Views.registerEventHandler('view-tsne', new TSNEViewer());
})();