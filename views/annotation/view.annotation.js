/*
	File:
		view.annotation.js
		
	Description:
		Contains functions of the Annotation View.
		
	Version:
        1.2.4	
	
	Date:
		08.03.2013
*/

/* Retrieves and displays the contig annotation */
(function() {
	function AnnotationViewer() {
            
		// Variables.
		this.msg = undefined;
		this.wrapper = undefined;
		this.annotations = [];
		this.current = 0;
        
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
			this.wrapper.id = 'annotation-content-wrapper';
			content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Contig.getAnnotation',
										  params: {contigs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}
		
		this.parseData = function(data) {
			var xml = data.responseXML;
			var root = xml.documentElement;
			var annotations = root.getElementsByTagName('contig')[0].getElementsByTagName('annotation');
			if(annotations.length==0) {
				GUI.displayErrorMsg('No annotation is available', this.wrapper);
				GUI.toggleInfoMsg(this.msg);
				return;
			}
			for(var i=0;i<annotations.length;i++) {
				var entry = annotations[i];
				var annotation = {'date': entry.getAttribute('date'),
						          'author': entry.getAttribute('author'),
						          'molecule': entry.getAttribute('molecule'),
						          'basis': entry.getAttribute('basis'),
						          'symbol': entry.getElementsByTagName('symbol')[0].firstChild.nodeValue,
						          'definition': entry.getElementsByTagName('definition')[0].firstChild.nodeValue,
						          'remarks': ''};
				var remarks = entry.getElementsByTagName('remarks')[0];
				if(remarks.firstChild) {
					annotation.remarks = remarks.firstChild.nodeValue;
				}
				this.annotations.push(annotation);
			}
			this.createContent();
		}
		
		this.createContent = function() {
			var table = document.createElement('table');
			table.setAttribute('border', '0');
			table.setAttribute('width', '95%');
			table.id = "annotation-details";
			// First row: gene symbol, spacer, and author.
			var row = document.createElement('tr');
			row.innerHTML = '<td width="12%">Added by:</td>' +
					'<td width="20%"><span id="annotation-author"></span></td>' +
					'<td width="3%" rowspan="3"><div class="spacer"></div></td>' +
					'<td width="12%">Gene symbol:</td>' +
					'<td width="52%"><span id="annotation-symbol"></span></td>';
			table.appendChild(row);
			// Second row: gene description, and date.
			row = document.createElement('tr');
			row.innerHTML = '<td>Added on:</td>' +
							'<td><span id="annotation-date"></span></td>' + 
							'<td rowspan="2" valign="top">Description:</td>' +
							'<td rowspan="2" valign="top"><span id="annotation-desc"></span></td>';
			table.appendChild(row);
			// Third row: basis.
			row = document.createElement('tr');
			row.innerHTML = '<td>Basis:</td>' +
					'<td><span id="annotation-basis"></span></td>';
			table.appendChild(row);
			this.wrapper.appendChild(table);
			// Remarks.
			var remarks = document.createElement('span');
			remarks.id = 'annotation-remarks';
			this.wrapper.appendChild(remarks);
			// Navigation buttons.
			var navbar = document.createElement('ul');
			navbar.id = 'annotation-navbar';
			var titles = ['Annotation version:', 'Latest', 'Previous', 'Next'];
			var callbacks = [undefined, this.displayLatest, this.displayPrevious, this.displayNext];
			var ids = [undefined, 'annotation-btn-latest', 'annotation-btn-prev', 'annotation-btn-next'];
			for(var i=0;i<titles.length;i++) {
				var item = document.createElement('li');
				if(i==0) {
					item.innerHTML = titles[i];
				} else {
					var btn = this.createButton(titles[i], ids[i], callbacks[i], this);
					item.appendChild(btn);
				}
				navbar.appendChild(item);
			}
			this.wrapper.appendChild(navbar);
			this.displayLatest();
			GUI.toggleInfoMsg(this.msg);
		}
		
		this.createButton = function(title, id, fnCallback, scope) {
			var btn = document.createElement('span');
			btn.className = 'push-button';
			btn.id = id;
			btn.innerHTML = title;
			btn.addEventListener('click', function(){fnCallback.apply(scope, [btn]);});
			return btn;
		}
		
		this.displayNext = function(btn) {
			if(btn.className=='push-button disabled') {return;}
			this.displayAnnotation(this.current+1);
		}
		
		this.displayPrevious = function(btn) {
			if(btn.className=='push-button disabled') {return;}
			this.displayAnnotation(this.current-1);
		}
		
		this.displayLatest = function() {
			this.displayAnnotation(0);
		}
		
		this.displayAnnotation = function(index) {
			if(index>=this.annotations.length || index<0) {return;}
			this.current = index;
			var entry = this.annotations[index];
			document.getElementById('annotation-symbol').innerHTML = entry.symbol;
			document.getElementById('annotation-desc').innerHTML = entry.definition;
			document.getElementById('annotation-author').innerHTML = entry.author;
			document.getElementById('annotation-date').innerHTML = entry.date;
			document.getElementById('annotation-basis').innerHTML = entry.basis;
			// Enable/disable the buttons.
			document.getElementById('annotation-btn-next').className = (index<this.annotations.length-1) ? 'push-button' : 'push-button disabled';
			document.getElementById('annotation-btn-prev').className = (index>0) ? 'push-button' : 'push-button disabled';
		}
	}
	
    Views.registerEventHandler('view-annotation', new AnnotationViewer());
})();