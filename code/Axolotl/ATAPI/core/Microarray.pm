#!/usr/bin/env perl

#   File:
#       Microarray.pm
#
#   Description:
#       Contains the Microarray core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.1.3
#
#   Date:
#       10.12.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;

use Axolotl::ATAPI::Constants;


package Microarray;
{
    my $MODULE = 'Microarray';
    my $VERSION = '1.2.2';
    my $DATE = '2014-09-18';
    
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
        return $MODULE;
    }
    
    sub getDescription 
    {
       return "Retrieves the microarray details.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
	my $strExampleProbe = 'CUST_10008_PI256121980';
        my $strExampleContig = 'NT_010000271051.1';
        my @arrMethods = ({_name => 'getMicroarraysList',
                           _description => 'Returns the list of available microarrays',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getMicroarraysList"},
                          
                          {_name => 'getMicroarrayDetails',
                           _description => 'Returns the details about the specified microarray',
                           _args => [{_name => 'names',
                                      _description => 'Comma-separated list of microarray names to retrieve details for',
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getMicroarrayDetails&names=Agilent_400K",
                           _remarks => "If no microarray names are specified the behavior is identical to that of $MODULE.getMicroarraysList"},
                          
                          {_name => 'getMicroarrayProbesList',
                           _description => 'Returns the list of available microarray probes for the specified contigs',
                           _args => [{_name => 'sequences',
                                      _description => 'Comma-separated list of contig or library sequence names to retrieve probes list for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence name is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getMicroarrayProbesList&sequences=$strExampleContig"},
                          
                          {_name => 'getMicroarrayProbeDetails',
                           _description => 'Returns the microarray probe details',
                           _args => [{_name => 'probes',
                                      _description => 'Comma-separated list of probe IDs to retrieve details for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no probe name is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getMicroarrayProbeDetails&probes=$strExampleProbe"},
                          
                          {_name => 'getMicroarrayProbeTargets',
                           _description => 'Returns the list of targets of the specified probes',
                           _args => [{_name => 'probes',
                                      _description => 'Comma-separated list of probe names to retrieve targets for',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'categories',
                                      _description => "Comma-separated list of categories to retrieve targets from. Can be combination of 'transcripts' and 'libraries'",
                                      _type => 'optional',
                                      _default => 'both, transcripts and libraries'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no probe name is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getMicroarrayProbeTargets&probes=$strExampleProbe"});
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
        if($strMethod eq 'getMicroarraysList')
        {
            return $self->getMicroarraysList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getMicroarrayDetails')
        {
            return $self->getMicroarrayDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getMicroarrayProbesList')
        {
            return $self->getMicroarrayProbesList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getMicroarrayProbeDetails')
        {
            return $self->getMicroarrayProbeDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getMicroarrayProbeTargets')
        {
            return $self->getMicroarrayProbeTargets($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    ################################################
    # Private module methods.
    ################################################
    sub getMicroarraysList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = "SELECT Microarray.name AS name, ".
                              "Microarray.probes AS probes, ".
                              "description, ".
                              "vendor, ".
                              "Author.name AS author, ".
                              "Author.email AS email ".
                       "FROM Microarray ".
                            "INNER JOIN Author ON Microarray.au_id=Author.au_id;";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $microarray = $xmldoc->createElement('microarray');
            $microarray->addChild($xmldoc->createAttribute(name => $refResult->{name}));
            $microarray->addChild($xmldoc->createAttribute(vendor => $refResult->{vendor}));
            $microarray->addChild($xmldoc->createAttribute(author => $refResult->{author}));
            $microarray->addChild($xmldoc->createAttribute(email => $refResult->{email}));
            $microarray->addChild($xmldoc->createAttribute(probes => $refResult->{probes}));
            $microarray->addChild($xmldoc->createTextNode($refResult->{description}));
            $xmldata->addChild($microarray);
        }
        return Constants::ERR_OK;
    }
    
    sub getMicroarrayDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{names})
        {
            return $self->getMicroarraysList($refParams, $xmldoc, $xmldata, $xmlerr);
        }
        my @tmp = ();
        foreach (split(/,/, $refParams->{names}))
        {
            $_ =~ s/'//g;
            push(@tmp, "'$_'");
        }
        my $strNames = join(',', @tmp);
        my $strQuery = "SELECT Microarray.name AS name, ".
                              "Microarray.probes AS probes, ".
                              "description, ".
                              "vendor, ".
                              "Author.name AS author, ".
                              "Author.email AS email ".
                       "FROM Microarray ".
                            "INNER JOIN Author ON Microarray.au_id=Author.au_id ".
                       "WHERE Microarray.name IN ($strNames)";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $microarray = $xmldoc->createElement('microarray');
            $microarray->addChild($xmldoc->createAttribute(name => $refResult->{name}));
            $microarray->addChild($xmldoc->createAttribute(vendor => $refResult->{vendor}));
            $microarray->addChild($xmldoc->createAttribute(author => $refResult->{author}));
            $microarray->addChild($xmldoc->createAttribute(email => $refResult->{email}));
            $microarray->addChild($xmldoc->createAttribute(probes => $refResult->{probes}));
            $microarray->addChild($xmldoc->createTextNode($refResult->{description}));
            $xmldata->addChild($microarray);
        }
        return Constants::ERR_OK;
    }
    
    sub getMicroarrayProbesList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqNames = (defined $refParams->{sequences}) ? split(/,/, $refParams->{sequences}) : ();
	$_=~ s/'/\\'/g foreach @arrSeqNames;
        if((scalar @arrSeqNames)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT MicroarrayProbe.name AS name, ".
                              "MicroarrayProbe.sequence AS seq, ".
			      "Microarray.name AS ma_name, ".
                              "MaPM.map_starts, ".
                              "MaPM.c_starts, ".
                              "MaPM.map_hsps, ".
                              "MaPM.c_hsps, ".
                              "MaPM.matches AS `matches`, ".
                              "MaPM.strand ".
                       "FROM MicroarrayProbe ".
                            "INNER JOIN (SELECT * FROM MicroarrayProbeMapping ".
		                        "WHERE seq_id = ? AND st_id = ?) AS MaPM ON MaPM.map_id=MicroarrayProbe.map_id ".
			    "INNER JOIN Microarray ON MicroarrayProbe.ma_id=Microarray.ma_id ".
		       "ORDER BY MicroarrayProbe.name, MicroarrayProbe.ma_id";
        my $statement = $self->{_db}->prepare($strQuery);
        foreach (@arrSeqNames)
        {
	    my ($seq_id) = $self->{_db}->selectrow_array("SELECT c_id FROM Contig WHERE name='$_'");
	    my $st_id = undef;
	    if($seq_id)
	    {
		($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
	    }
	    else
	    {
		($seq_id) = $self->{_db}->selectrow_array("SELECT ls_id FROM LibrarySequence WHERE name='$_'");
		($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='libseq'");
	    }
	    next if(!$seq_id || !$st_id);
            $statement->execute($seq_id, $st_id);
            my $entry = $xmldoc->createElement('sequence');
            $entry->addChild($xmldoc->createAttribute(name => $_));
            while(my $refResult = $statement->fetchrow_hashref())
            {
                my $probe = $xmldoc->createElement('probe');
                $probe->addChild($xmldoc->createAttribute(name => $refResult->{name}));
                $probe->addChild($xmldoc->createAttribute(matches => $refResult->{matches}));
		$probe->addChild($xmldoc->createAttribute(microarray => $refResult->{ma_name}));
                my $hsps = $xmldoc->createElement('hsps');
                my @arrMapStarts = split(/,/, $refResult->{map_starts});
                my @arrCStarts = split(/,/, $refResult->{c_starts});
                my @arrMapHsps = split(/,/, $refResult->{map_hsps});
                my @arrCHsps = split(/,/, $refResult->{c_hsps});
                my $nHsps = scalar @arrMapStarts;
                for(my $i=0;$i<$nHsps;$i++)
                {
                    my $hsp = $xmldoc->createElement('hsp');
                    my $c_hsp = $xmldoc->createElement('contig');
                    $c_hsp->addChild($xmldoc->createAttribute(start => $arrCStarts[$i]));
                    $c_hsp->addChild($xmldoc->createAttribute(strand => $refResult->{strand}));
                    $c_hsp->addChild($xmldoc->createTextNode($arrCHsps[$i]));
                    $hsp->addChild($c_hsp);
                    my $map_hsp = $xmldoc->createElement('probe');
                    $map_hsp->addChild($xmldoc->createAttribute(start => $arrMapStarts[$i]));
                    $map_hsp->addChild($xmldoc->createTextNode($arrMapHsps[$i]));
                    $hsp->addChild($map_hsp);
                    $probe->addChild($hsp);
                }
                $entry->addChild($probe);
            }
            $xmldata->addChild($entry);
        }
        return Constants::ERR_OK;
    }
    
    sub getMicroarrayProbeDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrProbes = (defined $refParams->{probes}) ? split(/,/, $refParams->{probes}) : ();
        if((scalar @arrProbes)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No probe name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT sequence, ".
                              "strand, ".
                              "Tm, ".
                              "gc, ".
                              "Microarray.name AS microarray ".
                       "FROM MicroarrayProbe ".
                            "INNER JOIN Microarray ON MicroarrayProbe.ma_id=Microarray.ma_id ".
                       "WHERE MicroarrayProbe.name=?";
        my $statement = $self->{_db}->prepare($strQuery);
        foreach my $strProbeID (@arrProbes)
        {
            $statement->execute($strProbeID);
            my $refResult = $statement->fetchrow_hashref();
            if($refResult)
            {
                my $probe = $xmldoc->createElement('probe');
                $probe->addChild($xmldoc->createAttribute(name => $strProbeID));
                $probe->addChild($xmldoc->createAttribute(strand => $refResult->{strand}));
                $probe->addChild($xmldoc->createAttribute(Tm => $refResult->{Tm}));
                $probe->addChild($xmldoc->createAttribute(GC => $refResult->{gc}));
                $probe->addChild($xmldoc->createAttribute(microarray => $refResult->{microarray}));
                $probe->addChild($xmldoc->createTextNode($refResult->{sequence}));
                $xmldata->addChild($probe);
            }
        }
        return Constants::ERR_OK;
    }
    
    sub getMicroarrayProbeTargets
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrProbes = (defined $refParams->{probes}) ? split(/,/, $refParams->{probes}) : ();
        if((scalar @arrProbes)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No probe name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my %hmCategories = ();
        foreach my $strCategory (split(/,/, $refParams->{categories}))
        {
            $strCategory = lc($strCategory);
            if(($strCategory eq 'transcripts') || ($strCategory eq 'libraries'))
            {
                $hmCategories{$strCategory} = 1;
            }
        }
        my @arrCategories = (%hmCategories) ? (keys %hmCategories) : ('transcripts','libraries');
        my $strQuery = "SELECT Contig.name, ".
                               "MicroarrayProbeMapping.matches, ".
                               "Annotation.definition AS definition ,".
			       "MicroarrayProbeMapping.map_starts, ".
                               "MicroarrayProbeMapping.c_starts, ".
                               "MicroarrayProbeMapping.map_hsps, ".
			       "MicroarrayProbeMapping.strand, ".
                               "MicroarrayProbeMapping.c_hsps ".
                       "FROM Contig ".
                            "INNER JOIN MicroarrayProbeMapping ON Contig.c_id=MicroarrayProbeMapping.seq_id ".
                            "INNER JOIN MicroarrayProbe ON MicroarrayProbeMapping.map_id=MicroarrayProbe.map_id ".
			    "INNER JOIN SequenceType ON MicroarrayProbeMapping.st_id=SequenceType.st_id ".
			    "INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
                            "LEFT JOIN Annotation ON Contig.an_id=Annotation.an_id ".
                       "WHERE MicroarrayProbe.map_id = ? AND SequenceType.name = 'transcript' ".
                       "ORDER BY MicroarrayProbeMapping.matches DESC, Assembly.version DESC";
        my $stmt_findTranscript = $self->{_db}->prepare($strQuery);
        $strQuery = "SELECT LibrarySequence.name, ".
                           "MicroarrayProbeMapping.matches, ".
                           "LibraryAnnotation.description AS definition, ".
			   "MicroarrayProbeMapping.map_starts, ".
                           "MicroarrayProbeMapping.c_starts, ".
                           "MicroarrayProbeMapping.map_hsps, ".
			   "MicroarrayProbeMapping.strand, ".
                           "MicroarrayProbeMapping.c_hsps ".
                       "FROM LibrarySequence ".
                            "INNER JOIN MicroarrayProbeMapping ON LibrarySequence.ls_id=MicroarrayProbeMapping.seq_id ".
                            "INNER JOIN MicroarrayProbe ON MicroarrayProbeMapping.map_id=MicroarrayProbe.map_id ".
			    "INNER JOIN SequenceType ON MicroarrayProbeMapping.st_id=SequenceType.st_id ".
                            "INNER JOIN Library ON LibrarySequence.lib_id=Library.lib_id ".
			    "LEFT  JOIN LibraryAnnotation ON LibrarySequence.ls_id=LibraryAnnotation.ls_id ".
                       "WHERE MicroarrayProbe.map_id = ? AND SequenceType.name = 'libseq'".
                       "ORDER BY MicroarrayProbeMapping.matches DESC, LibrarySequence.name";
        my $stmt_findLibSeq = $self->{_db}->prepare($strQuery);
        foreach my $strProbe (@arrProbes)
        {
            my ($map_id) = $self->{_db}->selectrow_array("SELECT map_id FROM MicroarrayProbe WHERE name='$strProbe'");
            next if(!$map_id);
            my $probe = $xmldoc->createElement('probe');
            $probe->addChild($xmldoc->createAttribute(name => $strProbe));
            foreach my $strCategory (@arrCategories)
            {
                my $category = $xmldoc->createElement('category');
                my $stmt = undef;
                if($strCategory eq 'transcripts')
                {
                    $category->addChild($xmldoc->createAttribute(type => 'transcripts'));
                    $stmt = $stmt_findTranscript;
                }
                else
                {
                    $category->addChild($xmldoc->createAttribute(type => 'libraries'));
                    $stmt = $stmt_findLibSeq;
                }
                $stmt->execute($map_id);
                next if($stmt->rows==0);
                while(my $refResult = $stmt->fetchrow_hashref())
                {
                    my $target = $xmldoc->createElement('target');
                    $target->addChild($xmldoc->createAttribute(name => $refResult->{name}));
                    $target->addChild($xmldoc->createAttribute(matches => $refResult->{matches}));
                    $target->addChild($xmldoc->createTextNode($refResult->{definition}));
		    my $hsps = $xmldoc->createElement('hsps');
		    my @arrMapStarts = split(/,/, $refResult->{map_starts});
		    my @arrTStarts = split(/,/, $refResult->{c_starts});
		    my @arrMapHsps = split(/,/, $refResult->{map_hsps});
		    my @arrTHsps = split(/,/, $refResult->{c_hsps});
		    my $nHsps = scalar @arrMapStarts;
		    for(my $i=0;$i<$nHsps;$i++)
		    {
			my $hsp = $xmldoc->createElement('hsp');
			my $t_hsp = $xmldoc->createElement('target');
			$t_hsp->addChild($xmldoc->createAttribute(start => $arrTStarts[$i]));
			$t_hsp->addChild($xmldoc->createAttribute(strand => $refResult->{strand}));
			$t_hsp->addChild($xmldoc->createTextNode($arrTHsps[$i]));
			$hsp->addChild($t_hsp);
			my $map_hsp = $xmldoc->createElement('probe');
			$map_hsp->addChild($xmldoc->createAttribute(start => $arrMapStarts[$i]));
			$map_hsp->addChild($xmldoc->createTextNode($arrMapHsps[$i]));
			$hsp->addChild($map_hsp);
			$target->addChild($hsp);
		    }
		    $category->addChild($target);
                }
                $probe->addChild($category);
            }
            $xmldata->addChild($probe);
        }
        return Constants::ERR_OK;
    }
}

1;
