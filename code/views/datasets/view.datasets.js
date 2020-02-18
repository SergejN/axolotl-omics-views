/*
	File:
		view.datasets.js
		
	Description:
		Contains functions of the Datasets View.
		
	Version:
        1.4.4
        
	Date:
		30.06.2014
*/

/* Retrieves and displays the datasets coverage details */
(function() {
	function DatasetsViewer() {

		this.data = {};
		this.keycolors = {'0'    : [55, 55, 205],
						  '0.25' : [250, 0, 0],
						  '0.50' : [230, 175, 0],
						  '0.75' : [250, 250, 0],
						  '1'    : [0, 250, 0]};
	
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
			var parent = view.parentNode;
			var content = parent.getElementsByClassName('view-expanded')[0];
			this.wrapper = document.createElement('div');
			this.wrapper.id = 'datasets-content-wrapper';
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
			var datasets = sequence.getElementsByTagName('dataset');
			for(var i=0;i<datasets.length;i++) {
				var ds = {name:   datasets[i].getAttribute('name'),
				          index:  parseInt(datasets[i].getAttribute('sortindex'), 10),
						  type:   datasets[i].getAttribute('type'),
						  fpkm:   (datasets[i].getAttribute('fpkm')!='N/A') ? parseFloat(datasets[i].getAttribute('fpkm')) : 0,
						  descr:  Core.extractLongText(datasets[i])};
				var strExpName = datasets[i].getAttribute('experiment');
				var exp = this.data[strExpName];
				if(!exp) {
					exp = {name: strExpName,
						   desc: Core.extractLongText(datasets[i]),
						   data: [],
						   max:  0};
					this.data[strExpName] = exp;
				}
				exp.data.push(ds);
				if(ds.fpkm>exp.max)
					exp.max = ds.fpkm;
			}
			this.displayOptions();
			this.displayHeatMap(this.sortByFPKM, 'datasets-sort-fpkm');
			this.drawLegend();
		    GUI.toggleInfoMsg(this.msg);
	    }

		this.displayOptions = function(){
			this.toolbar = Controls.createToolbar({title: 'Sort by:',
												   style: Controls.GB_TBSTYLE_FLAT,
												   selected: 'FPKM',
												   items: [{title: 'FPKM',
													 	    id: 'datasets-sort-fpkm',
														    callback: {cbClicked: this.displayHeatMap,
														               cbScope: this,
																	   cbParams: [this.sortByFPKM, 'datasets-sort-fpkm']}},
														   {title: 'Index',
														    id: 'datasets-sort-index',
														    callback: {cbClicked: this.displayHeatMap,
														               cbScope: this,
																	   cbParams: [this.sortByIndex, 'datasets-sort-index']}}]});
			this.wrapper.appendChild(this.toolbar);
		}
		
		this.displayHeatMap = function(fnSort, idSelected) {
			if(!this.plots) {
				this.plots = document.createElement('div');
				this.plots.id = 'datasets-plots';
				this.wrapper.appendChild(this.plots);
			}
			GUI.changeToolbarSelection(this.toolbar, idSelected);
			this.plots.innerHTML = '';
			var experiments = Object.keys(this.data).sort();
			for(var i=0;i<experiments.length;i++) {
				var block = document.createElement('div');
				block.className = 'datasets-exp';
				var hdr = document.createElement('h3');
				hdr.innerHTML = experiments[i];
				block.appendChild(hdr);
				var datasets = this.data[experiments[i]].data.sort(fnSort);
				for(var j=0;j<datasets.length;j++) {
					var item = document.createElement('div');
					item.className = 'expr-item';
					var ds = document.createElement('div');
					ds.className = 'dataset-name';
					ds.innerHTML = datasets[j].name;
					item.appendChild(ds);
					var fpkm = document.createElement('div');
					fpkm.className = 'fpkm';
					var color = this.keycolors[0];
					if(datasets[j].fpkm>0) {
						var ratio = datasets[j].fpkm/this.data[experiments[i]].max;
						var c1 = undefined;
						var c2 = undefined;
						var r = ratio;
						if(ratio<=0.25){
							c1 = this.keycolors['0'];
							c2 = this.keycolors['0.25'];
							r = (0.25-ratio)/0.25;
						} else if(ratio<=0.5){
							c1 = this.keycolors['0.25'];
							c2 = this.keycolors['0.50'];
							r = (0.5-ratio)/0.25;
						} else if(ratio<=0.75){
							c1 = this.keycolors['0.50'];
							c2 = this.keycolors['0.75'];
							r = (0.75-ratio)/0.25;
						} else {
							c1 = this.keycolors['0.75'];
							c2 = this.keycolors['1'];
							r = (1-ratio)/0.25;
						}
						color = [0, 0, 0];
						for(var n=0;n<3;n++) {
							color[n] = c2[n] - Math.round((c2[n]-c1[n])*r);
						}
						fpkm.style.background = 'linear-gradient(to top, rgba('+color.join(',')+',.7) 0%, rgba(250,250,250,0.5) 100%)';
					}
					fpkm.setAttribute('title', datasets[j].descr +': '+datasets[j].fpkm);
					item.appendChild(fpkm);
					block.appendChild(item);
				}
				this.plots.appendChild(block);
			}
		}
		
		this.drawLegend = function(){
			var legend = document.createElement('div');
			legend.id = 'datasets-legend';
			var hdr = document.createElement('h3');
			hdr.innerHTML = 'Legend';
			legend.appendChild(hdr);
			var items = [{title: 'No expression',
						  bg: 'rgb(255,255,255)'},
						 {title: '0%',
						  bg: 'linear-gradient(to top, rgba('+this.keycolors['0'].join(',')+',.7) 0%, rgba(250,250,250,0.5) 100%)'},
						 {title: '25%',
						  bg: 'linear-gradient(to top, rgba('+this.keycolors['0.25'].join(',')+',.7) 0%, rgba(250,250,250,0.5) 100%)'},
						 {title: '50%',
						  bg: 'linear-gradient(to top, rgba('+this.keycolors['0.50'].join(',')+',.7) 0%, rgba(250,250,250,0.5) 100%)'},
						 {title: '75% ',
						  bg: 'linear-gradient(to top, rgba('+this.keycolors['0.75'].join(',')+',.7) 0%, rgba(250,250,250,0.5) 100%)'},
						  {title: '100% ',
						  bg: 'linear-gradient(to top, rgba('+this.keycolors['1'].join(',')+',.7) 0%, rgba(250,250,250,0.5) 100%)'}];
			for(var i=0;i<items.length;i++){
				var line = document.createElement('div');
				line.className = 'line';
				var item = document.createElement('div');
				item.className = 'expr-item';
				item.style.background = items[i].bg;
				line.appendChild(item);
				var title = document.createElement('div');
				title.className = 'expr-title';
				title.innerHTML = items[i].title;
				line.appendChild(title);
				legend.appendChild(line);
			}
			this.wrapper.appendChild(legend);
		}
		
		this.sortByIndex = function(dsA, dsB) {
			return dsA.index-dsB.index;
		}
		
		this.sortByFPKM = function(dsA, dsB) {
			var tmp = dsB.fpkm-dsA.fpkm;
			return (tmp==0) ? dsA.index-dsB.index : tmp;
		}
	}
	
  	Views.registerEventHandler('view-datasets', new DatasetsViewer());
})();