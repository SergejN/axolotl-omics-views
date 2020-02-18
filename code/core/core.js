/*
	File:
		core.js
		
	Description:
		Contains a set of general functions all pages might use.
		
	Date:
		20.05.2013
*/

(function() {
	function Core() {
		
			var WEBSITE_ROOT = window.location.protocol + '//' + window.location.hostname + '/';
			
			// Method constants.
			this.ERR_OK 						= 0;
			this.ERR_OK_BINARY 					= -1;
			this.ERR_METHOD_NOT_FOUND 			= 1;
			this.ERR_NOT_ENOUGH_PARAMETERS 		= 2;
			this.ERR_INVALID_PARAMETER 			= 3;
			this.ERR_MALFORMED_QUERY 			= 4;
			this.ERR_DATA_NOT_FOUND 			= 5;
			this.ERR_DB_ERROR 					= 6;
			this.ERR_ACCESS_DENIED 				= 7;
			this.ERR_RUNTIME_ERROR 				= 8;
			this.ERR_DATA_EXISTS 				= 9;
			
			this.SAR_RT_XML	= 0;
			this.SAR_RT_TEXT = 1;
			
			this.SequenceType = {ST_TRANSCRIPT: 'transcript',
								 ST_LIBRARY_SEQUENCE: 'libseq',
								 ST_READ: 'read',
								 ST_PROBE: 'probe',
								 ST_GENE: 'gene'};
			this.sequence = {id: undefined, type: undefined};
			
			
			this.getCurrentSequence = function() {
				return this.sequence;
			}
			
			this.setCurrentSequence = function(id, type) {
				this.sequence = {id: id, type: type};
			}
			
            this.fillArray = function(length, value) {
                var array = [];
                for (var i = 0; i < length; i++) {
                        array[i] = value;
                }
                return array;
            }
			
			this.range = function(iFrom, iTo, iStep) {
				if(!iStep)
					iStep = 1;
				var data = [];
				for(var i=iFrom;i<=iTo;i+=iStep) {
					data.push(i);
				}
				return data;
			}

            this.getXmlHttp = function() {
                var xmlhttp;
                try {
					xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
                } catch (e) {
					try {
						xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
					} catch (E) {
						xmlhttp = false;
					}
                }
                if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
                    xmlhttp = new XMLHttpRequest();
                }
                return xmlhttp;
            }
			
			this.sendAPIRequest2 = function(data) {
				if(!data.method || !data.method.name)
					return {result: this.ERR_NOT_ENOUGH_PARAMETERS};
				if(!data.sync && (!data.callback || !data.callback.fn))
					return {result: this.ERR_NOT_ENOUGH_PARAMETERS};
				if(!data.format)
					data.format = 'xml';
				if(!data.requestID)
					data.requestID = 1;
				var strRequest = 'format='+data.format+
				                 '&requestID='+data.requestID+
								 '&method='+data.method.name;
				for(var param in data.method.params) {
					strRequest += '&'+param+'='+data.method.params[param];
				}
				var req = this.getXmlHttp();
				if(data.sync) {
					req.open("POST", WEBSITE_ROOT+'api', false);
				} else {
					req.open("POST", WEBSITE_ROOT+'api', true);
					req.onreadystatechange = function() {
						var scope = data.callback.scope ? data.callback.scope : this;
						var args = data.callback.args ? [req].concat(data.callback.args) : [req];
						if (req.readyState==4 && req.status==200) {
							data.callback.fn.apply(scope, args);
						}
					}
				}
				req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.send(strRequest);
				if(data.sync) {
					return {result: this.ERR_OK,
					        data: (data.format == 'xml') ? req.responseXML : req.responseText};
				}
				return {result: this.ERR_OK};
			}
			
            this.sendAPIRequest = function(request, callback, opts, bSynchronous) {
				alert('Deprecated method called! Please, submit a bug report');
                return this.sendAjaxRequest(WEBSITE_ROOT+'api', request, callback, opts, bSynchronous, false);
            }
            
            this.sendAjaxRequest = function(target, request, callback, opts, bSynchronous, bAsText) {
                var req = this.getXmlHttp();
				if(bSynchronous) {
					req.open("POST", target, false);
				} else {
					req.open("POST", target, true);
					req.onreadystatechange = function() {
						var scope = opts.scope ? opts.scope : this;
						var args = opts.args ? [req].concat(opts.args) : [req];
						if (req.readyState==4 && req.status==200) {
							callback.apply(scope, args);
						}
					}
				}
				req.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.send(request);
				if(bSynchronous) {
					return (bAsText) ? req.responseText : req.responseXML;
				} else {
					return '';
				}
            }

            this.toggleInfoMsg = function(infomsg) {
				alert('Deprecated. Please report to the administrator');
                if(!infomsg) {return;}
                if(infomsg.className == 'view-infomsg hidden') {
                    infomsg.className = 'view-infomsg';
                } else {
                    infomsg.className = 'view-infomsg hidden';
                }
            }
			
			this.extractLongText = function(node) {
				if(!node) return "";
				var str = "";
				for (var i=0;i<node.childNodes.length;i++) {
					if(node.childNodes[i].nodeValue!=null) {
						str += node.childNodes[i].nodeValue;
					}
				}
				return str;
			}
			
			this.showPopup = function(content) {
				$.magnificPopup.open({
						items: {
						  src: content,
						  type: 'inline'
						}
				});
			}
			
			this.closePopup = function() {
				$.magnificPopup.close();
			}
			
			this.showMessage = function(strMsg, strType) {
				toastr.options = {"closeButton": false,
								  "debug": false,
								  "positionClass": "toast-top-full-width",
								  "onclick": null,
								  "showDuration": "300",
								  "hideDuration": "1000",
								  "timeOut": "3000",
								  "extendedTimeOut": "1000",
								  "showEasing": "swing",
								  "hideEasing": "linear",
								  "showMethod": "fadeIn",
								  "hideMethod": "fadeOut"
								 };
				if(!strType)
					strType = 'info';
				if(strType == 'info') {
					toastr.success(strMsg);
				} else {
					if(strType == 'error') {
						toastr.error(strMsg);
					} else {
						return;
					}
				}
			}
			
			this.getBaseAddress = function() {
				return WEBSITE_ROOT;
			}
			
			this.getORFDetails = function(iStart) {
				var frames = {'1' : "5' &raquo; 3', frame 1",
						      '2' : "5' &raquo; 3', frame 2",
						      '0' : "5' &raquo; 3', frame 3",
						      '-1': "3' &raquo; 5', frame 1",
						      '-2': "3' &raquo; 5', frame 2",
						      '-0': "3' &raquo; 5', frame 3"};
				var orf = undefined;
				if(iStart>0) {
					var index = iStart % 3;
					orf = {title: frames[''+index],
						   sense: true,
						   frame: (index>0) ? index : 3};
				} else {
					var index = -iStart % 3;
					orf = {title: frames['-'+index],
						   sense: false,
						   frame: (index>0) ? index : 3};
				}
				return orf;
			}
			
			this.parseHSPdata = function(hsp, strSeqName, strHitName) {
				var fEvalue = hsp.getAttribute('evalue');
				var fScore = hsp.getAttribute('bitscore');
				var strAlgorithm = hsp.getAttribute('algorithm');
				var inc = {'blastn' : {query: 1, hit: 1},
				           'blastp' : {query: 1, hit: 1},
						   'tblastn': {query: 1, hit: 3},
						   'tblastx': {query: 3, hit: 3},
						   'blastx' : {query: 3, hit: 1}};
				var factors = (inc[strAlgorithm]) ? inc[strAlgorithm] : {query: 1, hit: 1};
				var strMidline = this.extractLongText(hsp.getElementsByTagName('midline')[0]);
				var bInvertHit = false;
				// Sequence data.
				var ss, se;
				var seq = hsp.getElementsByTagName('sequence')[0];
				if(!seq)
					seq = hsp.getElementsByTagName('query')[0];
				var strSSeq = this.extractLongText(seq);
				var ss = parseInt(seq.getAttribute('start'));
				var sf = parseInt(seq.getAttribute('frame'));
				if(sf>=0) {
					ss = parseInt(seq.getAttribute('start'));
					se = ss+strSSeq.replace(/-/g, '').length*factors.query-1;
				} else {
					se = parseInt(seq.getAttribute('start'));
					ss = ss-strSSeq.replace(/-/g, '').length*factors.query+1;
					strSSeq = this.buildReverseComplement(strSSeq);
					strMidline = strMidline.split('').reverse().join('');
					sf = -sf;
					bInvertHit = true;
				}
				// Hit data.
				var hs, he;
				var hit = hsp.getElementsByTagName('hit')[0];
				var strHSeq = this.extractLongText(hit);
				var hf = parseInt(hit.getAttribute('frame'));
				if(hf>=0) {
					hs = parseInt(hit.getAttribute('start'));
					he = hs+strHSeq.replace(/-/g, '').length*factors.hit-1;
				} else {
					he = parseInt(hit.getAttribute('start'));
					hs = he-strHSeq.replace(/-/g, '').length*factors.hit+1;
				}
				if(bInvertHit) {
					strHSeq = this.buildReverseComplement(strHSeq);
					var tmp = hs;
					hs = he;
					he = tmp;
					hf = -hf;
				}
				return {sequence: {seq: strSSeq,
				                   start: ss,
								   end: se,
								   frame: sf,
								   name: strSeqName},
						hit: {seq: strHSeq,
						      start: hs,
							  end: he,
							  frame: hf,
							  name: strHitName},
						midline: strMidline,
						score: fScore,
						evalue: fEvalue,
						algorithm: strAlgorithm};
			}
			
			this.buildReverseComplement = function(strSeq) {
				strSeq = strSeq.toUpperCase();
				var lookupTable = {A: 'T',
								   C: 'G',
								   G: 'C',
								   T: 'A'};
				var result = strSeq.split('').reverse();
				for(var i=0;i<result.length;i++) {
					var c = lookupTable[result[i]];
					if(c !== undefined) {
						result[i] = c;
					} else {
						result[i] = result[i].toLowerCase();
					}
				}
				return result.join('');
			}
        }
        
        window.Core = new Core();
})();
