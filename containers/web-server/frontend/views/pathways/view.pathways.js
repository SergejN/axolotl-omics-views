/*
	File:
		view.pathways.js
		
	Description:
		Contains functions of the Pathways View.
	
	Version:
        1.1.6	
	
	Date:
		17.05.2014
*/

/* Retrieves and displays the pathways details */
(function() {
    function PathwaysViewer() {
        
		this.wrapper = undefined;
		this.msg = undefined;
		this.panes = {};
		this.todo = {};
		
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
            this.wrapper.id = 'pathways-content-wrapper';
            content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Pathway.findPathways',
										  params: {contigs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
		}

        this.parseData = function(data) {
            var xml = data.responseXML;
            var root = xml.documentElement;
            var contig = root.getElementsByTagName('contig')[0];
            if(!contig) {
                GUI.displayErrorMsg('No pathway information could be found', this.wrapper);
                GUI.toggleInfoMsg(this.msg);
                return;
            }
			var pathways = contig.getElementsByTagName('pathway');
			var ul = document.createElement('ul');
			ul.id = 'pathways-list';
			for(var i=0;i<pathways.length;i++){
				var li = document.createElement('li');
				var item = document.createElement('div');
				// Pathway ID
				var strID = pathways[i].getAttribute('id');
				var id = document.createElement('div');
				id.className = 'pathway-id';
				var link = document.createElement('span');
				link.innerHTML = strID;
				(function(scope, fnCallback, strID) {
					link.addEventListener('click', function(){fnCallback.apply(scope, [strID]);});
				})(this, this.togglePathway, strID);
				id.appendChild(link);
				item.appendChild(id);
				// Pathway name
				var name = document.createElement('div');
				name.className = 'pathway-name';
				name.innerHTML = Core.extractLongText(pathways[i]);
				item.appendChild(name);
				// Pathway members pane.
				var pane = document.createElement('div');
				pane.className = 'pathways-pane hidden';
				pane.id = 'pathways-pane-'+strID;
				this.panes[strID] = false;
				item.appendChild(pane);
				li.appendChild(item);
				ul.appendChild(li);
			}
			this.wrapper.appendChild(ul);
            GUI.toggleInfoMsg(this.msg);
        }
		
		this.togglePathway = function(pwid) {
			// If the pathway pane already exists, toggle it. Otherwise, create it first and then display.
			if(this.panes[pwid]){
				var pane = document.getElementById('pathways-pane-'+pwid);
				if(pane.className == 'pathways-pane hidden') {
					pane.className = 'pathways-pane';
				} else {
					pane.className = 'pathways-pane hidden';
				}
			} else {
				GUI.toggleInfoMsg(this.msg);
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'Pathway.getPathwayDetails',
										      params: {pathways: pwid}},
								     callback: {scope: this,
								                fn: this.createPathwayPane}});
			}
		}
		
		this.createPathwayPane = function(data) {
			var xml = data.responseXML;
            var root = xml.documentElement;
			var pathway = root.getElementsByTagName('pathway')[0];
			var pwid = pathway.getAttribute('name');
			var organisms = pathway.getElementsByTagName('organism');
			var pane = document.getElementById('pathways-pane-'+pwid);
			// Create a separate block for each organism.
			for(var i=0;i<organisms.length;i++) {
				var organism = organisms[i];
				var strName = organism.getAttribute('name');
				this.todo[strName] = [];
				var title = document.createElement('div');
				title.className = 'pathways-blocktitle';
				title.id = 'pathways-bt-'+pwid+'-'+strName;
				title.innerHTML = strName;
				(function(scope, fnCallback, arrParams) {
					title.addEventListener('click', function(){fnCallback.apply(scope, arrParams);});
				})(this, this.toggleOrganism, [pwid, strName]);
				pane.appendChild(title);
				var block = document.createElement('div');
				block.className = 'pathways-block hidden';
				block.id = 'pathways-block-'+pwid+'-'+strName;
				var table = document.createElement('table');
				var headers = ['Component', 'UniProtKB ID', 'Name', 'Description', ''];
				for(var j=0;j<headers.length;j++) {
					var th = document.createElement('th');
					th.innerHTML = headers[j];
					table.appendChild(th);
				}
				var members = Array.prototype.slice.call(organism.getElementsByTagName('member'));
				members.sort(function(a,b){
						var a_id = a.getAttribute('id').toLowerCase();
						var b_id = b.getAttribute('id').toLowerCase();
						if(a_id<b_id) {
							return -1;
						}
						else if(a_id>b_id) {
							return 1;
						} else {
							return a.getAttribute('UniProtKB').localeCompare(b.getAttribute('UniProtKB'));
						}
					});
				var prev = undefined;
				for(var j=0;j<members.length;j++) {
					var pdbid = members[j].getAttribute('id');
					var upkb = members[j].getAttribute('UniProtKB');
					if(!prev || (prev.pdbid!=pdbid || prev.upkb!=upkb)){ 
						var tr = document.createElement('tr');
						// ID.
						var td = document.createElement('td');
						td.innerHTML = '<a target="_blank" href="http://www.pantherdb.org/pathway/pathCatDetail.do?clsAccession='+pdbid+'">'+pdbid+'</a>';
						tr.appendChild(td);
						// UniProtKB.
						td = document.createElement('td');
						td.innerHTML = '<a target="_blank" href="http://www.uniprot.org/uniprot/'+upkb+'">'+upkb+'</a>';
						tr.appendChild(td);
						// Symbol.
						td = document.createElement('td');
						td.innerHTML = members[j].getAttribute('symbol');
						tr.appendChild(td);
						// Description.
						td = document.createElement('td');
						td.innerHTML = Core.extractLongText(members[j]);
						tr.appendChild(td);
						// Loading.
						td = document.createElement('td');
						td.id = 'pw-'+pwid+'-c-'+pdbid+'-up-'+upkb;
						td.className = 'busy';
						td.title = 'Searching for Axolotl homologs...';
						tr.appendChild(td);
						table.appendChild(tr);
						this.todo[strName].push({upkb: upkb, wbid: td.id});
					}
					prev = {pdbid: pdbid, upkb: upkb};
				}
				block.appendChild(table);
				var separator = document.createElement('div');
				separator.className = 'separator';
				block.appendChild(separator);
				pane.appendChild(block);
			}
			pane.className = 'pathways-pane';
			this.panes[pwid] = true;
			GUI.toggleInfoMsg(this.msg);
		}
		
		this.toggleOrganism = function(pwID, orgID) {
			var block = document.getElementById('pathways-block-'+pwID+'-'+orgID);
			if(block.className == 'pathways-block hidden') {
				block.className = 'pathways-block';
				var item = this.todo[orgID].shift();
				while(item) {
					this.checkHomologs(undefined, item.upkb, item.wbid);
					item = this.todo[orgID].shift();
				}
			} else {
				block.className = 'pathways-block hidden';
			}
		}
		
		this.checkHomologs = function(data, upkb, wbid) {
			if(!data) {
				Core.sendAPIRequest2({format: 'xml',
				                     requestID: 1,
								     method: {name: 'Contig.getHomologousContigs',
										  params: {type: 'uniprotkb',
								                   ids: upkb}},
								 callback: {scope: this,
								            fn: this.checkHomologs,
									        args: [upkb, wbid]}});
			} else {
				var xml = data.responseXML;
				var root = xml.documentElement;
				var query = root.getElementsByTagName('query')[0];
				var wb = document.getElementById(wbid);
				if(query){
					var contigs = query.getElementsByTagName('contig');
					wb.className = 'success';
					wb.title = (contigs.length>1) ? contigs.length + ' homologs found. Click to view the contigs list'
												  : 'One homolog found. Click to view the contig name';
					var homologs = [];
					for(var i=0;i<contigs.length;i++) {
						homologs.push({name: contigs[i].getAttribute('name'),
									   assembly: parseInt(contigs[i].getAttribute('assembly'), 10),
									   length: contigs[i].getAttribute('length')});
					}
					homologs.sort(function(a,b) {return a.assembly-b.assembly});
					(function(scope, fnCallback, homologs) {
						wb.addEventListener('click', function(){fnCallback.apply(scope, [homologs]);});
					})(this, this.showHomologs, homologs);
				} else {
					wb.className = 'failure';
					wb.title = 'No homologs found. Click to run Blast';
					wb.addEventListener('click', function(){Viewer.blastSequence(true, undefined, 'tblastn', undefined, undefined, undefined, {source: 'UniProtKB', id: upkb});});
				}
			}
		}
		
		this.showHomologs = function(homologs) {
			var block = document.createElement('div');
			block.id = 'pathways-homologs-list';
			var title = document.createElement('h3');
			title.innerHTML = 'List of homologous axolotl contigs';
			block.appendChild(title);
			var table = document.createElement('table');
			var hdr = ['Contig', 'Length', 'Assembly'];
			for(var i=0;i<hdr.length;i++) {
				var th = document.createElement('th');
				th.innerHTML = hdr[i];
				table.appendChild(th);
			}
			for(var i=0;i<homologs.length;i++) {
				var row = document.createElement('tr');
				var td = document.createElement('td');
				td.innerHTML = '<a target="_blank" href="viewer?contigID='+homologs[i].name+'">'+homologs[i].name+'</a>';
				row.appendChild(td);
				
				td = document.createElement('td');
				td.innerHTML = homologs[i].length;
				row.appendChild(td);
				
				td = document.createElement('td');
				td.innerHTML = '<a target="_blank" href="viewer?assembly&version='+homologs[i].assembly+'">'+homologs[i].assembly+'</a>';
				row.appendChild(td);
				table.appendChild(row);
			}
			block.appendChild(table);
			Core.showPopup(block.outerHTML);
		}
    }
	
    Views.registerEventHandler('view-pathways', new PathwaysViewer());
})();	