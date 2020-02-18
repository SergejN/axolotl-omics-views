/*
	File:
		aobio.js
		
	Description:
		Contains several frequently used functions for biological data.
	
	Version:
        1.0.1
	
	Date:
		23.08.2018
*/


(function() {
	function AOBio() {

		this.codonTable = {GCA: {OLC: 'A', TLC: 'Ala', name: 'Alanine'},
						   GCC: {OLC: 'A', TLC: 'Ala', name: 'Alanine'},
						   GCG: {OLC: 'A', TLC: 'Ala', name: 'Alanine'},
						   GCT: {OLC: 'A', TLC: 'Ala', name: 'Alanine'},
						   
						   AGA: {OLC: 'R', TLC: 'Arg', name: 'Arginine'},
						   AGG: {OLC: 'R', TLC: 'Arg', name: 'Arginine'},
						   CGA: {OLC: 'R', TLC: 'Arg', name: 'Arginine'},
						   CGC: {OLC: 'R', TLC: 'Arg', name: 'Arginine'},
						   CGG: {OLC: 'R', TLC: 'Arg', name: 'Arginine'},
						   CGT: {OLC: 'R', TLC: 'Arg', name: 'Arginine'},
						   
						   AAC: {OLC: 'N', TLC: 'Asn', name: 'Asparagine'},
						   AAT: {OLC: 'N', TLC: 'Asn', name: 'Asparagine'},
						   
						   GAC: {OLC: 'D', TLC: 'Asp', name: 'Aspartic acid'},
						   GAT: {OLC: 'D', TLC: 'Asp', name: 'Aspartic acid'},
						   
						   TGC: {OLC: 'C', TLC: 'Cys', name: 'Cysteine'},
						   TGT: {OLC: 'C', TLC: 'Cys', name: 'Cysteine'},
						   
						   GAA: {OLC: 'E', TLC: 'Glu', name: 'Glutamic acid'},
						   GAG: {OLC: 'E', TLC: 'Glu', name: 'Glutamic acid'},
						   
						   CAA: {OLC: 'Q', TLC: 'Gln', name: 'Glutamine'},
						   CAG: {OLC: 'Q', TLC: 'Gln', name: 'Glutamine'},
						   
						   GGA: {OLC: 'G', TLC: 'Gly', name: 'Glycine'},
						   GGC: {OLC: 'G', TLC: 'Gly', name: 'Glycine'},
						   GGG: {OLC: 'G', TLC: 'Gly', name: 'Glycine'},
						   GGT: {OLC: 'G', TLC: 'Gly', name: 'Glycine'},
						   
						   CAC: {OLC: 'H', TLC: 'His', name: 'Histidine'},
						   CAT: {OLC: 'H', TLC: 'His', name: 'Histidine'},
						   
						   ATA: {OLC: 'I', TLC: 'Ile', name: 'Isoleucine'},
						   ATC: {OLC: 'I', TLC: 'Ile', name: 'Isoleucine'},
						   ATT: {OLC: 'I', TLC: 'Ile', name: 'Isoleucine'},
						   
						   CTA: {OLC: 'L', TLC: 'Leu', name: 'Leucine'},
						   CTC: {OLC: 'L', TLC: 'Leu', name: 'Leucine'},
						   CTG: {OLC: 'L', TLC: 'Leu', name: 'Leucine'},
						   CTT: {OLC: 'L', TLC: 'Leu', name: 'Leucine'},
						   TTA: {OLC: 'L', TLC: 'Leu', name: 'Leucine'},
						   TTG: {OLC: 'L', TLC: 'Leu', name: 'Leucine'},
						   
						   AAA: {OLC: 'K', TLC: 'Lys', name: 'Lysine'},
						   AAG: {OLC: 'K', TLC: 'Lys', name: 'Lysine'},
						   
						   ATG: {OLC: 'M', TLC: 'Met', name: 'Methionine'},
						   
						   TTC: {OLC: 'F', TLC: 'Phe', name: 'Phenylalanine'},
						   TTT: {OLC: 'F', TLC: 'Phe', name: 'Phenylalanine'},
						   
						   CCA: {OLC: 'P', TLC: 'Pro', name: 'Proline'},
						   CCC: {OLC: 'P', TLC: 'Pro', name: 'Proline'},
						   CCG: {OLC: 'P', TLC: 'Pro', name: 'Proline'},
						   CCT: {OLC: 'P', TLC: 'Pro', name: 'Proline'},
						   
						   AGC: {OLC: 'S', TLC: 'Ser', name: 'Serine'},
						   AGT: {OLC: 'S', TLC: 'Ser', name: 'Serine'},
						   TCA: {OLC: 'S', TLC: 'Ser', name: 'Serine'},
						   TCC: {OLC: 'S', TLC: 'Ser', name: 'Serine'},
						   TCG: {OLC: 'S', TLC: 'Ser', name: 'Serine'},
						   TCT: {OLC: 'S', TLC: 'Ser', name: 'Serine'},
						   
						   GTA: {OLC: 'V', TLC: 'Val', name: 'Valine'},
						   GTC: {OLC: 'V', TLC: 'Val', name: 'Valine'},
						   GTG: {OLC: 'V', TLC: 'Val', name: 'Valine'},
						   GTT: {OLC: 'V', TLC: 'Val', name: 'Valine'},
						   
						   ACA: {OLC: 'T', TLC: 'Thr', name: 'Threonine'},
						   ACC: {OLC: 'T', TLC: 'Thr', name: 'Threonine'},
						   ACG: {OLC: 'T', TLC: 'Thr', name: 'Threonine'},
						   ACT: {OLC: 'T', TLC: 'Thr', name: 'Threonine'},
						   
						   TGG: {OLC: 'W', TLC: 'Trp', name: 'Tryprophan'},
						   
						   TAC: {OLC: 'Y', TLC: 'Tyr', name: 'Tyrosine'},
						   TAT: {OLC: 'Y', TLC: 'Tyr', name: 'Tyrosine'},
						   
						   TAA: {OLC: '-', TCL: 'TER', name: 'Terminator'},
						   TAG: {OLC: '-', TCL: 'TER', name: 'Terminator'},
						   TGA: {OLC: '-', TCL: 'TER', name: 'Terminator'}};

		/*
			Returns the codon table object.
		*/
		this.getCodonTable = function() {
			return this.codonTable;
		};

		/*
			Returns either the one-letter code (OLC), the three-letter code (TLC) or
			the full name for the specified codon or undefined if the codon is not valid.

			Parameters:
				strCodon		codon to retrieve the amino acid for
				mode			0 (default): return the one-letter code
								1		   : return the three-letter code
								2		   : return the full name

			Return values:
				Aminoacid name			if succeeds
				undefined				otherwise
		*/
		this.getAminoAcid = function(strCodon, mode) {
			if(strCodon.length != 3) {
				return undefined;
			}

			var entry = this.codonTable[strCodon];
			if(!entry) {
				return undefined;
			}

			if(mode == 1) {
				return entry.TLC;
			} else if(mode == 2) {
				return entry.name;
			} else {
				return entry.OLC;
			}
		};

		/*
			Translates the specified sequence starting from the first nucleotide.

			Parameters:
				strSeq			sequence to translate
				mode			0 (default): return the one-letter codes
								1		   : return the three-letter codes

			Return values:
				Translated aminoacid sequence
		*/
		this.translate = function(strSeq, mode) {
			if(!strSeq) {
				return "";
			}
			var iPos = 0;
			var strProtein = '';
			while(iPos <= strSeq.length-3) {
				var strCodon = strSeq.substr(iPos, 3);
				var strAA = this.getAminoAcid(strCodo, (mode == 1) ? 1 : 0);
				if(!strAA) {
					strAA = '?';
				}
				strProtein += strAA;
				iPos += 3;
			}
			return strProtein;
		};

		/*
			Calculates the codon frequencies in the given sequence and returns an object
			contaning the OLC:frequency pairs.

			Parameters:
				strSequence		sequence to analyze

			Return values:
				Codon frequency table
		*/
		this.calculateCodonFrequencies = function(strSequence) {
			strSequence = strSequence.toUpperCase();
			var arrCodons = Object.keys(this.codonTable);
			var codons = {};
			for(var i=0;i<arrCodons.length;i++) {
				codons[arrCodons[i]] = 0;
			}
			if(!strSequence) {
				return freqs;
			}
			var iPos = 0;
			var aminoacids = {};
			while(iPos <= strSequence.length-3) {
				var strCodon = strSequence.substr(iPos, 3);
				codons[strCodon]++;
				if(this.codonTable[strCodon]) {
					var strAA = this.codonTable[strCodon].OLC;
					if(aminoacids[strAA])
						aminoacids[strAA]++;
					else
						aminoacids[strAA] = 1;
				}
				iPos +=3;
			}
			var freqs = {};
			for(var i=0;i<arrCodons.length;i++) {
				var strCodon = arrCodons[i];
				var strAA = this.codonTable[strCodon].OLC;
				var nTotal = aminoacids[strAA];
				var nCodon = codons[strCodon];
				if(nTotal > 0)
					freqs[strCodon] = (nCodon/nTotal);
				else
					freqs[strCodon] = 0;
			}
			return freqs;
		};

		/*
			Parses the text in FASTA format and returns an array of sequences. Each
			sequence is an object with the following properties:
				name		content of the FASTA header without the '>' character
				sequence 	entry sequence
		*/
		this.parseSequences = function(strText) {
			var arrSeqs = [];
			if(!strText) {
				return arrSeqs;
			}
			if(!strText) {
				return arrSeqs;
			}
			var arrLines = strText.split('\n');
			var entry = undefined;
			for(var i = 0;i<arrLines.length;i++) {
				var res = arrLines[i].match(/^>(.+)$/);
				if(res) {
					entry = {name: res[1], sequence: ''};
					arrSeqs.push(entry);
				} else {
					if(entry.name) {
						entry.sequence += arrLines[i];
					}
		        }
			}
			return arrSeqs;
		}
	}
    
    window.AOBio = new AOBio();
})();