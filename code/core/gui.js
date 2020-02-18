/*
    File:
		controls.js
	    
    Description:
	    Contains general functions of the controls.
	    
    Date:
		15.05.2014
*/

(function() {
    function Controls() {
			
		this.GB_VIEWHEADER_SIMPLE = 0;
		this.GB_VIEWHEADER_EXPANDABLE = 1;
		this.GB_VIEWSTYLE_COLLAPSED = 0;
		this.GB_VIEWSTYLE_EXPANDED = 1;
		this.GB_WAITMSGSTYLE_HIDDEN = 0;
		this.GB_WAITMSGSTYLE_VISIBLE = 1;
		
		this.GB_DDLISTSTATE_COLLAPSED = 0;
		this.GB_DDLISTSTATE_EXPANDED = 1;
		
		this.GB_LISTSTYLE_CHECKBOX = 0;
		this.GB_LISTSTYLE_RADIO = 1;
		this.GB_LISTSTYLE_NONE = 2;
		
		this.GB_BTNSTYLE_NORMAL = 0;
		this.GB_BTNSTYLE_SUBMIT = 1;
		this.GB_BTNSTYLE_CANCEL = 2;
	
		this.GB_TBSTYLE_BUTTON = 0;
		this.GB_TBSTYLE_FLAT = 1;
		
		this.GB_SMFRAGMENT_NONE = 0;
		this.GB_SMFRAGMENT_FORWARD = 1;
		this.GB_SMFRAGMENT_REVERSE = 2;
		this.GB_SMFRAGMENT_BOTH = 3;
		
		this.GB_SMSORT_NONE = 0;
		this.GB_SMSORT_BYNAME = 1;
		this.GB_SMSORT_BYLEFTMOST = 2;
		this.GB_SMSORT_BYLONGEST = 3;
		
		this.GB_AS_NOHEADER = 0;
		this.GB_AS_HEADER = 1;
		
		this.GB_AT_DNA = 0;
		this.GB_AT_PROTEIN = 1;
		
		this.GB_MAP_FRAGMENT_HEIGHT = 5;
		this.GB_MAP_FRAGMENT_MARGIN = 2;
		this.GB_MAP_MARGIN = 3;
			
			
		this.toggleView = function(view) {
			var parent = view.parentNode;
			var content = parent.getElementsByClassName('view-collapsed')[0];
			if(content) {
			content.className = 'view-expanded';
			return 'expanded';
			} else {
			content = parent.getElementsByClassName('view-expanded')[0];
			if(content) {
				content.className = 'view-collapsed';
				return 'collapsed';
				} else {
					return undefined;
				}
			}
		}
			
		/*
			Creates a views container with views.
			Parameters:
				- arrViews     array containing the views.
					   Each array element must be an object with the following keys:
						- title                 view title
						- description           view description
						- id                    view ID. Can be undefined if type is GB_VIEWHEADER_SIMPLE
						- type                  either GB_VIEWHEADER_SIMPLE or GB_VIEWHEADER_EXPANDABLE. Default is GB_VIEWHEADER_SIMPLE
						- cbExpand              object containing the details about the callback function. Ignored if type is GB_VIEWHEADER_SIMPLE. Must have the following keys:
							- scope				scope the callback function is called in
							- fnCallback        function to be called. The first argument will be the reference to the header object
							- params            array containing any additional parameters to be passed to the callback function. Can be undefined
						- style                 either GB_VIEWSTYLE_COLLAPSED (default) or GB_VIEWSTYLE_EXPANDED
						- anchor                anchor name. Can be undefined
						- color                 color of the label displayed at the left hand border. Can be undefined
						- infomsgID             ID of the infomsg element. Can be undefined
						- content               object representing the content of the viewarea. Can be undefined
						- toolbar               object that specifies, which toolbar buttons should be displayed. Currently only can have following keys:
						- waitmsg           	object. If specified a wait icon is added. Can have following keys:
							- id            		icon ID. Can be undefined
							- state         		the icon state. Can be either GB_WAITMSGSTYLE_HIDDEN (default) or GB_WAITMSGSTYLE_VISIBLE.
							- text          		waitmsg text. Default is 'Loading...'
		*/
		this.createViewsContainer = function(arrViews) {
			var control = {container: undefined,
				           views: {}};
			if(!arrViews) {
				return control;
			}
			var viewsContainer = document.createElement('div');
			viewsContainer.className = 'views-container';
			control.container = viewsContainer;
			var views = document.createElement('ul');
			for(var i=0;i<arrViews.length;i++) {
				var view = arrViews[i];
				var item = document.createElement('li');
				if(view.anchor) {
					var anchor = document.createElement('a');
					anchor.id = view.anchor;
					item.appendChild(anchor);
				}
				var datablock = document.createElement('div');
				datablock.className = 'data-block';
				if(!view.color)
					view.color = 'transparent';
				datablock.style.borderLeft = '5px solid '+view.color;
				var viewheader = document.createElement('div');
				if(view.id)
					viewheader.id = view.id;
				viewheader.className = 'view-header';
				var eventArea = document.createElement('div');
				if((view.type == this.GB_VIEWHEADER_EXPANDABLE) && (view.cbExpand)) {
					eventArea.className = 'view-eventarea';
					var arrParams = [viewheader];
					if(view.cbExpand.params)
						arrParams.push(view.cbExpand.params);
					(function(scope, fnCallback, arrParams) {
						eventArea.addEventListener('click', function(){fnCallback.apply(scope, arrParams);});
					})(view.cbExpand.scope, view.cbExpand.fnCallback, arrParams);
				} else {
					eventArea.className = 'view-eventarea simple';
				}
				var viewtitle = document.createElement('div');
				viewtitle.className = 'view-title';
				var title = document.createElement('span');
				title.innerHTML = view.title;
				viewtitle.appendChild(title);
				eventArea.appendChild(viewtitle);
				var viewdescr = document.createElement('div');
				viewdescr.className = 'view-description';
				var descr = document.createElement('span');
				descr.innerHTML = view.description;
				viewdescr.appendChild(descr);
				eventArea.appendChild(viewdescr);
				viewheader.appendChild(eventArea);
				if(view.toolbar) {
					var toolbar = document.createElement('ul');
					toolbar.className = 'view-toolbar';
					// Waitbar.
					var waitmsg = view.toolbar.waitmsg;
					if(waitmsg) {
						var infomsg = document.createElement('li');
						infomsg.className = (waitmsg.state == this.GB_WAITMSGSTYLE_VISIBLE) ? 'view-infomsg'
															: 'view-infomsg hidden';
						if(waitmsg.id)																
							infomsg.id = waitmsg.id;
						infomsg.innerHTML = (waitmsg.text) ? '<span>' + waitmsg.text + '</span>'
										   : '<span>Loading...</span>';
						toolbar.appendChild(infomsg);
					}
					viewheader.appendChild(toolbar);
				}
				datablock.appendChild(viewheader);
				var viewarea = document.createElement('div');
				viewarea.className = (view.style == this.GB_VIEWSTYLE_EXPANDED) ? 'view-expanded' : 'view-collapsed';
				if(view.content)
					viewarea.appendChild(view.content);
				datablock.appendChild(viewarea);
				item.appendChild(datablock);
				views.appendChild(item);
				control.views[view.title] = {item: item, viewarea: viewarea};
			}
			viewsContainer.appendChild(views);
			return control;
		}
	
		/*
			Creates a toolbar.
			Parameters:
				- data  object containing the toolbar data with the following keys:
					- title                 toolbar title
					- selected              name of the selected item
					- style                 either GB_TBSTYLE_BUTTON (default) or GB_TBSTYLE_FLAT
					- items     			array holding the toolbar items. Each array element must be an object with the following keys:
						- title             item title
						- id                item ID. Can be undefined
						- tooltip           tooltip. Can be undefined
						- callback			object containing the callback details:
							- cbClicked     callback function, which is called when the item is clicked
							- cbScope		scope the callback function is called in
							- cbParams		array of parameters to pass to the callback function
		*/
		this.createToolbar = function(data) {
			if(!data){
				return undefined;
			}
			var tb = document.createElement('ul');
			tb.className = (data.style == this.GB_TBSTYLE_FLAT) ? 'flattoolbar' : 'toolbar';
			var item = document.createElement('li');
			item.innerHTML = data.title;
			tb.appendChild(item);
			var selectedItem = undefined;
			for(var i=0;i<data.items.length;i++){
				var di = data.items[i];
				item = document.createElement('li');
				var ctrl = undefined;
				if(di.id)
					item.id = di.id;
				if(di.tooltip)
					item.tooltip = di.tooltip;
				if(data.style == this.GB_TBSTYLE_FLAT) {
					var span = document.createElement('span');
					span.className = 'push-button';
					item.appendChild(span);
					ctrl = span;
				} else {
					ctrl = item;
				}
				ctrl.innerHTML = di.title;
				if(!selectedItem || (di.title == data.selected))
					selectedItem = ctrl;
				if(di.callback) {
					(function(scope, fnCallback, arrParams) {
						ctrl.addEventListener('click', function(){fnCallback.apply(scope, arrParams);});
					})(di.callback.cbScope, di.callback.cbClicked, di.callback.cbParams);
				}
				tb.appendChild(item);
			}
			selectedItem.className = (data.style == this.GB_TBSTYLE_FLAT) ? 'push-button pushed' : 'selected';
			return tb;
		}
			
		/*
			Creates a map, which can be used to represent sequence mapping.
			Parameters:
				- data              			object containing the map data with the following keys:
					- length            		length of the region to represent
					- nTicks            		number of ticks in the grid
					- lines						array of line details objects. The objects must have the following keys:
						- title					line title
						- fragments				array containing the fragments. Each element must be an object with the following keys:
							- position			object with following keys:
								- start			start of the fragment with respect to the region
								- end			end of the fragment
							- type				fragment representation type. Can be one of the following:
													- GB_SMFRAGMENT_NONE	default		the fragment representation does not have orientation
													- GB_SMFRAGMENT_FORWARD				the fragment points to the right
													- GB_SMFRAGMENT_REVERSE				the fragment points to the left
													- GB_SMFRAGMENT_BOTH				the fragment points to both sides
							- className     	user-defined class (CSS) name
							- background		user-defined background
							- text				fragment text (optional)
							- tooltip			tooltip (optional)
							- callback			object containing the callback details:
								- cbClicked     name of the callback function, which is called when the item is clicked
								- cbScope		scope the callback function is called in
								- cbParams		array of parameters to pass to the callback function
					- sort						specifies the sorting of the lines. Can be one of the following values:
													- GB_SMSORT_NONE (default)		the lines are not sorted
													- GB_SMSORT_BYNAME				the lines are sorted by name
													- GB_SMSORT_BYLEFTMOST			the lines are sorted by the left-most fragment start
													- GB_SMSORT_BYLONGEST			the lines are sorted by the length of the longest fragment
					- topLine					index of the line, which should be displayed at the top, independent of sorting. Can be undefined
		*/
		this.createMap = function(data) {
			if(!data){
				return undefined;
			}
			var map = document.createElement('div');
			map.className = 'sequencemap';
			// Positions.
			var line = document.createElement('div');
			line.className = 'line';
			title = document.createElement('div');
			title.className = 'title';
			title.innerHTML = '&nbsp;';
			line.appendChild(title);
			var grid = document.createElement('div');
			grid.className = 'grid';
			for(var j=0;j<=data.nTicks;j++) {
				var tick = document.createElement('span');
				tick.className = 'tick';
				tick.style.left = (data.nTicks*j)+'%';
				var iVal = Math.round((j*(data.length/data.nTicks)+1));
				if(iVal>data.length)
					iVal = data.length;
				tick.innerHTML = iVal;
				grid.appendChild(tick);
			}
			line.appendChild(grid);
			map.appendChild(line);
			var topLine = undefined;
			if(data.topLine!='undefined' && data.topLine>=0 && data.topLine<data.lines.length) {
				topLine = data.lines.splice(data.topLine,1)[0];
			}
			if(data.sort == this.GB_SMSORT_BYNAME) {
				data.lines.sort(function(a,b){return a.title.toLowerCase().localeCompare(b.title.toLowerCase())});
			} else if(data.sort == this.GB_SMSORT_BYLEFTMOST) {
				data.lines.sort(function(a,b){
									var left = [data.length,data.length];
									var lines = [a,b];
									for(var i=0;i<2;i++) {
										var frags = lines[i].fragments;
										for(var j=0;j<frags.length;j++){
											var tmp = Math.min(frags[j].position.start, frags[j].position.end);
											if(tmp<left[i])
												left[i] = tmp;
										}
									}
									return left[0]-left[1];
								});
			} else if(data.sort == this.GB_SMSORT_BYLONGEST) {
				data.lines.sort(function(a,b){
									var lengths = [0, 0];
									var lines = [a,b];
									for(var i=0;i<2;i++) {
										var frags = lines[i].fragments;
										for(var j=0;j<frags.length;j++){
											var tmp = Math.abs(frags[j].position.start-frags[j].position.end);
											if(tmp>lengths[i])
												lengths[i] = tmp;
										}
									}
									return lengths[1]-lengths[0];
								});
			}
			if(topLine)
				data.lines.unshift(topLine);
			for(var i=0;i<data.lines.length;i++){
				var ld = data.lines[i];
				line = document.createElement('div');
				if(ld.className)
					line.className = 'line '+ld.className;
				else
					line.className = 'line';
				// Name
				title = document.createElement('div');
				title.className = 'title';
				if(ld.title)
					title.innerHTML = ld.title;
				line.appendChild(title);
				// Outline.
				var iOutlineHeight = 2*this.GB_MAP_MARGIN + ld.fragments.length*(this.GB_MAP_FRAGMENT_HEIGHT+2*this.GB_MAP_FRAGMENT_MARGIN);
				var outline = document.createElement('div');
				outline.className = 'outline';
				outline.style.height = iOutlineHeight + 'px';
				for(var j=0;j<=data.nTicks;j++) {
					var tick = document.createElement('span');
					tick.className = 'tick';
					tick.style.left = (data.nTicks*j)+'%';
					tick.style.height = iOutlineHeight + 'px';
					outline.appendChild(tick);
				}
				// Fragments.
				for(var j=0;j<ld.fragments.length;j++) {
					var fd = ld.fragments[j];
					var fragment = document.createElement('span');
					fragment.className = 'fragment';
					if(fd.type == this.GB_SMFRAGMENT_FORWARD) {
						fragment.className = 'fragment forward';
					} else if(fd.type == this.GB_SMFRAGMENT_REVERSE) {
						fragment.className = 'fragment reverse';
					} else if(fd.type == this.GB_SMFRAGMENT_BOTH) {
						fragment.className = 'fragment both';
					}
					var left = 0;
					var width = 0;
					if(fd.position.start<=fd.position.end) {
						left = fd.position.start/data.length*100;
						width = (fd.position.end-fd.position.start)/data.length*100;
					} else {
						left = fd.position.end/data.length*100;
						width = (fd.position.start-fd.position.end)/data.length*100;
					}
					fragment.style.left = left + '%';
					fragment.style.width = width + '%';
					fragment.style.marginTop = this.GB_MAP_MARGIN + (j*(this.GB_MAP_FRAGMENT_HEIGHT+2*this.GB_MAP_FRAGMENT_MARGIN)+this.GB_MAP_FRAGMENT_MARGIN) + 'px';
					if(fd.text)
						fragment.innerHTML = fd.text;
					if(fd.tooltip)
						fragment.title = fd.tooltip;
					if(fd.callback) {
						(function(scope, fnCallback, arrParams) {
							fragment.addEventListener('click', function(){fnCallback.apply(scope, arrParams);});
						})(fd.callback.scope, fd.callback.cbClicked, fd.callback.cbParams);
						fragment.className += ' active';
					}
					if(fd.className)
						fragment.className += ' ' + fd.className;
					if(fd.background)
						fragment.style.background = fd.background;
					outline.appendChild(fragment);
				}
				line.appendChild(outline);
				map.appendChild(line);
			}
			return map;
		}
		
		/*
			Create the fragment representing the open reading frame (ORF).
			Parameters:
				- strORFClass			name of the ORF class
				- strORFDescription		description of the ORF class
				- iORFStart				1-based position the ORF starts at within the sequence
				- iORFLength			ORF length in nucleotides
				- iSeqLength			the length of the entire sequence
		*/
		this.createORFFragment = function(strORFClass, strORFDescription, iORFStart, iORFLength, iSeqLength) {
			var strClass = 'orf-predicted';
			switch(strORFClass.toLowerCase()) {
				case 'putative': strClass = 'orf-putative'; break;
				case 'n-terminal': strClass = 'orf-nterminal'; break;
				case 'c-terminal': strClass = 'orf-cterminal'; break;
				case 'partial': strClass = 'orf-partial'; break;
				case 'ptc': strClass = 'orf-ptc'; break;
			}
			var fragment = {text: strORFClass,
							tooltip: strORFDescription,
							position: {start: iORFStart, end: 0},
							type: Controls.GB_SMFRAGMENT_FORWARD,
							className: 'orf-outline plus'};
			if(iORFStart<0) {
				iORFStart = iSeqLength-Math.abs(iORFStart+1)-iORFLength+1;
				fragment.position.start = iORFStart;
				fragment.type = Controls.GB_SMFRAGMENT_REVERSE;
				fragment.className = 'orf-outline minus';
			}
			fragment.className += ' '+ strClass;
			fragment.position.end = iORFStart+iORFLength-1;
			return fragment;
		}
			
		/*
			Creates the control displaying an alignment.
			Parameters:
				- data              	object containing the alignment data. Must have the following keys:
					- score            	(optional) alignment score
					- evalue			(optional) e-value
					- algorithm			(optional) algorithm name. Default 'blastn'
					- linelength		(optional) number of residues per line. Default 60
					- first				object containing the data of the first sequence. Must have the following keys:
						- name			sequence name
						- frame			frame or strand
						- start			start of the aligned portion of the sequence
						- end			end of the aligned portion of the sequence
						- sequence		aligned sequence
					- second			object containing the data of the second sequence. Must have the following keys:
						- name			sequence name
						- frame			frame or strand
						- start			start of the aligned portion of the sequence
						- end			end of the aligned portion of the sequence
						- sequence		aligned sequence
					- midline			alignment midline
					- style				either BG_AS_NOHEADER (default) or BG_AS_HEADER
		*/
		this.createAlignment = function(data) {
			if(!data){
				return undefined;
			}
			if(!data.algorithm)
				data.algorithm = 'blastn';
			var strAlgorithm = data.algorithm.toLowerCase();
			var nRpL = (data.linelength) ? parseInt(data.linelength, 10) : 60;
			if(!nRpL>0)
				nRpL = 60;
			var values = [['Score', 'Expect', 'Identities', 'Gaps', data.first.name, data.second.name, 'Algorithm'],
						  [new Number(data.score).toFixed(2), new Number(data.evalue).toExponential(2), 0, 0, 'Strand: ', 'Strand: ', data.algorithm]];
			var aln = document.createElement('div');
			aln.className = 'alignment';
			var table = document.createElement('table');
			var pos = 0;
			var iFPos = (data.first.frame>=0) ? data.first.start : data.first.end;
			var iSPos = (data.second.frame>=0) ? data.second.start : data.second.end;
			var iFInc = 1;
			var iSInc = 1;
			if(strAlgorithm=='blastp' || strAlgorithm=='blastx' || strAlgorithm=='tblastn' || strAlgorithm=='tblastx') {
				iFInc = (data.first.frame==0) ? 1 : 3;
				iSInc = (data.second.frame==0) ? 1 : 3;
				values[1][4] = values[1][5] = 'Frame: ';
				values[1][4] += data.first.frame;
				values[1][5] += data.second.frame;
			} else {
				values[1][4] += (data.first.frame>=0) ? 'plus' : 'minus';
				values[1][5] += (data.second.frame>=0) ? 'plus' : 'minus';
			}
			if(data.first.frame<0) {
				iFPos += data.first.sequence.replace(/-/g, '').length*iFInc-1;
				iFInc *= -1;
			}
			if(data.second.frame<0) {
				iSInc *= -1;
			}
			while(pos<data.midline.length) {
				var line = document.createElement('tr');
				// Sequence IDs.
				var cell = document.createElement('td');
				cell.innerHTML = '<pre>'+data.first.name+'\n\n'+data.second.name+'</pre>';
				line.appendChild(cell);
				// Positions.
				cell = document.createElement('td');
				cell.innerHTML = '<pre>'+(iFPos)+'\n\n'+(iSPos)+'</pre>';
				line.appendChild(cell);
				// Sequence.
				cell = document.createElement('td');
				var strFirst = data.first.sequence.substr(pos, nRpL);
				var strMidline = data.midline.substr(pos, nRpL);
				var strSecond = data.second.sequence.substr(pos, nRpL);
				cell.innerHTML = '<pre>'+strFirst+'</pre><pre class="midline">'+strMidline+'</pre><pre>'+strSecond+'</pre>';
				line.appendChild(cell);
				// End positions. 
				iFPos += iFInc*(strFirst.replace(/-/g, '').length);
				iSPos += iSInc*(strSecond.replace(/-/g, '').length);
				cell = document.createElement('td');
				cell.innerHTML = '<pre>'+(iFPos-iFInc)+'\n\n'+(iSPos-iSInc)+'</pre>';
				line.appendChild(cell);
				table.appendChild(line);
				pos+=nRpL;
			}
			// Add the header if necessary.
			if(data.style == this.GB_AS_HEADER) {
				var nIdentities = 0;
				var nGaps = 0;
				for(var i=0;i<data.midline.length;i++) {
					var c1 = data.first.sequence.charAt(i);
					var c2 = data.second.sequence.charAt(i);
					if(c1 == c2)
						nIdentities++;
					if((c1 == '-') || (c2 == '-'))
						nGaps++;
				}
				var fGaps = new Number(nGaps/data.first.sequence.length*100).toFixed(2);
				values[1][3] = nGaps + '/' + data.first.sequence.length + ' (' + fGaps + '%)';
				var fIdentities = new Number(nIdentities/data.first.sequence.length*100).toFixed(2);
				values[1][2] = nIdentities + '/' + data.first.sequence.length + ' (' + fIdentities + '%)';
				var stats = document.createElement('div');
				stats.className = 'statistics';
				for(var i=0;i<values.length;i++) {
					var line = document.createElement('div');
					line.className = 'line';
					for(var j=0;j<values[i].length;j++) {
						var item = document.createElement('div');
						item.className = 'item';
						item.innerHTML = values[i][j];
						line.appendChild(item);
					}
					stats.appendChild(line);
				}
				aln.appendChild(stats);
			}
			aln.appendChild(table);
			return aln;
		}
		
		/*
			Creates the control displaying a multiple sequence alignment.
			Parameters:
				- data              	object containing the alignment data. Must have the following keys:
					- type				(optional) sequence type. Must be either GB_AT_DNA (default) or GB_AT_PROTEIN
					- linelength		(optional) number of residues per line. Default 60
					- sequences			array containing the sequences. Each element is an object with the following keys:
						- name			sequence name
						- start			start of the aligned portion of the sequence
						- end			end of the aligned portion of the sequence
						- sequence		aligned sequence
					- consensus			(optional) alignment consensus sequence
		*/
		this.createMultipleAlignment = function(data) {
			if(!data){
				return undefined;
			}
			var nRpL = (data.linelength) ? parseInt(data.linelength, 10) : 60;
			if(!nRpL>0)
				nRpL = 60;
			var nAlnLen = undefined;
			var arrNames = [];
			var arrPositions = [];
			var nSeqs = data.sequences.length;
			for(var i=0;i<nSeqs;i++) {
				if(!nAlnLen || data.sequences[i].sequence.length<nAlnLen)
					nAlnLen = data.sequences[i].sequence.length;
				arrNames.push(data.sequences[i].name);
				arrPositions.push(data.sequences[i].start);
			}
			if(data.consensus) {
				arrNames.push('<span class="consensus">consensus</span>');
				arrPositions.push(1);
			}
			var aln = document.createElement('div');
			aln.className = 'alignment';
			var table = document.createElement('table');
			var pos = 0;
			var iInc = (data.type==this.GB_AT_PROTEIN) ? 3 : 1;
			var strSeqNames = arrNames.join('\n');
			while(pos<nAlnLen) {
				var line = document.createElement('tr');
				// Sequence IDs.
				var cell = document.createElement('td');
				cell.innerHTML = '<pre>'+strSeqNames+'</pre>';
				line.appendChild(cell);
				// Positions.
				cell = document.createElement('td');
				cell.innerHTML = '<pre>'+arrPositions.join('\n')+'</pre>';
				line.appendChild(cell);
				// Sequence.
				cell = document.createElement('td');
				cell.className = 'homology-aln';
				var tmp = [];
				var ends = [];
				for(var i=0;i<nSeqs;i++) {
					var strSeq = data.sequences[i].sequence.substr(pos, nRpL);
					tmp.push(strSeq);
					arrPositions[i] += iInc*(strSeq.replace(/-/g, '').length);
					ends.push(arrPositions[i]-iInc);
				}
				if(data.consensus) {
					var strSeq = data.consensus.substr(pos, nRpL);
					tmp.push('<span class="consensus">'+strSeq+'</span>');
					arrPositions[nSeqs] += iInc*strSeq.length;
					ends.push(arrPositions[nSeqs]-iInc);
				}
				cell.innerHTML = '<pre>'+tmp.join('\n')+'</pre>';
				line.appendChild(cell);
				// End positions. 
				cell = document.createElement('td');
				cell.innerHTML = '<pre>'+ends.join('\n')+'</pre>';
				line.appendChild(cell);
				table.appendChild(line);
				pos+=nRpL;
			}
			aln.appendChild(table);
			return aln;
		}
		
		/*
			Creates the list control.
			Parameters:
				- data              		object containing the list data. Must have the following keys:
					- style         		list items style. Must be one of the following values:
												GB_LISTSTYLE_CHECKBOX (default)     list items are checkboxes
												GB_LISTSTYLE_RADIO                  list items are radio buttons
												GB_LISTSTYLE_NONE                   list items are text
					- groups				array of groups. Each element must have the following keys:
						- name				group name
						- toggle			(optional) object with the following keys:
							- title			title of 'Toggle all' element
							- cbClicked		callback function called upon click on the element
							- scope			scope
						- items				array of list group elements. Each element must have the following keys:
							- title			item title
							- description	(optional) item description
							- attributes	(optional) array of objects specifying additional attributes: {name: <ATTRIBUTE>, value: <VALUE>.
											Ignored if the style is GB_LISTSTYLE_NONE.
							- tooltip		(optional) item tooltip
							- id            item ID. Reguired if style is either GB_LISTSTYLE_CHECKBOX or GB_LISTSTYLE_RADIOBTN
							- name          item name. Required if style is either GB_LISTSTYLE_CHECKBOX or GB_LISTSTYLE_RADIOBTN
							- cbChange      callback function, which is called when the item state is changed
							- scope			callback function scope
					
		*/
		this.createList = function(data) {
			if(!data){
				return undefined;
			}
			var list = document.createElement('div');
			list.className = 'list';
			var groups = document.createElement('ul');
			for(var i=0;i<data.groups.length;i++) {
				var item = document.createElement('li');
				var block = document.createElement('div');
				var header = document.createElement('h2');
				header.innerHTML = data.groups[i].name;
				block.appendChild(header);
				var elements = document.createElement('ul');
				for(var j=0;j<data.groups[i].items.length;j++) {
					var el = data.groups[i].items[j];
					if(el.title && el.title.length) {
						var li = document.createElement('li');
						var input = undefined;
						var label = undefined;
						if(data.style == this.GB_LISTSTYLE_NONE){
							label = document.createElement('span');
							label.className = 'itemlabel';
						} else {
							var strType = (data.style==this.GB_LISTSTYLE_RADIO) ? 'radio' : 'checkbox';
							input = document.createElement('input');
							input.setAttribute('type', strType);
							if(el.name)
								input.setAttribute('name', el.name);
							if(el.cbChange) {
								(function(scope, fnCallback, input) {
									input.addEventListener('click', function(){fnCallback.apply(scope, [input]);});
								})(el.scope, el.cbChange, input);
							}
							if(el.id)
								input.id = el.id;
							label = document.createElement('label');
							label.className = 'itemlabel';
							label.setAttribute('for', el.id);
							for(var n=0;n<el.attributes.length;n++){
								input.setAttribute(el.attributes[n].name, el.attributes[n].value);
							}
						}
						if(input)
							li.appendChild(input);
						var namespan = document.createElement('span');
						namespan.innerHTML = el.title;
						label.appendChild(namespan);
						if(el.description) {
							var descspan = document.createElement('span');
							if(el.tooltip)
								descspan.setAttribute('title', el.tooltip);
							descspan.innerHTML = el.description;
							label.appendChild(descspan);
						}
						li.appendChild(label);
						elements.appendChild(li);
					}
				}
				if(data.groups[i].toggle)
				{
					var li = document.createElement('li');
					li.className = 'toggleall';
					li.innerHTML = data.groups[i].toggle.title;
					(function(scope, fnCallback) {
						li.addEventListener('click', function(){fnCallback.apply(scope);});
					})(data.groups[i].toggle.scope, data.groups[i].toggle.cbClicked);
					elements.appendChild(li);
				}
				block.appendChild(elements);
				item.appendChild(block);
				groups.appendChild(item);
			}
			list.appendChild(groups);
			return list;
		};
		
		/*
			Creates a drop-down list
			Parameters:
				- data                  	object containing the list data with the following keys:
					- content               element representing the list content
					- title                 list title
					- id                    drop-down list ID. Can be undef
					- state                 initial state. Must be either GB_DDLISTSTATE_COLLAPSED (default) or GB_DDLISTSTATE_EXPANDED
					- cbClicked             callback function, which is called when the list title is clicked
					- scope					scope of the callback function
					- buttons               reference to an array containing the buttons on the bottom of the list. Can be undef. Each element must be a reference to a hash with the following keys:
						- text              button text
						- tooltip           tooltip. Can be undef
						- style             button style. Must be one of the GB_BTNSTYLE_* values
						- cbClicked         name of the callback function, which is called upon click
						- scope				scope of the button function
		*/
		this.createDropDownList = function(data) {
			if(!data){
				return undefined;
			}
			var strClass = (data.state == this.GB_DDLISTSTATE_EXPANDED) ? 'dropdown-list' : 'dropdown-list collapsed';
			var ddlist = document.createElement('div');
			ddlist.className = strClass;
			if(data.id)
				ddlist.id = data.id;
			var title = document.createElement('h3');
			title.innerHTML = data.title;
			(function(scope, fnCallback, ddlist) {
				title.addEventListener('click', function(){fnCallback.apply(scope, [ddlist]);});
			})(data.scope, data.cbClicked, ddlist);
			ddlist.appendChild(title);
			ddlist.appendChild(data.content);
			if(data.buttons.length>0) {
				var btnarea = document.createElement('div');
				btnarea.className = 'btnarea';
				for(var i=0;i<data.buttons.length;i++){
					var btn = this.createButton(data.buttons[i]);
					btnarea.appendChild(btn);
				}
				ddlist.appendChild(btnarea);
			}
			return ddlist;
		}
		
		/*
			Creates a button.
			Parameters:
				- data                  object containing the button data with the following keys:
					- text              button text
					- tooltip           tooltip. Can be undef
					- style             button style. Must be either GB_BTNSTYLE_NORMAL (default), GB_BTNSTYLE_SUBMIT or GB_BTNSTYLE_CANCEL
					- cbClicked         name of the callback function, which is called upon click
					- scope				scope of the callback function
		*/
		this.createButton = function(data) {
			if(!data){
				return undefined;
			}
			var btn = document.createElement('span');
			btn.innerHTML = data.text;
			if(data.tooltip)
				btn.addAttribute('title', data.tooltip);
			if(data.style==this.GB_BTNSTYLE_SUBMIT) {
				btn.className = 'button submit';
			} else if(data.style==this.GB_BTNSTYLE_CANCEL) {
				btn.className = 'button cancel';
			} else {
				btn.className = 'button';
			}
			(function(scope, fnCallback, btn) {
				btn.addEventListener('click', function(){fnCallback.apply(scope, [btn]);});
			})(data.scope, data.cbClicked, btn);
			return btn;
		}
		
		this.createPopupNavigation = function(viewsContainer, strTitle) {
			if(!viewsContainer || (viewsContainer.className != 'views-container')){
				return undefined;
			}
			var pn_data = [];
			var blocks = (viewsContainer.getElementsByTagName('ul')[0]).children;
			for(var i=0;i<blocks.length;i++) {
				if(blocks[i].tagName=='LI'){
					var pn_item = {anchor: 'top',
					               name: undefined,
								   description: undefined,
								   color: undefined};
					var li_children = blocks[i].children;
					for(var j=0;j<li_children.length;j++) {
						if(li_children[j].tagName=='DIV' && li_children[j].className=='data-block') {
							pn_item.color = li_children[j].style.borderLeftColor;
							var db_children = li_children[j].children;
							for(var n=0;n<db_children.length;n++) {
								if((db_children[n].tagName=='DIV') &&
								   (db_children[n].className=='view-header' || db_children[n].className=='view-header simple')) {
									var title = db_children[n].getElementsByClassName('view-title')[0];
									var descr = db_children[n].getElementsByClassName('view-description')[0];
									pn_item.name = title.getElementsByTagName('span')[0].innerText;
									pn_item.description = descr.getElementsByTagName('span')[0].innerText;
								}
							}
						} else if(li_children[j].tagName=='A') {
							pn_item.anchor = li_children[j].id;
						}
					}
					pn_data.push(pn_item);
				}
			}
			var pn_wrapper = document.createElement('div');
			pn_wrapper.id = 'pun-wrapper';
			pn_wrapper.addEventListener('click', function(){window.PopupNavigation.hidePopupNavigation()});
			var pn_bg = document.createElement('div');
			pn_bg.id = 'pun-bg';
			pn_wrapper.appendChild(pn_bg);
			var pn_contentwrapper = document.createElement('div');
			pn_contentwrapper.id = 'pun-contentwrapper';
			var pn_content = document.createElement('div');
			pn_content.id = 'pun-content';
			if(strTitle) {
				var title = document.createElement('h1');
				title.innerHTML = strTitle;
				pn_content.appendChild(title);
			}
			var pn_items = document.createElement('ul');
			pn_items.id = 'pun-items';
			for(var i=0;i<pn_data.length;i++) {
				var item = document.createElement('li');
				item.innerHTML = pn_data[i].name;
				(function(strAnchor) {
					item.addEventListener('click', function(){window.PopupNavigation.hidePopupNavigation(strAnchor)});
				})(pn_data[i].anchor);
				pn_items.appendChild(item);
			}
			var nRows = Math.ceil(pn_data.length/5);
			pn_content.appendChild(pn_items);
			pn_content.style.height = (nRows*80+60)+'px';
			pn_content.style.marginTop = '-'+(nRows*80/2+60)+'px';
			pn_contentwrapper.appendChild(pn_content);
			pn_wrapper.appendChild(pn_contentwrapper);
			return pn_wrapper;
		}
		
		this.createSlider = function(id) {
			var slider = document.createElement('ul');
			slider.id = id;
			slider.className = 'slider';
			return slider;
		}
		
		this.createHSPSlide = function(hspdata, strTitle, strDescription, strTopID, cbBlast) {
			var slide = document.createElement('li');
			var header = document.createElement('h3');
			header.innerHTML = strTitle;
			slide.appendChild(header);
			if(strDescription && strDescription.length>0) {
				var desc = document.createElement('h4');
				desc.innerHTML = strDescription;
				slide.appendChild(desc);
			}
			var top = document.createElement('div');
			top.className = 'toplink';
			top.innerHTML = '&#x25B2 overview';
			top.addEventListener('click', function(){GUI.scrollToElement(strTopID)});
			slide.appendChild(top);
			if(cbBlast)
			{
				var blast = document.createElement('div');
				blast.className = 'blastlink';
				var text = document.createElement('span');
				text.innerHTML = 'You can also BLAST the HSP sequence ';
				blast.appendChild(text);
				var local = document.createElement('span');
				local.className = 'actionlink';
				local.innerHTML = 'locally';
				(function(scope, fnCallback, args) {
					local.addEventListener('click', function(){fnCallback.apply(scope, [true].concat(args));});
				})(cbBlast.scope, cbBlast.fnCallback, cbBlast.args);
				blast.appendChild(local);
				text = document.createElement('span');
				text.innerHTML = ' or on ';
				blast.appendChild(text);
				var ncbi = document.createElement('span');
				ncbi.className = 'actionlink';
				ncbi.innerHTML = 'NCBI';
				(function(scope, fnCallback, args) {
					ncbi.addEventListener('click', function(){fnCallback.apply(scope, [false].concat(args));});
				})(cbBlast.scope, cbBlast.fnCallback, cbBlast.args);
				blast.appendChild(ncbi);
				slide.appendChild(blast);
			}
			var alndata = {score: hspdata.score,
						   evalue: hspdata.evalue,
						   algorithm: hspdata.algorithm,
						   first: {name: hspdata.sequence.name,
								   frame: hspdata.sequence.frame,
								   start: hspdata.sequence.start,
								   end: hspdata.sequence.end,
								   sequence: hspdata.sequence.seq},
						   second: {name: hspdata.hit.name,
									frame: hspdata.hit.frame,
									start: hspdata.hit.start,
									end: hspdata.hit.end,
									sequence: hspdata.hit.seq},
						   midline: hspdata.midline,
						   style: this.GB_AS_HEADER};
			var aln = this.createAlignment(alndata);
			slide.appendChild(aln);
			return slide;
		}
    }	
    window.Controls = new Controls();
})();


