#!/usr/bin/env perl

#   File:
#       Homology.pm
#
#   Description:
#       Contains the Homology core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.10.2
#
#   Date:
#       25.11.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use Storable;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use Axolotl::ATAPI::Constants;


package Homology;
{
    my $MODULE = 'Homology';
    my $VERSION = '1.10.2';
    my $DATE = '2014-11-25';
    
    my $PACBIO_GENOMIC = 'TLAMEXGCPB';
    
    sub new
    {
        my $class = shift;
        my $self = {_db => undef, _fnAddNodes => undef};
        bless $self, $class;
        return $self;
    }
    
    # Common plug-in methods.
    sub init
    {
        my ($self, $hDB, $fnAddNodes, $ps) = @_;
        $self->{_db} = $hDB;
        $self->{_fnAddNodes} = $fnAddNodes;
	$self->{_external} = $ps->getSetting('HOMOLOGY', 'external');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the homology details.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my $strExampleContig = 'NT_01000010432.2';
        my @arrMethods = ({_name => 'listHomologs',
                           _description => 'Returns the homologs of the specified sequence(s)',
                           _args => [{_name => 'seqIDs',
                                        _description => 'Comma-separated list of sequence IDs to retrieve homologs for',
                                        _type => 'required',
                                        _default => ''},
                                     {_name => 'values',
                                        _description => 'Comma-separated list of additional values to retrieve. Currently, only "alignment" is supported',
                                        _type => 'optional',
                                        _default => ''},
                                     {_name => 'type',
                                        _description => 'Type of the homologs to retrieve. Can be one the combination of the following values: '.
							    '"RefSeq", "LibSeq", "Pfam", "GenBank", "Versions", "Paralogs", "ISH", "MicroArray", or "PacBio"',
                                        _type => 'optional',
                                        _default => 'RefSeq,LibSeq'},
                                     {_name => 'evalue',
                                        _description => 'E-value threshold',
                                        _type => 'optional',
                                        _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence IDs are specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listHomologs&seqIDs=$strExampleContig&values=statistics,alignment",
			   _remarks => "No entry is created in the resulting XML if the sequence ID is invalid or if the sequence has no homologs."});
        return \@arrMethods;
    }
    
    sub execute
    {
        my ($self, %hmParams) = @_;
        my $strMethod = $hmParams{_method};
        my $refMethodParams = $hmParams{_parameters};
        my $xmldoc = $hmParams{_xmldoc};
        my $xmldata = $hmParams{_xmldata};
        my $xmlerr = $hmParams{_xmlerr};
        # Execute the method.
        if($strMethod eq 'listHomologs')
        {
            return $self->listHomologs($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub listHomologs
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqIDs = (defined $refParams->{seqIDs}) ? split(/,/, $refParams->{seqIDs}) : ();
        my @arrValues = ($refParams->{values}) ? split(/,/, $refParams->{values}) : ();
        # Remove hyphens, if any.
        $_=~ s/'//g foreach @arrValues;
        $refParams->{type} = 'RefSeq,LibSeq' unless($refParams->{type});
        my %hmTypes = ();
        foreach my $strType (split(/,/, $refParams->{type}))
        {
            $strType = lc($strType);
            if($strType eq 'refseq')
            {
                $hmTypes{RefSeq}++;
            }
            elsif($strType eq 'libseq')
            {
                $hmTypes{LibSeq}++;
            }
            elsif($strType eq 'pfam')
            {
                $hmTypes{Pfam}++;
            }
            elsif($strType eq 'genbank')
            {
                $hmTypes{GenBank}++;
            }
            elsif($strType eq 'versions')
            {
                $hmTypes{Version}++;
            }
            elsif($strType eq 'paralogs')
            {
                $hmTypes{Paralog}++;
            }
            elsif($strType eq 'ish')
            {
                $hmTypes{'ISH probe'}++;
            }
            elsif($strType eq 'microarray')
            {
                $hmTypes{'MA probe'}++;
            }
            elsif($strType eq 'phylogeny')
            {
                $hmTypes{'Phylogeny'}++;
            }
            elsif($strType eq 'pacbio')
            {
                $hmTypes{$PACBIO_GENOMIC}++;
            }
        }
        my @arrTypes = keys(%hmTypes);
        $_ = "'$_'" foreach (@arrTypes);
        my $strTypes = join(',', @arrTypes);
        # Contig IDs.
        if((scalar @arrSeqIDs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $bGetAlignment = 0;
        foreach my $strValue (@arrValues)
        {
            my $strValue_lc = lc($strValue);
            if($strValue_lc eq 'alignment')
            {
                $bGetAlignment = 1;
            }
        }
        my $strQuery = "SELECT Homology.h_id, ".
                            "Homology.query_id, ".
                            "Homology.qst_id, ".
                            "Homology.hit_id, ".
                            "Homology.hst_id, ".
                            "Homology.accession, ".
                            "HomologType.name AS type, ".
                            "Algorithm.name AS algorithm ".
                       "FROM Homology ".   
                            "INNER JOIN Algorithm ON Homology.al_id=Algorithm.al_id ".
                            "INNER JOIN HomologType ON Homology.ht_id=HomologType.ht_id ".
                       "WHERE ((Homology.query_id=? AND qst_id=?) OR (Homology.hit_id=? AND Homology.hst_id=?)) ".
                            "AND HomologType.name IN ($strTypes)";
        my $stmtGetData = $self->{_db}->prepare($strQuery);
	
        $strQuery = "SELECT * from HSP WHERE h_id=?";
        my $stmtGetHSPs = $self->{_db}->prepare($strQuery);
	
        $strQuery = "SELECT RefSeq.seq_id AS hname,".
			   'RefSeq.gene_id, '.
                           'RefSeq.symbol, '.
                           'RefSeq.definition, '.
                           'RefSeqOrganism.name AS org, '.
                           'RefSeqOrganism.tax_id, '.
                           'RefSeqSource.name AS src '.
                    "FROM RefSeq ".
                         "INNER JOIN RefSeqOrganism ON RefSeq.rso_id=RefSeqOrganism.rso_id ".
                         "INNER JOIN RefSeqSource ON RefSeq.rss_id=RefSeqSource.rss_id ".
                    "WHERE RefSeq.rs_id=?";
        my $stmtSelectRefSeq = $self->{_db}->prepare($strQuery);
        
        $strQuery = "SELECT name AS hname, ".
                           "symbol, ".
                           "description ".
                    "FROM LibrarySequence ".
                         "LEFT JOIN LibraryAnnotation ON LibrarySequence.ls_id=LibraryAnnotation.ls_id ".
                    "WHERE LibrarySequence.ls_id=?";
        my $stmtSelectLibSeq = $self->{_db}->prepare($strQuery);
        
        $strQuery = "SELECT Contig.name AS hname, ".
                           "Annotation.symbol, ".
                           "Annotation.definition, ".
                           "Assembly.version ".
                    "FROM Contig ".
                         "LEFT  JOIN Annotation ON Contig.an_id=Annotation.an_id ".
                         "INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
                    "WHERE Contig.c_id=?";
        my $stmtSelectTranscript = $self->{_db}->prepare($strQuery);
	
        $strQuery = "SELECT ISHProbe.name AS hname, ".
                   "Author.name AS author ".
                "FROM ISHProbe ".
                     "INNER JOIN Author ON ISHProbe.au_id=Author.au_id ".
                "WHERE ISHProbe.ishp_id=?";
        my $stmtSelectISHProbe = $self->{_db}->prepare($strQuery);
        
        $strQuery = "SELECT MicroarrayProbe.name AS hname, ".
                           "Microarray.name AS ma ".
                "FROM MicroarrayProbe ".
                     "INNER JOIN Microarray ON MicroarrayProbe.ma_id=Microarray.ma_id ".
                "WHERE MicroarrayProbe.map_id=?";
        my $stmtSelectMAProbe = $self->{_db}->prepare($strQuery);
        
        $strQuery = "SELECT PhylogeneticSequence.name AS hname, ".
		           "PhylogeneticSequence.length AS len, ".
	                   "PhylogeneticSource.description AS src, ".
			   "PhylogeneticSource.organism AS organism, ".
			   "PhylogeneticSource.reference AS ref ".
		    "FROM PhylogeneticSequence ".
		         "INNER JOIN PhylogeneticSource ON PhylogeneticSequence.pgs_id=PhylogeneticSource.pgs_id ".
		    "WHERE PhylogeneticSequence.pgseq_id=?";
        my $stmtSelectPhylogeny = $self->{_db}->prepare($strQuery);
        
        my ($st_id_transcript) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
        my ($st_id_libseq) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='libseq'");
        foreach my $strSeqID (@arrSeqIDs)
        {
            my @arrAlnFiles = ();
            $strSeqID =~ s/'//g;
            # Determine the ID and the type of the sequences.
            my $st_id = $st_id_transcript;
            my $strSeqType = 'Transcript';
            my ($seq_id, $nLen, $iVersion) = $self->{_db}->selectrow_array("SELECT c_id, ".
                                                                                  "LENGTH(sequence), ".
								                  "Assembly.version ".
                                                                           "FROM Contig ".
								                "INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
                                                                           "WHERE Contig.name='$strSeqID'");
            if(!$seq_id)
            {
                $st_id = $st_id_libseq;
                $strSeqType = 'Library sequence';
                ($seq_id, $nLen) = $self->{_db}->selectrow_array("SELECT ls_id, ".
                                                                        "LENGTH(sequence) ".
                                                                 "FROM LibrarySequence ".
                                                                 "WHERE name='$strSeqID'");
            }
	    if(!$seq_id)
	    {
            # Check if the sequence ID is a PacBio read ID.
            my $strHash = Digest::MD5::md5_hex($strSeqID);
            my $strSubdir1 = substr($strHash, 0, 4);
            my $strSubdir2 = substr($strHash, 4, 4);
            opendir(DIR, "$self->{_external}/$PACBIO_GENOMIC");
            my @arrAssemblies = grep {/Am_/} readdir DIR;
            closedir(DIR);
            foreach my $strAssembly (@arrAssemblies)
            {
                my $strAlnFile = "$self->{_external}/$PACBIO_GENOMIC/$strAssembly/reads/$strSubdir1/$strSubdir2/$strSeqID/transcripts.aln";
                push(@arrAlnFiles, $strAlnFile) if(-e $strAlnFile);
            }
            if(scalar @arrAlnFiles)
            {
                $seq_id = -1;
                $strSeqType = 'PacBio';
            }
	    }
        next if(!$seq_id);
	    # Check if external homologous alignments (e.g. PacBio) are requested.
	    my @arrHomologs = ();
	    if((defined $hmTypes{$PACBIO_GENOMIC} && $iVersion) || $seq_id==-1)
	    {
            my @arrFiles = ($seq_id==-1) ? @arrAlnFiles
                                         : ("$self->{_external}/$PACBIO_GENOMIC/Am_$iVersion/transcripts/$strSeqID/reads.aln");
            foreach my $strFilename (@arrFiles)
            {
                if(-e $strFilename)
                {
                my @arrHits = @{Storable::retrieve($strFilename)};
                foreach my $refHit (@arrHits)
                {
                    my @arrHSPs = ();
                    foreach my $refHSP (@{$refHit->{_hsps}})
                    {
                    push(@arrHSPs, {evalue => $refHSP->{_evalue},
                            bitscore => $refHSP->{_score},
                            algorithm => 'blastn',
                            qframe => $refHSP->{_qframe},
                            qstart => $refHSP->{_qFrom},
                            query => $refHSP->{_alnQ},
                            hframe => $refHSP->{_hframe},
                            hstart => $refHSP->{_hFrom},
                            hit => $refHSP->{_alnH},
                            midline => $refHSP->{_alnM}});
                    }
                    push(@arrHomologs, {algorithm => 'blastn',
                            type => ($seq_id==-1) ? 'Transcript' : 'PacBio',
                            hname => $refHit->{_hit},
                            hsps => \@arrHSPs});
                    $nLen = $refHit->{_qlen};
                }
                }
            }
	    }
	    # Find all other requested alignments for the given sequence.
            $stmtGetData->execute($seq_id, $st_id, $seq_id, $st_id);
            my $refResult = $stmtGetData->fetchrow_hashref();
            next unless ($refResult || (scalar @arrHomologs));
            
            my $sequence = $xmldoc->createElement('sequence');
            $sequence->addChild($xmldoc->createAttribute(name => $strSeqID));
            $sequence->addChild($xmldoc->createAttribute(type => $strSeqType));
            $sequence->addChild($xmldoc->createAttribute(length => $nLen));

            while($refResult)
            {
                my $refAdditional = {};
                if($refResult->{type} eq 'RefSeq')
                {
                    $stmtSelectRefSeq->execute($refResult->{hit_id});
                    $refAdditional = $stmtSelectRefSeq->fetchrow_hashref();
                }
                elsif($refResult->{type} eq 'LibSeq')
                {
                    $stmtSelectLibSeq->execute($refResult->{hit_id});
                    $refAdditional = $stmtSelectLibSeq->fetchrow_hashref();
                }
                elsif(($refResult->{type} eq 'Version') || ($refResult->{type} eq 'Paralog'))
                {
                    $stmtSelectTranscript->execute($refResult->{hit_id});
                    $refAdditional = $stmtSelectTranscript->fetchrow_hashref();
                }
                elsif($refResult->{type} eq 'ISH probe')
                {
                    $stmtSelectISHProbe->execute($refResult->{hit_id});
                    $refAdditional = $stmtSelectISHProbe->fetchrow_hashref();
                }
                elsif($refResult->{type} eq 'MA probe')
                {
                    $stmtSelectMAProbe->execute($refResult->{hit_id});
                    $refAdditional = $stmtSelectMAProbe->fetchrow_hashref();
                }
                elsif($refResult->{type} eq 'Phylogeny')
                {
                    $stmtSelectPhylogeny->execute($refResult->{hit_id});
                    $refAdditional = $stmtSelectPhylogeny->fetchrow_hashref();
                }
                $refResult->{$_} = $refAdditional->{$_} foreach(keys %{$refAdditional});
                push(@arrHomologs, $refResult);
                $refResult = $stmtGetData->fetchrow_hashref();
            }
            
            foreach my $refHomolog (@arrHomologs)
            {
                my $homolog = $xmldoc->createElement('homolog');
                my $bInvertHSP = 0;
                if(($refHomolog->{hit_id} eq $seq_id))
                {
                    $stmtSelectTranscript->execute($refHomolog->{query_id});
                    my $refTmp = $stmtSelectTranscript->fetchrow_hashref();
                    $refHomolog->{$_} = $refTmp->{$_} foreach(keys %{$refTmp});
                    $refHomolog->{type} = 'Transcript';
                    $bInvertHSP = 1;
                }
                # General details.
                $homolog->addChild($xmldoc->createAttribute(type => $refHomolog->{type}));
                $homolog->addChild($xmldoc->createAttribute(name => $refHomolog->{hname}));
                $homolog->addChild($xmldoc->createAttribute(assembly => $refHomolog->{version})) if($refHomolog->{version});
                if($refHomolog->{src})
                {
                    $homolog->addChild($xmldoc->createAttribute(source => $refHomolog->{src}));
                    $homolog->addChild($xmldoc->createAttribute(organism => $refHomolog->{organism}));
                    $homolog->addChild($xmldoc->createAttribute(length => $refHomolog->{len}));
                    $homolog->addChild($xmldoc->createAttribute(reference => $refHomolog->{ref}));
                }
                if($refHomolog->{definition})
                {
                    my $annotation = $xmldoc->createElement('annotation');
                    $annotation->addChild($xmldoc->createAttribute(gene => $refHomolog->{gene_id})) if($refHomolog->{gene_id});
                    $annotation->addChild($xmldoc->createAttribute(symbol => $refHomolog->{symbol})) if($refHomolog->{symbol});
                    $annotation->addChild($xmldoc->createAttribute(organism => $refHomolog->{org})) if($refHomolog->{org});
                    $annotation->addChild($xmldoc->createTextNode($refHomolog->{definition}));
                    $homolog->addChild($annotation);
                }
                if($bGetAlignment)
                {
                    my $aln = $xmldoc->createElement('alignment');
                    my @arrHSPs = ();
                    if(!$refHomolog->{hsps})
                    {
                        $stmtGetHSPs->execute($refHomolog->{h_id});
                        next if($stmtGetHSPs->rows == 0);
                        while(my $refHSP = $stmtGetHSPs->fetchrow_hashref())
                        {
                            push(@arrHSPs, $refHSP);
                        }
                    }
                    else
                    {
                        @arrHSPs = @{$refHomolog->{hsps}};
                    }
        
                    foreach my $refHSP (@arrHSPs)
                    {
                        my $hsp = $xmldoc->createElement('hsp');
                        invertAlignment($refHSP, $refHomolog->{algorithm}) if($bInvertHSP);
                        $hsp->addChild($xmldoc->createAttribute(evalue => $refHSP->{evalue}));
                        $hsp->addChild($xmldoc->createAttribute(bitscore => $refHSP->{bitscore}));
                        $hsp->addChild($xmldoc->createAttribute(algorithm => $refHomolog->{algorithm}));
                        my $seq = $xmldoc->createElement('sequence');
                        $seq->addChild($xmldoc->createAttribute(frame => $refHSP->{qframe}));
                        $seq->addChild($xmldoc->createAttribute(start => $refHSP->{qstart}));
                        $seq->addChild($xmldoc->createTextNode($refHSP->{query}));
                        $hsp->addChild($seq);
                        my $hit = $xmldoc->createElement('hit');
                        $hit->addChild($xmldoc->createAttribute(frame => $refHSP->{hframe}));
                        $hit->addChild($xmldoc->createAttribute(start => $refHSP->{hstart}));
                        $hit->addChild($xmldoc->createTextNode($refHSP->{hit}));
                        $hsp->addChild($hit);
                        my $midline = $xmldoc->createElement('midline');
                        $midline->addChild($xmldoc->createTextNode($refHSP->{midline}));
                        $hsp->addChild($midline);
                        $aln->addChild($hsp);
                    }
                    $homolog->addChild($aln);
                }
                $sequence->addChild($homolog);
            }
            $xmldata->addChild($sequence);
        }
        return Constants::ERR_OK;
    }
    
    sub invertAlignment
    {
        my ($refHomolog, $strAlgorithm) = @_;
        if(($strAlgorithm eq 'blastn') && ($refHomolog->{hframe}==0))
        {
            $refHomolog->{midline} = reverse $refHomolog->{midline};
            $refHomolog->{query} = reverseComplement($refHomolog->{query});
            $refHomolog->{hit} = reverseComplement($refHomolog->{hit});
            
            #my $qs = $refHomolog->{qstart};
            #my $strTmp = $refHomolog->{query};
            #$strTmp =~ s/-//g;
            #my $qe = $qs + length($strTmp) - 1;
            #$refHomolog->{qstart} = $qe;
            
            #my $hs = $refHomolog->{hstart};
            #$strTmp = $refHomolog->{hit};
            #$strTmp =~ s/-//g;
            #my $he = $hs + length($strTmp) - 1;
            #$refHomolog->{hstart} = $he;
        }
        my $tmp = $refHomolog->{hframe};
        $refHomolog->{hframe} = $refHomolog->{qframe};
        $refHomolog->{qframe} = $tmp;
        $tmp = $refHomolog->{hstart};
        $refHomolog->{hstart} = $refHomolog->{qstart};
        $refHomolog->{qstart} = $tmp;
        $tmp = $refHomolog->{query};
        $refHomolog->{query} = $refHomolog->{hit};
        $refHomolog->{hit} = $tmp;
    }
    
    sub reverseComplement
    {
        my ($strSeq) = @_;
        my @arrBases = split(//, uc($strSeq));
        foreach (@arrBases)
        {
            if($_ eq 'A') {$_ = 'T'}
            elsif($_ eq 'C') {$_ = 'G'}
            elsif($_ eq 'G') {$_ = 'C'}
            elsif($_ eq 'T') {$_ = 'A'}
        }
        return reverse join('', @arrBases);
    }
}

1;