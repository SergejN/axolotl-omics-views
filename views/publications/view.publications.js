/*
	File:
		view.publications.js
		
	Description:
		Contains functions of the Publications View.
		
	Version:
        1.2.4	
	
	Date:
		25.08.2013
*/

/* Retrieves and displays the related publication abstracts */
(function() {
	function PublicationsViewer() {
        
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
            this.wrapper.id = 'publications-content-wrapper';
            content.appendChild(this.wrapper);
			this.sequence = Core.getCurrentSequence();
			Core.sendAPIRequest2({format: 'xml',
				                 requestID: 1,
								 method: {name: 'Literature.getAbstractsList',
										  params: {contigs: this.sequence.id}},
								 callback: {scope: this,
								            fn: this.parseData}});
        }
        
        this.parseData = function(data) {
            var xml = data.responseXML;
            var root = xml.documentElement;
            var contig = root.getElementsByTagName('contig')[0];
            if(!contig) {
                GUI.displayErrorMsg('No related publications could be found', this.wrapper);
                GUI.toggleInfoMsg(this.msg);
                return;
            }
			var publications = contig.getElementsByTagName('publication');
			if(publications.length==0) {
				this.displayErrorMsg('No related publications are available');
				GUI.toggleInfoMsg(this.msg);
				return;
			}
			var descr = document.createElement('div');
			descr.id = 'publications-description';
			descr.innerHTML = 'The following list is based on the information obtained from the <a href="http://www.string-db.org" target="_blank">STRING database</a> and '+
								'<a href="http://www.ncbi.nlm.nih.gov/pubmed/" target="_blank">PubMed</a>. You can also manually search those databases to get more results.';
			this.wrapper.appendChild(descr);
			
			var publist = document.createElement('ul');
			publist.className = 'publications-list';
			for(var i=0;i<publications.length;i++) {
				var pub = publications[i];
				var item = document.createElement('li');
				// Authors.
				var authors = [];
				var au_list = pub.getElementsByTagName('author');
				for(var j=0;j<au_list.length;j++) {
					authors.push(au_list[j].getAttribute('name'));
				}
				var strAuthor = authors.join(', ');
				// Journal: date;Volume (Issue):pages.
				var strIssue = (pub.getAttribute('issue').length>0) ? '('+pub.getAttribute('issue')+')' : '';
				item.innerHTML = '<div class="publications-journal"><b>'+pub.getAttribute('journal')+'</b> '+
																	 pub.getAttribute('date')+'; '+
																	 pub.getAttribute('volume')+' '+
																	 strIssue+':'+
																	 pub.getAttribute('pages')+
									'</div>' +
								 '<div class="publications-title"><a target="_blank" href="'+Core.extractLongText(pub.getElementsByTagName('link')[0])+'">'+
																	 pub.getAttribute('title')+'</a></div>' +
								 '<div class="publications-author">'+strAuthor+'</div>' +
								 '<div class="publications-abstract">'+Core.extractLongText(pub)+'</div>';
				publist.appendChild(item);
			}
			this.wrapper.appendChild(publist);
            GUI.toggleInfoMsg(this.msg);
        }
    }
	
    Views.registerEventHandler('view-publications', new PublicationsViewer());
})();