(function() {
    function GUI() {
		
		this.scrollToElement = function(id) {
			var element = document.getElementById(id);
			if(!element) {
				element = document.getElementsByName(id)[0];
			}
			if(element) {
				$('html, body').animate({scrollTop: $(element).offset().top}, 1000);
			}
		}
		
		this.scrollToTop = function() {
			$('html, body').animate({scrollTop: 0}, 1000);
		}
		
		this.highlightViewBlock = function(target, duration) {
			var anchor = document.getElementById(target);
			var viewblock = anchor.parentNode.getElementsByClassName('data-block')[0];
			this.highlightElement(viewblock, duration);
		}
		
		this.highlightElement = function(element, duration) {
			if(typeof element === 'string') {
				element = document.getElementById(element);
			}
			if(element) {
				if(!duration)
					duration = 5000;
				var old = element.style.backgroundColor;
				element.style.backgroundColor = 'rgba(255,255,155,0.5)';
				$(element).animate({backgroundColor: old}, duration);
			}
		}
		
		this.changeToolbarSelection = function(ctrl, id) {
			var items = ctrl.getElementsByTagName('li');
			for(var i=1;i<items.length;i++) {
				var btn = items[i];
				var child = btn.getElementsByTagName('span')[0];
				if(btn.id == id) {
					if(child)
						child.className = 'push-button pushed';
					else
						btn.className = 'selected';
				} else {
					if(child)
						child.className = 'push-button';
					else
						btn.className = '';
				}
			}
		}
		
		this.displayErrorMsg = function(strMsg, parent) {
			if(parent) {
				var msg_container = document.createElement('div');
				msg_container.className = "view-content-msg";
				var msg = document.createElement('span');
				msg.innerHTML = strMsg;
				msg_container.appendChild(msg);
				parent.appendChild(msg_container);
			}
		}
		
		this.toggleInfoMsg = function(infomsg) {
			if(!infomsg) {return;}
			if(infomsg.className == 'view-infomsg hidden') {
				infomsg.className = 'view-infomsg';
			} else {
				infomsg.className = 'view-infomsg hidden';
			}
		}
	}
	
	window.GUI = new GUI();
})();