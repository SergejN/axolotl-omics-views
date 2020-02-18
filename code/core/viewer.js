/*
	File:
		viewer.js
		
	Description:
		Contains general functions of the viewer module.
		
	Date:
		26.04.2013
*/

(function() {
    function Viewer() {
	    
	// Variables.
	this.plots = {};
	this.nLoading = 0;
	this.infomsg = undefined;

	
	this.checkBookmark = function(xmldata, strClass) {
		if(!strClass)
			strClass = 'transcript';
	    if(!xmldata) {
			var sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'User.getBookmarkDetails',
										  params: {class: strClass,
								                   itemID: sequence.id}},
								 callback: {scope: this,
								            fn: this.checkBookmark,
									        args: [strClass]}});
	    } else {
			var root = xmldata.responseXML.documentElement;
			var bmdata = root.getElementsByTagName('bookmark')[0];
			this.toggleBookmark(undefined, bmdata, strClass);
	    }
	}
		
	this.toggleBookmark = function(xmldata, bmdata, strClass) {
		if(!strClass)
			strClass = 'transcript';
		var sequence = Core.getCurrentSequence();
	    // If xmldata is undefined, then the method was called from this.checkBookmark. In this case set the bookmark icon
	    // according to whether bmdata is defined. Otherwise, examine the result code and toggle the bookmark icon if the code is Core.ERR_OK.
	    if(xmldata) {
			var iCode = xmldata.responseXML.documentElement.getElementsByTagName('resultCode')[0].firstChild.nodeValue;
			if(iCode!=Core.ERR_OK) {
				Core.showMessage('Failed to toggle the bookmark', 'error');
				return;
			}
			var result = Core.sendAPIRequest2({format: 'xml',
				                              requestID: 1,
								              method: {name: 'User.getBookmarkDetails',
										               params: {class: strClass,
								                                itemID: sequence.id}},
											  sync: true});
			bmdata = result.data.documentElement.getElementsByTagName('bookmark')[0];
	    }
	    var bookmark = document.getElementById('viewer-bookmark');
	    var details = document.createElement('div');
	    details.id = 'viewer-bm';
	    var img = document.createElement('img');
	    img.setAttribute('width', '64');
	    img.setAttribute('height', '64');
		var api_data = {format: 'xml',
				        requestID: 1,
						method: {name: 'User.toggleBookmark',
								 params: {class: strClass,
								          itemID: sequence.id}}};
	    if(bmdata) {
			img.src = '/images/pages/viewer/bookmark.png';
			img.setAttribute('alt', 'Bookmarked sequence');
			img.setAttribute('title', 'Click to remove the bookmark');
			api_data.method.params.action = 'remove';
			var info = document.createElement('div');
			info.id = 'viewer-bm-info';
			var comment = document.createElement('input');
			comment.type = 'text';
			comment.id = 'viewer-bm-comment';
			var strComment = bmdata.getAttribute('comment');
			if(strComment) {
				comment.value = strComment;
				if(strComment.length>30)
				comment.style.fontSize = '12px';
			} else {
				comment.placeholder = 'No label. Click to set label';
			}
			comment.setAttribute('original', strComment);
			comment.setAttribute('maxlength', '50');
			(function(scope, fnCallback, strClass) {
				comment.addEventListener('blur', function(){fnCallback.apply(scope, [this, strClass]);});
			})(this, this.editBookmarkComment, strClass);
			info.appendChild(comment);
			var timestamp = document.createElement('div');
			timestamp.id = 'viewer-bm-timestamp';
			timestamp.innerHTML = 'Added on: '+bmdata.getAttribute('timestamp');
			info.appendChild(timestamp);
			details.appendChild(info);
	    } else {
			img.src = '/images/pages/viewer/bookmark_bw.png';
			img.setAttribute('alt', 'Bookmark sequence');
			img.setAttribute('title', 'Click to bookmark current sequence');
			api_data.method.params.action = 'add';
	    }
		api_data.callback = {scope: this,
							 fn: this.toggleBookmark,
							 args: [bmdata, strClass]};
		(function(scope, api_data) {
			img.addEventListener('click', function(){Core.sendAPIRequest2(api_data)});
		})(this, api_data);
	    details.appendChild(img);
	    bookmark.innerHTML = '';
	    bookmark.appendChild(details);
	    if(xmldata)
			Core.showMessage((bmdata) ? 'The bookmark has been set' : 'The bookmark has been removed');
	}
	
	this.editBookmarkComment = function(edit, strClass) {
		if(!strClass)
			strClass = 'transcript';
	    if(edit.value == edit.getAttribute('original'))
			return;
		var sequence = Core.getCurrentSequence();
		var result = Core.sendAPIRequest2({format: 'xml',
										   requestID: 1,
										   method: {name: 'User.toggleBookmark',
											    	params: {action: 'update',
															 class: strClass,
															 comment: edit.value,
															 itemID: sequence.id}},
										   sync: true});
	    if(result.data.documentElement.getElementsByTagName('resultCode')[0].firstChild.nodeValue) {
		Core.showMessage('Bookmark comment successfully updated');
			edit.setAttribute('original', edit.value);
	    } else {
			Core.showMessage('Failed to update the bookmark comment', 'error');
	    }
	    if(edit.value.length>30) {
			edit.style.fontSize = '12px';
	    } else {
			edit.style.fontSize = '14px';
	    }
	}

	this.addToHistory = function(xmldata, values) {
		if(xmldata)
			return;
		var sequence = Core.getCurrentSequence();
		var params = {type: sequence.type,
		              id: sequence.id};
		var keys = Object.keys(values);
		for (var i=0;i<keys.length;i++) {
			params[keys[i]] = values[keys[i]];
		}
		Core.sendAPIRequest2({format: 'xml',
							  requestID: 1,
							  method: {name: 'User.addToHistory',
							           params: params},
							  callback: {scope: this,
							             fn: this.addToHistory,
										 args: []}});
	}
	
	this.blastSequence = function(bRunLocally, strSequence, strAlgorithm, db, dbtype, strJobID, external) {
	    // Create the form.
	    var form = document.createElement('form');
	    form.setAttribute('method', 'POST');
	    form.setAttribute('target', '_blank');
	    form.style.display = 'none';
	    if(bRunLocally) {
			form.setAttribute('action', "/blast");
			form.innerHTML = '<input type="hidden" name="pageid" value="blast" />' +
					 '<input type="hidden" name="algorithm" value="'+strAlgorithm+'" />';
			if(external) {
				form.innerHTML += '<input type="hidden" name="external" value="'+external.source+':'+external.id+'" />';
			} else {
				form.innerHTML += '<input type="hidden" name="query" value=">'+strJobID+'\n'+strSequence+'" />';
			}
	    } else {
			form.setAttribute('enctype', 'multipart/form-data');
			form.setAttribute('action', 'http://blast.ncbi.nlm.nih.gov/Blast.cgi');
			form.innerHTML = '<input type="hidden" name="QUERY" value="'+strSequence+'" />'+
					 '<input type="hidden" name="db" value="'+dbtype+'" />'+
					 '<input type="hidden" name="PROGRAM" value="'+strAlgorithm+'" />'+
					 '<input type="hidden" name="BLAST_PROGRAMS" value="'+strAlgorithm+'" />'+
					 '<input type="hidden" name="DBTYPE" value="gc" />'+
					 '<input type="hidden" name="DATABASE" value="'+db+'" />'+
					 '<input type="hidden" name="JOB_TITLE" value="'+strJobID+'" />'+
					 '<input type="hidden" name="PAGE_TYPE" value="BlastSearch" />';
	    }
	    document.body.appendChild(form);
	    form.submit();
	    document.body.removeChild(form);
	}
		
	this.expandStatsList = function(strName) {
	    var ddlist = document.getElementById('viewer-stats-'+strName);
	    if(ddlist.className == 'dropdown-list') {
		return;
	    }
	    var checkboxes = ddlist.getElementsByTagName('input');
	    for(var i=0;i<checkboxes.length;i++) {
		checkboxes[i].checked = checkboxes[i].getAttribute('state')==1;
	    }
	    ddlist.className = 'dropdown-list';
	}
	
	this.onCancelStatList = function(strName) {
	    var ddlist = document.getElementById('viewer-stats-'+strName);
	    var checkboxes = ddlist.getElementsByTagName('input');
	    for(var i=0;i<checkboxes.length;i++) {
		var bOldState = checkboxes[i].getAttribute('state')==1;
		if(checkboxes[i].checked != bOldState) {
		    checkboxes[i].checked = bOldState;
		}
	    }
	    ddlist.className = 'dropdown-list collapsed';
	}
		
	this.displayStatistics = function(strType, strName) {
	    var msg = document.getElementById('view-infomsg-'+strName);
	    msg.setAttribute('active', '0');
	    var nRunning = 0;
	    GUI.toggleInfoMsg(msg);
	    var ddlist = document.getElementById('viewer-stats-'+strName);
	    var checkboxes = ddlist.getElementsByTagName('input');
	    for(var i=0;i<checkboxes.length;i++) {
		var bOldState = checkboxes[i].getAttribute('state')==1;
		if(checkboxes[i].checked != bOldState) {
		    checkboxes[i].setAttribute('state', (checkboxes[i].checked) ? '1' : '');
		    nRunning++;
		    msg.setAttribute('active', nRunning);
		    this.togglePlot(strType, checkboxes[i], msg);
		}
	    }
	    ddlist.className = 'dropdown-list collapsed';
	    if(msg.getAttribute('active')==0) {GUI.toggleInfoMsg(msg);}
	}
		
	this.togglePlot = function(strType, checkbox, msg) {
	    var strName = checkbox.getAttribute(strType);
	    var type = checkbox.value;
	    var plotblock = document.getElementById('viewer-plotblock-'+strName+'-'+type);
	    plotblock.className = (checkbox.checked) ? 'viewer-plotblock' : 'viewer-plotblock viewer-invisible';
		var api_data = {format: 'xml',
		                requestID: 1,
						method: {name: 'Contig.getSummary',
								 params: {type: type}},
						callback: {scope: this,
								   args: [msg]}};
	    if(checkbox.getAttribute('hasData')==0) {
			if(strType == 'dataset') {
				api_data.method.name = 'Dataset.getStatisticData';
				api_data.method.params.dataset = strName;
				api_data.callback.fn = this.displayDatasetPlot;
				Core.sendAPIRequest2(api_data);
			} else if(strType == 'assembly') {
				api_data.method.name = 'Assembly.getStatisticData';
				api_data.method.params.assembly = strName;
				api_data.callback.fn = this.displayAssemblyPlot;
				Core.sendAPIRequest2(api_data);
			} else if(strType == 'collection') {
				api_data.method.name = 'ReadsCollection.getStatisticData';
				api_data.method.params.collectionID = strName;
				api_data.callback.fn = this.displayReadsCollectionPlot;
				Core.sendAPIRequest2(api_data);
			} else if(strType == 'library') {
				api_data.method.name = 'Library.getStatisticData';
				api_data.method.params.libID = strName;
				api_data.callback.fn = this.displayLibraryPlot;
				Core.sendAPIRequest2(api_data);
			} 
			checkbox.setAttribute('hasData', '1');
		} else {
			var nRunning = msg.getAttribute('active');
			nRunning--;
			msg.setAttribute('active', nRunning);
	    }
	}
		
	this.displayAssemblyPlot = function(xmldata, msg) {
	    var xml = xmldata.responseXML;
	    var root = xml.documentElement;
	    var stat = root.getElementsByTagName('statistic')[0];
	    var strName = stat.getAttribute('assembly');
	    var type = stat.getAttribute('type');
	    var plotdata = [];
	    var plotopt = {};
	    if(type == 'gc') {
			var items = root.getElementsByTagName('content');
			var data = Core.fillArray(items.length, undefined);
			for(var i=0;i<items.length;i++) {
				var pc = parseInt(items[i].getAttribute('percent'), 10);
				var nCount = parseInt(items[i].getAttribute('count'), 10);
				data[pc] = [pc, nCount];
			}
			plotdata.push({data: data});
			plotopt.xaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.xaxes = [{axisLabel: 'Per cent GC'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
		}
		if(type == 'homology') {
			var items = root.getElementsByTagName('range');
			for(var i=0;i<items.length;i++) {
				var pc = parseFloat(items[i].getAttribute('fraction'))*100;
				plotdata.push({label: items[i].getAttribute('name')+' ('+items[i].getAttribute('e-value')+')',
					   data: pc});
			}
			plotopt.series = {pie: {show: true,
							radius: 1}};
			plotopt.legend = {show: true};
		}
		if(type == 'orf') {
			var items = root.getElementsByTagName('orf');
			for(var i=0;i<items.length;i++) {
				var pc = parseFloat(items[i].getAttribute('fraction'))*100;
				plotdata.push({label: items[i].getAttribute('type')+' ('+items[i].getAttribute('count')+', '+(new Number(pc).toFixed(1))+'%)',
					   data: pc});
			}
			plotopt.series = {pie: {show: true,
						radius: 1}};
			plotopt.legend = {show: true};
	    }
		if(type == 'moltype') {
			var items = root.getElementsByTagName('molecule');
			for(var i=0;i<items.length;i++) {
				var pc = parseInt(items[i].getAttribute('count'));
				plotdata.push({label: items[i].getAttribute('type')+' ('+items[i].getAttribute('count')+')',
					          data: pc});
			}
			plotopt.series = {pie: {show: true,
						     radius: 1}};
			plotopt.legend = {show: true};
	    }
	    if(type == 'refseqcov') {
			var organisms = root.getElementsByTagName('organism');
			var nOrganisms = organisms.length;
			var data = {'No homologs': Core.fillArray(nOrganisms, 0)};
			var orgnames = [];
			var clnames = [[1, 'No homologs']];
			for(var i=0;i<nOrganisms;i++) {
				orgnames.push(organisms[i].getAttribute('name'));
				var nTotal = parseInt(organisms[i].getAttribute('sequences'), 10);
				var nUncovered = nTotal;
				var classes = organisms[i].getElementsByTagName('class');
				for(var j=0;j<classes.length;j++) {
					var cc = data[classes[j].getAttribute('type')];
					if(cc === undefined) {
						cc = Core.fillArray(nOrganisms, 0);
						data[classes[j].getAttribute('type')] = cc;
						clnames.push([j+2, classes[j].getAttribute('type')]);
					}
					var nCount = parseInt(classes[j].getAttribute('count'), 10);
					cc[i] = nCount/nTotal*100;
					nUncovered -= nCount;
				}
				data['No homologs'][i] = nUncovered/nTotal*100;
			}
			var barwidth = 0.1;
			var bargap = 0.01;
			var offset = -((nOrganisms*barwidth)+(nOrganisms-1)*bargap)/2;
			for(var i=0;i<orgnames.length;i++) {
				var od = [];
				for(var j=0;j<clnames.length;j++) {
				var cc = data[clnames[j][1]];
					od.push([j+1+offset+i*(barwidth+bargap), cc[i]]);
				}
				plotdata.push({label: orgnames[i],
					           data: od,
					           bars: {show: true,
						              barWidth: .1,
						              fill: true,
						              fillColor: {colors: [{opacity: 1}, {opacity: 0.9}]},
						       lineWidth: 0,
						       order: i+1}});
			}
			plotopt.xaxis = {tickLength: 0,
					         autoscaleMargin: 0.2,
					         ticks: clnames};
			plotopt.yaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.xaxes = [{axisLabel: 'Homology type'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Proportion of transcripts'}];
	    }
	    if(type == 'seqlen' || type == 'orflen') {
			var items = root.getElementsByTagName('bin');
			var data = [];
			var iMin = undefined;
			var iMax = undefined;
			for(var i=0;i<items.length;i++) {
				var nLength = parseInt(items[i].getAttribute('value'), 10);
				var nCount = parseInt(items[i].getAttribute('count'), 10);
				if(!iMin)
				iMin = nLength;
				iMax = nLength;
				data.push([nLength, nCount]);
			}
			plotdata.push({data: data, bars: {show: true}});
			plotopt.xaxes = [{axisLabel: 'Length'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
			plotopt.xaxis = {min: iMin-50, max: iMax+50};
	    }
	    if(type == 'codons') {
			var columns = new Array();
			for(var i=0;i<4;i++) {
				columns[i] = document.createElement('div');
				columns[i].className = 'viewer-aacolumn';
			}
			var colors = {'normal'           : 'linear-gradient(to right, rgba(16,227,55,0.7), rgba(16,227,170,0.7))',		// Green: 0.75<=RATIO<=1.25
					  'underrepresented' : 'linear-gradient(to right, rgba(235,133,15,0.7), rgba(229,175,105,0.7))',	// Orange: RATIO<0.75
					  'overrepresented'  : 'linear-gradient(to right, rgba(7,50,222,0.7), rgba(145,170,222,0.7))'};		// Blue: RATIO>1.25
			var aminoacids = root.getElementsByTagName('aminoacid');
			var iIndex = 0;
			for(var i=0;i<aminoacids.length;i++) {
				var aablock = document.createElement('div');
				aablock.className = 'viewer-aablock';
				var name = document.createElement('h4');
				if(aminoacids[i].getAttribute('TLC').length>0) {
					name.innerHTML = aminoacids[i].getAttribute('name') + ' ('+aminoacids[i].getAttribute('TLC')+', '+aminoacids[i].getAttribute('OLC')+')';
				} else {
					name.innerHTML = aminoacids[i].getAttribute('name');
				}
				aablock.appendChild(name);
				var codons = aminoacids[i].getElementsByTagName('codon');
				for(var j=0;j<codons.length;j++) {
					var fFreq = parseFloat(codons[j].getAttribute('frequency'));
					var exp = 1.0/codons.length;
					var ratio = fFreq/exp;
					fFreq *= 100;
					var strFreq = (new Number(fFreq)).toFixed(1);
					fFreq = Math.floor(fFreq);
					var bg = colors.normal + ' 0 0 / '+fFreq+'px 100% no-repeat';
					if(ratio<0.75) {
						bg = colors.underrepresented + ' 0 0 / '+fFreq+'px 100% no-repeat';
					} else if(ratio>1.25) {
						bg = colors.overrepresented + ' 0 0 / '+fFreq+'px 100% no-repeat';
					}
					var codon = document.createElement('div');
					codon.className = 'viewer-codon';
					codon.innerHTML = '<div class="viewer-codon-seq">'+codons[j].getAttribute('sequence')+'</div>'+
							  '<div class="viewer-codon-freq" style="background: '+bg+'">'+strFreq+'%</div>';
					aablock.appendChild(codon);
				}
				columns[iIndex].appendChild(aablock);
				iIndex++;
				if(iIndex==4)
					iIndex = 0;
			}
			var wrapper = document.createElement('div');
			wrapper.className = 'viewer-aawrapper';
			for(var i=0;i<4;i++)
				wrapper.appendChild(columns[i]);
			// Legend.
			var legend = document.createElement('div');
			legend.className = 'viewer-aalegend';
			legend.innerHTML =  '<h4>Legend</h4>'+
								'<div class="viewer-aalegend-item" style="background: '+colors.normal+' no-repeat">Expected</div>'+
									'<div class="viewer-aalegend-item" style="background: '+colors.underrepresented+' no-repeat">Underrepresented</div>'+
								'<div class="viewer-aalegend-item" style="background: '+colors.overrepresented+' no-repeat">Overrepresented</div>';
			wrapper.appendChild(legend);
			var ph = document.getElementById('viewer-placeholder-'+strName+'-'+type);
			var php = ph.parentNode;
			php.innerHTML = '';
			php.className = 'viewer-placeholder-wrapper noplot';
			php.appendChild(wrapper);
	    }
	    if(plotdata.length>0)
			$.plot($('#viewer-placeholder-'+strName+'-'+type), plotdata, plotopt);
	    // Info message.
	    var nRunning = msg.getAttribute('active');
	    nRunning--;
	    msg.setAttribute('active', nRunning);
	    if(nRunning==0) {GUI.toggleInfoMsg(msg);}
	}
		
	this.displayDatasetPlot = function(xmldata, msg) {
	    var xml = xmldata.responseXML;
	    var root = xml.documentElement;
	    var stat = root.getElementsByTagName('statistic')[0];
	    var strName = stat.getAttribute('dataset');
	    var type = stat.getAttribute('type');
	    var plotdata = [];
	    var plotopt = {};
	    if(type == 'quality') {
		var ends = root.getElementsByTagName('end');
		var nGroups = ends.length;
		var labels = [];
		var offsets = (nGroups>1) ? [-0.2, 0.2] : [0];
		for(var i=0;i<nGroups;i++) {
		    var ranges = ends[i].getElementsByTagName('range');
		    var data_real = [];
		    var data_cover = [];
		    var data_err = [];
		    for(var j=0;j<ranges.length;j++) {
			if(i==0) {
			    var strLabel = ranges[j].getAttribute('positions');
			    if((strLabel.length>4) && (j%2==0))
				strLabel = '';
			    labels.push([j+1, strLabel]);
			}
			var val_bottom = parseFloat(ranges[j].getAttribute('quartile_25'));
			var val_top = parseFloat(ranges[j].getAttribute('quartile_75'));
			var val_lo = parseFloat(ranges[j].getAttribute('percentile_10'));
			var val_hi = parseFloat(ranges[j].getAttribute('percentile_90'));
			var val_med = parseFloat(ranges[j].getAttribute('median'));
			data_real.push([j+1+offsets[i], val_top-val_bottom]);
			data_cover.push([j+1+offsets[i], val_bottom]);
			data_err.push([j+1+offsets[i], val_med, val_med-val_lo, val_hi-val_med+0.01]);
		    }
		    plotdata.push({data: data_cover,
				   bars: {show: true,
					  fill: false},
					  stack: true});
		    plotdata.push({data: data_err,
				   stack: false,
		    	           lines: {show: false, lineWidth: 0.5},
					   points: {radius: 0,
						    errorbars: "y", 
				    		    yerr: {asymmetric: true, show:true, upperCap: "-", lowerCap: "-", radius: 2}}});
		    plotdata.push({data: data_real,
				   label: ends[i].getAttribute('type'),
				   bars: {show: true},
				   stack: true});
		}
		plotopt.xaxis = {minTickSize: 1,
				 autoscaleMargin: 0.01,
				 ticks: labels};
		plotopt.series = {bars: {barWidth: (nGroups>1) ? 0.35 : 0.7,
					 lineWidth: 0,
					 align: "center",
					 fillColor: {colors: [{opacity: 1}, {opacity: 1}]}}};
		plotopt.colors = ['rgb(0,0,0)','rgba(50,50,50, 0.5)','rgb(233,134,111)',
				  'rgb(0,0,0)', 'rgba(50,50,50, 0.5)', 'rgb(82,189,195)'];
		plotopt.xaxes = [{axisLabel: 'Position'}];
		plotopt.yaxes = [{position: 'left', axisLabel: 'Fred score'}];
	    }
	    if(type == 'gc') {
			var ends = root.getElementsByTagName('end');
			for(var i=0;i<ends.length;i++) {
				var items = ends[i].getElementsByTagName('content');
				var data = Core.fillArray(items.length, undefined);
				for(var j=0;j<items.length;j++) {
				var pc = parseInt(items[j].getAttribute('percent'), 10);
				var nCount = parseInt(items[j].getAttribute('count'), 10);
				data[pc] = [pc, nCount];
				}
				plotdata.push({label: ends[i].getAttribute('type'),
					   data: data});
			}
			plotopt.xaxis = {autoscaleMargin: 0.05,
					 tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.colors = ['rgb(233,124,111)', 'rgb(82,189,195)'];
			plotopt.xaxes = [{axisLabel: 'Per cent GC'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
	    }
	    if(type == 'bases') {
			var ends = root.getElementsByTagName('end');
			var labels = [];
			for(var i=0;i<ends.length;i++) {
				var items = ends[i].getElementsByTagName('range');
				var data = {'A' : Core.fillArray(items.length, undefined),
					'C' : Core.fillArray(items.length, undefined),
					'G' : Core.fillArray(items.length, undefined),
					'T' : Core.fillArray(items.length, undefined)};
				var bases = ['A', 'C', 'G', 'T'];
				for(var j=0;j<items.length;j++) {
				for(var b=0;b<bases.length;b++)
					data[bases[b]][j] = [j, parseFloat(items[j].getAttribute(bases[b]))];
				if(i==0) {
					var strLabel = items[j].getAttribute('positions');
					if((strLabel.length>4) && (j%2==0))
					strLabel = '';
					labels.push([j, strLabel]);
				}	    
				}
				for(var b=0;b<bases.length;b++) {
				plotdata.push({label: ends[i].getAttribute('type')+', '+bases[b],
						   data: data[bases[b]]});
				}
			}
			plotopt.xaxis = {autoscaleMargin: 0.02,
					 ticks: labels,
					 labelAngle: 45};
			plotopt.yaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.colors = ['rgb(250,0,0)', 'rgb(0,250,0)', 'rgb(0,0,250)', 'rgb(250,250,0)',
					  'rgb(125,0,0)', 'rgb(0,125,0)', 'rgb(0,0,125)', 'rgb(125,125,0)'];
			plotopt.xaxes = [{axisLabel: 'Position'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Proportion'}];
	    }
	    if(type == 'duplication') {
			var ends = root.getElementsByTagName('end');
			var labels = undefined;
			for(var i=0;i<ends.length;i++) {
				var items = ends[i].getElementsByTagName('reads');
				if(i==0)
				labels = Core.fillArray(items.length, undefined);
				var data = Core.fillArray(items.length, undefined);
				for(var j=0;j<items.length;j++) {
				var cn = items[j].getAttribute('copynumber');
				var cnv = parseInt(cn, 10);
				var fValue = parseFloat(items[j].getAttribute('proportion'))*100;
				if(isNaN(cnv))
					cnv = items.length;
				cnv -= 1;	
				data[cnv] = [cnv, fValue];
				if(i==0)
					labels[cnv] = [cnv, cn];
				}
				plotdata.push({label: ends[i].getAttribute('type'),
					   data: data});
			}
			plotopt.xaxis = {autoscaleMargin: 0.02,
					ticks: labels};
			plotopt.yaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.colors = ['rgb(233,124,111)', 'rgb(82,189,195)', 'rgb(233,189,150)'];
			plotopt.xaxes = [{axisLabel: 'Repeat count'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Proportion of reads'}];
	    }
	    if(type == 'mapping') {
			var nReads = parseInt(stat.getAttribute('reads'),10);
			var assemblies = root.getElementsByTagName('assembly');
			var data_c = [];
			var data_m = [];
			var data_u = [];
			var names = [];
			for(var i=0;i<assemblies.length;i++){
				var nContigs = parseInt(assemblies[i].getAttribute('contigs'),10);
				var nUsed = parseInt(assemblies[i].getAttribute('used'),10);
				var nMapped = parseInt(assemblies[i].getAttribute('mapped'),10);
				var nCovered = parseInt(assemblies[i].getAttribute('covered'),10);
				data_u.push([i+1-0.16, nUsed/nReads*100]);
				data_m.push([i+1-0.05, nMapped/nReads*100]);
				data_c.push([i+1+0.06, nCovered/nContigs*100]);
				names.push([i+1, assemblies[i].getAttribute('name')]);
			}
			plotdata.push({label: 'Used',
					   data: data_u,
					   bars: {show: true,
						  barWidth: .1,
						  fill: true,
						 lineWidth: 0,
						 order: 1}});
			plotdata.push({label: 'Mapped',
					   data: data_m,
					   bars: {show: true,
						  barWidth: .1,
						  fill: true,
						  lineWidth: 0,
						  order: 2}});
			plotdata.push({label: 'Covered',
					   data: data_c,
					   bars: {show: true,
						  barWidth: .1,
						  fill: true,
						  lineWidth: 0,
						  order: 3}});
			plotopt.xaxis = {tickLength: 0,
					 autoscaleMargin: 0.5,
					 ticks: names};
			plotopt.yaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.colors = ['rgb(32,15,225)', 'rgb(35,220,35)', 'rgb(150,15,50)'];
	    }
	    $.plot($('#viewer-placeholder-'+strName+'-'+type), plotdata, plotopt);
	    // Info message.
	    var nRunning = msg.getAttribute('active');
	    nRunning--;
	    msg.setAttribute('active', nRunning);
	    if(nRunning==0) {GUI.toggleInfoMsg(msg);}
	}
		
	this.displayReadsCollectionPlot = function(xmldata, msg) {
	    var xml = xmldata.responseXML;
	    var root = xml.documentElement;
	    var stat = root.getElementsByTagName('statistic')[0];
	    var strName = stat.getAttribute('collection');
	    var type = stat.getAttribute('type');
	    var plotdata = [];
	    var plotopt = {};
	    if(type == 'gc') {
			var items = root.getElementsByTagName('content');
			var data = Core.fillArray(items.length, undefined);
			for(var i=0;i<items.length;i++) {
				var pc = parseInt(items[i].getAttribute('percent'), 10);
				var nCount = parseInt(items[i].getAttribute('count'), 10);
				data[pc] = [pc, nCount];
			}
			plotdata.push({data: data});
			plotopt.xaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.xaxes = [{axisLabel: 'Per cent GC'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
	    } else if(type == 'readlen') {
			var items = root.getElementsByTagName('bin');
			var data = [];
			var iMin = undefined;
			var iMax = undefined;
			for(var i=0;i<items.length;i++) {
				var nLength = parseInt(items[i].getAttribute('value'), 10);
				var nCount = parseInt(items[i].getAttribute('count'), 10);
				if(!iMin)
				iMin = nLength;
				iMax = nLength;
				data.push([nLength, nCount]);
			}
			plotdata.push({data: data, bars: {show: true}});
			plotopt.xaxes = [{axisLabel: 'Length'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
			plotopt.xaxis = {min: iMin-50,
					 max: iMax+50};
	    }
	    $.plot($('#viewer-placeholder-'+strName+'-'+type), plotdata, plotopt);
	    // Info message.
	    var nRunning = msg.getAttribute('active');
	    nRunning--;
	    msg.setAttribute('active', nRunning);
	    if(nRunning==0) {GUI.toggleInfoMsg(msg);}
	}
		
	this.displayGenomicNeighborhood = function(readID) {
	    var msg = document.getElementById('view-infomsg');
	    msg.setAttribute('active', '0');
	    var nRunning = 0;
	    GUI.toggleInfoMsg(msg);
	    var ddlist = document.getElementById('viewer-stats-gn');
	    var checkboxes = ddlist.getElementsByTagName('input');
	    for(var i=0;i<checkboxes.length;i++) {
			var bOldState = checkboxes[i].getAttribute('state')==1;
			if(checkboxes[i].checked != bOldState) {
				checkboxes[i].setAttribute('state', (checkboxes[i].checked) ? '1' : '');
				nRunning++;
				msg.setAttribute('active', nRunning);
				this.toggleGenomicNeighborhood(readID, checkboxes[i], msg);
			}
	    }
	    ddlist.className = 'dropdown-list collapsed';
	    if(msg.getAttribute('active')==0) {GUI.toggleInfoMsg(msg);}
	}
	
	this.displayLibraryPlot = function(xmldata, msg) {
	    var xml = xmldata.responseXML;
	    var root = xml.documentElement;
	    var stat = root.getElementsByTagName('statistic')[0];
	    var strName = stat.getAttribute('library');
	    var type = stat.getAttribute('type');
	    var plotdata = [];
	    var plotopt = {};
	    if(type == 'gc') {
			var items = root.getElementsByTagName('content');
			var data = Core.fillArray(items.length, undefined);
			for(var i=0;i<items.length;i++) {
				var pc = parseInt(items[i].getAttribute('percent'), 10);
				var nCount = parseInt(items[i].getAttribute('count'), 10);
				data[pc] = [pc, nCount];
			}
			plotdata.push({data: data});
			plotopt.xaxis = {tickFormatter: function(value, axis){return (value<=100) ? value+'%' : ''}};
			plotopt.xaxes = [{axisLabel: 'Per cent GC'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
	    } else if(type == 'seqlen') {
			var items = root.getElementsByTagName('bin');
			var data = [];
			var iMin = undefined;
			var iMax = undefined;
			for(var i=0;i<items.length;i++) {
				var nLength = parseInt(items[i].getAttribute('value'), 10);
				var nCount = parseInt(items[i].getAttribute('count'), 10);
				if(!iMin)
				iMin = nLength;
				iMax = nLength;
				data.push([nLength, nCount]);
			}
			plotdata.push({data: data, bars: {show: true}});
			plotopt.xaxes = [{axisLabel: 'Length'}];
			plotopt.yaxes = [{position: 'left', axisLabel: 'Count'}];
			plotopt.xaxis = {min: iMin-50,
					 max: iMax+50};
	    }
	    $.plot($('#viewer-placeholder-'+strName+'-'+type), plotdata, plotopt);
	    // Info message.
	    var nRunning = msg.getAttribute('active');
	    nRunning--;
	    msg.setAttribute('active', nRunning);
	    if(nRunning==0) {GUI.toggleInfoMsg(msg);}
	}
		
	this.displayGenomicNeighborhood = function(readID) {
	    var msg = document.getElementById('view-infomsg');
	    msg.setAttribute('active', '0');
	    var nRunning = 0;
	    GUI.toggleInfoMsg(msg);
	    var ddlist = document.getElementById('viewer-stats-gn');
	    var checkboxes = ddlist.getElementsByTagName('input');
	    for(var i=0;i<checkboxes.length;i++) {
			var bOldState = checkboxes[i].getAttribute('state')==1;
			if(checkboxes[i].checked != bOldState) {
				checkboxes[i].setAttribute('state', (checkboxes[i].checked) ? '1' : '');
				nRunning++;
				msg.setAttribute('active', nRunning);
				this.toggleGenomicNeighborhood(readID, checkboxes[i], msg);
			}
	    }
	    ddlist.className = 'dropdown-list collapsed';
	    if(msg.getAttribute('active')==0) {GUI.toggleInfoMsg(msg);}
	}
		
	this.toggleGenomicNeighborhood = function(readID, checkbox, msg) {
	    var iAssembly = checkbox.getAttribute('assembly');
	    var plotblock = document.getElementById('viewer-map-'+iAssembly);
	    plotblock.className = (checkbox.checked) ? 'viewer-plotblock' : 'viewer-plotblock viewer-invisible';
	    if(checkbox.getAttribute('hasData')==0) {
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'ReadsCollection.getReadMapping',
										  params: {evalue: 1e-25,
								                   reads: readID,
												   assemblies: iAssembly}},
								 callback: {scope: this,
								            fn: this.displayMap,
									        args: [iAssembly, '1e-25', msg]}});
			checkbox.setAttribute('hasData', '1');
	    } else {
			var nRunning = msg.getAttribute('active');
			nRunning--;
			msg.setAttribute('active', nRunning);
	    }
	}
		
	this.displayMap = function(xmldata, iAssembly, evalue, msg) {
	    var xml = xmldata.responseXML;
	    var root = xml.documentElement;
	    var read = root.getElementsByTagName('read')[0];
	    var assembly = root.getElementsByTagName('assembly')[0];
	    var ph = document.getElementById('viewer-placeholder-'+iAssembly);
	    var php = ph.parentNode;
	    php.innerHTML = '';
	    php.className = 'viewer-placeholder-wrapper noplot';
	    if(!assembly) {
		var err = document.createElement('div');
		err.className = 'viewer-badid';
		err.style.marginTop = '0';
		err.innerHTML = '<i>No mapping information could be retrieved for this assembly. This could indicate that there are no '+
				'contigs that map to this read or that the mapping for this assembly has not been performed, yet.</i>';
		php.appendChild(err);
	    } else {
		var hint = document.createElement('div');
		hint.className = 'viewer-map-hint';
		hint.innerHTML = 'Note that only hits with the e-value less than or equal to '+evalue+' are displayed. '+
				 'Click on the contig outline to toggle the alignment.';
		php.appendChild(hint);
		var mapdata = {length: parseInt(read.getAttribute('length'), 10),
			       nTicks: 10,
			       lines: [],
			       sort: Controls.GB_SMSORT_BYNAME};
		var children = assembly.childNodes;
		for(var i=0;i<children.length;i++) {
		    if(children[i].tagName == 'contig'){
			var cname = children[i].getAttribute('name');
			var link = '<a target="_blank" class="viewer-map-link" href="/transcripts/'+cname+'">'+cname+'</a>';
			if(!this.mapdata)
				this.mapdata = {};
			this.mapdata[cname] = [];
			var cd = {title: link,
					  fragments: []};
			var hsps = children[i].getElementsByTagName('hsp');
			for(var j=0;j<hsps.length;j++) {
			    var hsp_contig = hsps[j].getElementsByTagName('contig')[0];
			    var cs = parseInt(hsp_contig.getAttribute('from'), 10);
			    var ce = parseInt(hsp_contig.getAttribute('to'), 10);
			    var hsp_read = hsps[j].getElementsByTagName('read')[0];
			    var rs = parseInt(hsp_read.getAttribute('from'), 10);
			    var re = parseInt(hsp_read.getAttribute('to'), 10);
			    var index = parseInt(hsps[j].getAttribute('index'),10)-1;
			    var frpos = {start: rs, end: re};
			    if(re>rs)
				frpos = {start: re, end: rs};
			    var fragment = {position: frpos,
					    type: (rs<=re) ? Controls.GB_SMFRAGMENT_FORWARD : Controls.GB_SMFRAGMENT_REVERSE,
					    tooltip: 'Bitscore: '+hsps[j].getAttribute('bitscore')+
						     ' E-value: '+hsps[j].getAttribute('evalue'),
					    callback: {scope: this,
						       cbClicked: this.displayReadAlignment,
						       cbParams: [cname, index, php]}};
			    cd.fragments.push(fragment);
			    var hsp = {contig: {seq: Core.extractLongText(hsp_contig),
						start: cs,
						end: ce},
				       read: {seq: Core.extractLongText(hsp_read),
					      start: rs,
					      end: re},
				       midline: Core.extractLongText(hsps[j].getElementsByTagName('midline')[0]),
				       score: parseFloat(hsps[j].getAttribute('bitscore')),
				       evalue: parseFloat(hsps[j].getAttribute('evalue'))};
			    this.mapdata[cname].push(hsp);
			}
		    }
		    mapdata.lines.push(cd);
		}
		var map = Controls.createMap(mapdata);
		php.appendChild(map);
	    }
	    // Info message.
	    var nRunning = msg.getAttribute('active');
	    nRunning--;
	    msg.setAttribute('active', nRunning);
	    if(nRunning==0) {GUI.toggleInfoMsg(msg);}
	}

	this.displayReadAlignment = function(cname, hsp, php) {
	    var alnwrapper = document.getElementById('viewer-aln');
	    if(!alnwrapper) {
		alnwrapper = document.createElement('div');
		alnwrapper.id = 'viewer-aln';
		php.appendChild(alnwrapper);
		this.lastShown = {cname: undefined, hsp: undefined};
	    } else if(this.lastShown.cname == cname && this.lastShown.hsp == hsp) {
		alnwrapper.className = 'viewer-map-aln hidden';
		this.lastShown.cname = this.lastShown.hsp = undefined;
		return;
	    }
	    var hspdata = (this.mapdata[cname])[hsp];
	    alnwrapper.innerHTML = '';
	    var header = document.createElement('h3');
	    header.innerHTML = cname + ', region '+(hsp+1);
	    alnwrapper.appendChild(header);
	    var alndata = {score: hspdata.score,
			   evalue: hspdata.evalue,
			   algorithm: 'blastn',
			   type: Controls.GB_AT_DNA,
			   first: {name: 'Read',
				   frame: 1,
				   start: hspdata.read.start,
				   end: hspdata.read.end,
				   sequence: hspdata.read.seq},
			   second: {name: 'Contig',
				    frame: 0,
				    start: hspdata.contig.start,
				    end: hspdata.contig.end,
				    sequence: hspdata.contig.seq},
			   midline: hspdata.midline,
			   style: Controls.GB_AS_HEADER};
	    if(hspdata.read.start>hspdata.read.end) {
		alndata.first.frame = -1;
		alndata.first.start = hspdata.read.end;
		alndata.first.end = hspdata.read.start;
	    }
	    var aln = Controls.createAlignment(alndata);
	    alnwrapper.appendChild(aln);
	    alnwrapper.className = 'viewer-map-aln';
	    this.lastShown.cname = cname;
	    this.lastShown.hsp = hsp;
	}
		
	this.showFullImage = function(strLine) {
	    var frame = document.createElement('div');
	    frame.className = 'viewer-popup';
	    var img = document.createElement('img');
	    img.setAttribute('src', Core.getBaseAddress()+'api?method=Transgenics.getTransgenicLineImage&line='+strLine);
	    frame.appendChild(img);
	    Core.showPopup(frame);
	}
    }
	
    window.Viewer = new Viewer();
})();
