/*
	File:
		views.js
		
	Description:
		Contains general functions of the views.
		
	Date:
		31.01.2013
*/

(function() {
	function Views() {
		
		this.actions_map = {};

		this.registerEventHandler = function(viewID, objHandler) {
			this.actions_map[viewID] = objHandler;
		}
		
		this.toggle = function(view) {
			var state = Controls.toggleView(view);
			var msg = view.getElementsByClassName('view-infomsg hidden')[0];
			if(!msg) {
				msg = view.getElementsByClassName('view-infomsg')[0];
			}
			var objHandler = this.actions_map[view.id];
			if(objHandler) {
				objHandler.toggleView(view, state, msg);
			}
		}
		
		this.execute = function() {
			var params = Array.prototype.slice.call(arguments);
			var viewID = params.shift();
			var strMethod = params.shift();
			var objHandler = this.actions_map[viewID];
			if(objHandler) {
				var pfnMethod = objHandler[strMethod];
				pfnMethod.call(params);
			}
		}
	}
	
	window.Views = new Views();
})();