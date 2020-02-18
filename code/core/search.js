/*
	File:
		search.js
		
	Description:
		Contains general functions of the search pages.
		
	Date:
		18.02.2013
*/

(function() {
	function Search() {
		
		this.keyPress = function(event, strCategory) {
			if(event && event.keyCode==13) {
				this.submit(strCategory);
			}
		}

		this.submit = function(strCategory, from) {
		    var form = document.createElement('form');
			form.setAttribute('action', '/search');
			form.setAttribute('method', 'get');
			form.appendChild(this.createElement('query', document.getElementsByName('searchquery')[0].value));
			var assemblies = [];
			var asmlist = document.getElementById('search-assemblies');
			if(asmlist) {
				var inputs = asmlist.getElementsByTagName('input');
				for(var i=0;i<inputs.length;i++) {
					var input = inputs[i];
					if(input.getAttribute('type') == 'checkbox' && input.checked) {
						assemblies.push(parseInt(input.getAttribute('version'), 10));
					}
				}
			}
			if(assemblies.length>0) {
				form.appendChild(this.createElement('assemblies', assemblies.join(',')));
			}
			if(strCategory) {
				form.appendChild(this.createElement('category', strCategory));
			}
			if(from) {
				form.appendChild(this.createElement('start', from));
			}
			document.getElementsByTagName('body')[0].appendChild(form);
			form.submit();
		}
		
		this.createElement = function(name, value) {
			var element = document.createElement('input');
			element.setAttribute('type', 'hidden');
			element.setAttribute('name', name);
			element.setAttribute('value', value);
			return element;
		}
	}
	
	window.Search = new Search();
})();