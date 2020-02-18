/*
	File:
		aomath.js
		
	Description:
		Contains several math functions that are frequently used in analyses.
	
	Version:
        1.0.1
	
	Date:
		26.02.2018
*/


(function() {
	function AOMath() {
        
        this.calculateMean = function(matrix) {
            var nElem = matrix.length;
            var fSum = 0;
            for(var i=0;i<nElem;i++) {
                fSum += matrix[i];
            }
            return fSum/nElem;
        };
        
        this.calculateMedian = function(matrix) {
            var nElem = matrix.length;
            matrix = Arrays.sort(matrix);
            if((nElem % 2) == 1)
                return matrix[Math.floor(nElem/2)];
            else
                return (matrix[nElem/2] + matrix[(nElem/2)-1])/2;
        };
        
        this.calculateSD = function(matrix) {
            var fMean = this.calculateMean(matrix);
            var nElem = matrix.length;
            if(nElem === 0)
                return undefined;
            var fSum = 0;
            for(var i=0;i<nElem;i++) {
                var tmp = matrix[i] - fMean;
                fSum += tmp*tmp;
            }
            return Math.sqrt(1/(nElem-1)*fSum);
        };
        
        this.calculateSE = function(matrix) {
            var fSD = this.calculateSD(matrix);
            var nElem = matrix.length;
            return fSD/Math.sqrt(nElem);
        };
    }
    
    window.AOMath = new AOMath();
})();