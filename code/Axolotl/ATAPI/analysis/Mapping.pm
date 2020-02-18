#!/usr/bin/env perl

#   File:
#       Mapping.pm
#
#   Description:
#       Contains the Mapping analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.12
#
#   Date:
#       16.01.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use File::Temp;

use Axolotl::ATAPI::Constants;


package Mapping;
{
    my $MODULE = 'Mapping';
    my $VERSION = '1.0.14';
    my $DATE = '2013-11-22';
    
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
	$self->{_bamroot} = $ps->getSetting('MAPPING', 'BAMroot');
	$self->{_samtools} = $ps->getSetting('MAPPING', 'SAMtools');
	$self->{_bedtools} = $ps->getSetting('MAPPING', 'BEDtools');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the data related to mapping of the individual reads to the contigs.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
	my $strExampleContig = 'NT_010001269873.2';
        my @arrMethods = ({_name => 'getDatasetsList',
                           _description => 'Returns the list datasets with the mapping data for the specified sequences',
			   _args => [{_name => 'sequences',
                                      _description => 'Comma-separated list of sequence names to retrieve datasets lists for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence name specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getDatasetsList&sequences=$strExampleContig"},
			  
			  {_name => 'getCoverageData',
                           _description => 'Returns the coverage data as an array of coverage depth at each position in the contig',
			   _args => [{_name => 'sequence',
                                      _description => 'Name of the sequence to retrieve coverage data for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'dataset',
                                      _description => 'Name of the dataset to retrieve coverage for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If either sequence name or dataset name is not specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no mapping data are available for specified sequence and dataset'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getCoverageData&sequence=$strExampleContig&dataset=mSC"},

			  {_name => 'getSAMFile',
                           _description => 'Returns the SAM file for the contig and dataset pair',
			   _args => [{_name => 'contig',
                                      _description => 'Name of the contig to retrieve coverage for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'dataset',
                                      _description => 'Name of the dataset to retrieve coverage for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If either contig ID or dataset name is not specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no mapping data are available for specified contig and dataset'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getSAMFile&contig=$strExampleContig&dataset=mSC"});
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
        if($strMethod eq 'getDatasetsList')
        {
            return $self->getDatasetsList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getCoverageData')
        {
            return $self->getCoverageData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getSAMFile')
        {
            return $self->getSAMFile($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
    
    sub getDatasetsList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqs = (defined $refParams->{sequences}) ? split(/,/, $refParams->{sequences}) : ();
        if((scalar @arrSeqs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$_=~ s/'/\\'/g foreach @arrSeqs;
	my $strQuery = "SELECT Dataset.name AS dsname, ".
	                      "Dataset.description AS description, ".
			      "Dataset.sortindex AS sortindex, ".
			      "Dataset.paired AS paired, ".
			      "CoverageData.fpkm AS fpkm, ".
			      "LENGTH(Contig.sequence) AS length, ".
			      "Assembly.version AS version, ".
			      "Tissue.description AS tname, ".
			      "Experiment.name AS ename ".
		       "FROM CoverageData ".
		            "INNER JOIN Dataset ON CoverageData.ds_id=Dataset.ds_id ".
			    "INNER JOIN Contig ON CoverageData.seq_id=Contig.c_id ".
			    "INNER JOIN Tissue ON Dataset.t_id=Tissue.t_id ".
			    "INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
			    "INNER JOIN Experiment ON Dataset.exp_id=Experiment.exp_id ".
		       "WHERE CoverageData.seq_id=? AND CoverageData.st_id=?";
        my $stmtTranscript = $self->{_db}->prepare($strQuery);
	$strQuery = "SELECT Dataset.name AS dsname, ".
	                   "Dataset.description AS description, ".
			   "Dataset.sortindex AS sortindex, ".
			   "Dataset.paired AS paired, ".
			   "CoverageData.fpkm AS fpkm, ".
			   "LENGTH(LibrarySequence.sequence) AS length, ".
			   "Tissue.description AS tname, ".
			   "Experiment.name AS ename ".
		       "FROM CoverageData ".
		            "INNER JOIN Dataset ON CoverageData.ds_id=Dataset.ds_id ".
			    "INNER JOIN LibrarySequence ON CoverageData.seq_id=LibrarySequence.ls_id ".
			    "INNER JOIN Tissue ON Dataset.t_id=Tissue.t_id ".
			    "INNER JOIN Experiment ON Dataset.exp_id=Experiment.exp_id ".
		       "WHERE CoverageData.seq_id=? AND CoverageData.st_id=?";
        my $stmtLibSeq = $self->{_db}->prepare($strQuery);
        foreach my $strSeqName (@arrSeqs)
        {
	    my $stmt = undef;
	    my ($seq_id) = $self->{_db}->selectrow_array("SELECT c_id FROM Contig WHERE name='$strSeqName'");
	    my $st_id = undef;
	    if($seq_id)
	    {
		($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
		$stmt = $stmtTranscript;
	    }
	    else
	    {
		($seq_id) = $self->{_db}->selectrow_array("SELECT ls_id FROM LibrarySequence WHERE name='$strSeqName'");
		($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='libseq'");
		$stmt = $stmtLibSeq;
	    }
	    next if(!$seq_id || !$st_id);
            $stmt->execute($seq_id, $st_id);
            my $refResult = $stmt->fetchrow_hashref();
            next if !$refResult;
            my $sequence = $xmldoc->createElement('sequence');
            $sequence->addChild($xmldoc->createAttribute(name => $strSeqName));
            $sequence->addChild($xmldoc->createAttribute(length => $refResult->{length}));
	    $sequence->addChild($xmldoc->createAttribute(assembly => $refResult->{version}));
            while($refResult)
            {
                $refResult->{type} = ($refResult->{paired}==0) ? 'single-end' : 'paired-end';
                my $dataset = $xmldoc->createElement('dataset');
                $dataset->addChild($xmldoc->createAttribute(name => $refResult->{dsname}));
                $dataset->addChild($xmldoc->createAttribute(sortindex => $refResult->{sortindex}));
                $dataset->addChild($xmldoc->createAttribute(type => $refResult->{type}));
                $dataset->addChild($xmldoc->createAttribute(fpkm => $refResult->{fpkm}));
                $dataset->addChild($xmldoc->createAttribute(tissue => $refResult->{tname}));
                $dataset->addChild($xmldoc->createAttribute(experiment => $refResult->{ename}));
                $dataset->addChild($xmldoc->createTextNode($refResult->{description}));
                $sequence->addChild($dataset);
                $refResult = $stmt->fetchrow_hashref();
            }
            $xmldata->addChild($sequence);
        }
        return Constants::ERR_OK;
    }
    
    sub getCoverageData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        # Contig.
        if(!$refParams->{sequence})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{sequence} =~ s/'/\\'/g;
        # Dataset.
        if(!$refParams->{dataset})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No dataset name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{dataset} =~ s/'/\\'/g;
	my ($version, $nLen) = $self->{_db}->selectrow_array("SELECT version, LENGTH(Contig.sequence) AS len ".
						             "FROM Contig INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
						             "WHERE Contig.name='$refParams->{sequence}'");
	my $strBAMdir = undef;
	if($version)
	{
	    $strBAMdir = "$self->{_bamroot}/assemblies/Am_$version";
	}
	else
	{
	    ($nLen) = $self->{_db}->selectrow_array("SELECT LENGTH(LibrarySequence.sequence) AS len ".
						    "FROM LibrarySequence ".
						    "WHERE LibrarySequence.name='$refParams->{sequence}'");
	    $version = 'lib';
	    $strBAMdir = "$self->{_bamroot}/libraries";
	}
	if(!$nLen)
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No mapping data are available for the specified sequence and dataset"));
            return Constants::ERR_DATA_NOT_FOUND;
	}
	# Use SAMtools to calculate the coverage for each position of the contig.
        my $strSAMtools = $self->{_samtools};
        my $strBEDtools = $self->{_bedtools};
        my $strBAMfile = "$strBAMdir/$refParams->{dataset}/" . $version . '_' . $refParams->{dataset} . '.transcripts.bam';
        my $strCmd = "$strSAMtools view -b $strBAMfile $refParams->{sequence} |  $strBEDtools -d -ibam stdin | cut -f3";
        my @arrData = ();
        open(OUT, "$strCmd |");
        while(<OUT>)
        {
            chomp();
            push(@arrData, $_);
        }
        close(OUT);
	if((scalar @arrData)==0)
	{
	    @arrData = (0)x$nLen;
	}
        # Return the content.
        my $sequence = $xmldoc->createElement('sequence');
        $sequence->addChild($xmldoc->createAttribute(name => $refParams->{sequence}));
        $sequence->addChild($xmldoc->createAttribute(dataset => $refParams->{dataset}));
        $sequence->addChild($xmldoc->createAttribute(length => $nLen));
	$sequence->addChild($xmldoc->createAttribute(assembly => $version)) if($version ne 'lib');
        $sequence->addChild($xmldoc->createTextNode(join(' ', @arrData)));
        $xmldata->addChild($sequence);
        return Constants::ERR_OK;
    }
    
    # Returns the SAM file containing the reads mapping for the requested contig and dataset.
    #   Required parameters:
    #       - contig                contig name
    #       - dataset               dataset name
    sub getSAMFile
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        # Contig.
        if(!$refParams->{contig})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{contig} =~ s/'/\\'/g;
        # Dataset.
        if(!$refParams->{dataset})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No dataset name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{dataset} =~ s/'/\\'/g;
	# First, check if the dataset was mapped to the assembly of the contig.
	my $strQuery = "SELECT COUNT(*) AS count, ".
			      "version " .
		       "FROM Coverage ".
			    "INNER JOIN Assembly ON Assembly.a_id=Coverage.a_id " .
		       "WHERE Assembly.a_id=(SELECT a_id FROM Contig WHERE name='$refParams->{contig}') ".
		             "AND ds_id=(SELECT ds_id FROM Dataset WHERE name='$refParams->{dataset}')";
	my ($nCount, $version) = $self->{_db}->selectrow_array($strQuery);
        if($nCount==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No mapping data is available for specified contig and dataset"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strSAMtools = $self->{_samtools};
        my $strBAMfile = "$self->{_bamroot}/Am_$version/$refParams->{dataset}/" . $version . '_' . $refParams->{dataset} . '.bam';
        my $strSAMfile = $refParams->{contig} . '_' . $refParams->{dataset} . '_Am_' . $version . '.sam';
        my $strCmd = "$strSAMtools view $strBAMfile $refParams->{contig}";
        print "Content-disposition:attachment;filename=$strSAMfile;";
        print "Content-type:application/octet-stream\n\n";
        open(OUT, "$strCmd |");
        print $_ while(<OUT>);
        close(OUT);
        return Constants::ERR_OK_BINARY;
    }
}

1;
