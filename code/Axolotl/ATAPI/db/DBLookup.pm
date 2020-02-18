#!/usr/bin/env perl

#   File:
#       DBLookup.pm
#
#   Description:
#       Contains the DBLookup database module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       02.12.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use LWP::Simple;
use Axolotl::ATAPI::Constants;


package DBLookup;
{
    my $MODULE = 'DBLookup';
    my $VERSION = '1.0.1';
    my $DATE = '2014-12-02';
    
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
       return "Retrieves the sequence information from different sources based on the sequence ID";
    }
     
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
     
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'fetchSequences',
                           _description => 'Retrieves the sequence specified by the ID(s)',
			   _args => [{_name => 'seqIDs',
                                      _description => 'Comma-separated list of IDs (transcript, library sequence, Entrez, Ensembl or UniProt)',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.fetchSequences&sequences=NP_000724.1"});
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
	if($strMethod eq 'fetchSequences')
        {
            return $self->fetchSequences($refMethodParams, $xmldoc, $xmldata, $xmlerr, 'category');
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub fetchSequences
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr, $strType) = @_;
	if(!$refParams->{seqIDs})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my @arrSeqIDs = split(/,/, $refParams->{seqIDs});
	my @arrMethods = (\&databaseLookup,
			  \&ncbiLookup,
			  \&ensemblLookup,
			  \&uniprotLookup);
	foreach my $strSeqID (@arrSeqIDs)
	{
	    $strSeqID =~ s/'//g;
	    $strSeqID =~ s/^\s+//g;
	    $strSeqID =~ s/\s+$//g;
	    my $sequence = $xmldoc->createElement('sequence');
	    $sequence->addChild($xmldoc->createAttribute(id => $strSeqID));
	    foreach my $pfn (@arrMethods)
	    {
		my $refResult = $pfn->($self, $strSeqID);
		if($refResult)
		{
		    $sequence->addChild($xmldoc->createAttribute(source => $refResult->{source}));
		    $sequence->addChild($xmldoc->createAttribute(type => $refResult->{type}));
		    $sequence->addChild($xmldoc->createTextNode($refResult->{sequence}));
		    if($refResult->{annotation})
		    {
			my $annotation = $xmldoc->createElement('annotation');
			if($refResult->{symbol} && ($refResult->{symbol} ne 'N/A'))
			{
			    $annotation->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
			}
			$annotation->addChild($xmldoc->createTextNode($refResult->{annotation}));
			$sequence->addChild($annotation);
		    }
		    $xmldata->addChild($sequence);
		    last;
		}
	    }
	}
        return Constants::ERR_OK;
    }
    
    sub databaseLookup
    {
	my ($self, $strSeqID) = @_;
	my $strQuery = "SELECT sequence, definition, symbol ".
		       "FROM Contig ".
			    "LEFT JOIN Annotation ON Contig.an_id=Annotation.an_id ".
		       "WHERE name='$strSeqID'";
	my ($strSeq, $strDefinition, $strSymbol) = $self->{_db}->selectrow_array($strQuery);
	if($strSeq)
	{
	    return {sequence => $strSeq,
		    annotation => $strDefinition,
		    symbol => $strSymbol,
		    source => 'transcript',
		    type => 'dna'};
	}
	$strQuery = "SELECT sequence, description, symbol ".
		    "FROM LibrarySequence ".
			 "LEFT JOIN LibraryAnnotation ON LibrarySequence.ls_id=LibraryAnnotation.ls_id ".
		    "WHERE name='$strSeqID'";
	($strSeq, $strDefinition, $strSymbol) = $self->{_db}->selectrow_array($strQuery);
	if($strSeq)
	{
	    return {sequence => $strSeq,
		    annotation => $strDefinition,
		    symbol => $strSymbol,
		    source => 'library sequence',
		    type => 'dna'};
	}
	return undef;
    }
    
    sub ncbiLookup
    {
	my ($self, $strSeqID) = @_;
	my $strSeq = undef;
	my $strType = undef;
	my $strDesc = undef;
	my $strCMD = "wget -q -O - 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&id=$strSeqID&rettype=fasta'";
	my @arrLines = ();
	my $strHeader = undef;
	open(CMD, "$strCMD |");
	while(<CMD>)
	{
	    chomp();
	    if($strHeader)
	    {
		push(@arrLines, $_);
	    }
	    else
	    {
		$strHeader = $_;
	    }
	}
	close(CMD);
	if($strHeader)
	{
	    my @arrChunks = split(/\|/, $strHeader);
	    $strDesc = $arrChunks[4];
	    $strDesc =~ s/^\s*//g;
	    $strDesc =~ s/\s*$//g;
	    $strSeq = join('', @arrLines);
	    if($strSeq =~ m/^[ACGTNacgtn]+$/)
	    {
		$strType = 'dna';
	    }
	    else
	    {
		$strType = 'protein';
	    }
	    return {sequence => $strSeq,
		    annotation => $strDesc,
		    source => 'NCBI',
		    type => $strType};
	}
	return undef;
    }
    
    sub uniprotLookup
    {
	my ($self, $strSeqID) = @_;
	my $strCMD = "wget -q -O - http://www.uniprot.org/uniprot/$strSeqID.fasta";
	my @arrLines = ();
	my $strHeader = undef;
	open(CMD, "$strCMD |");
	while(<CMD>)
	{
	    chomp();
	    if($strHeader)
	    {
		push(@arrLines, $_);
	    }
	    else
	    {
		$strHeader = $_;
	    }
	}
	close(CMD);
	if($strHeader)
	{
	    my @arrChunks = split(/\|/, $strHeader);
	    my $strDesc = $arrChunks[2];
	    $strDesc =~ s/^\s*//g;
	    $strDesc =~ s/\s*$//g;
	    my $strSeq = join('', @arrLines);
	    return {sequence => $strSeq,
		    annotation => $strDesc,
		    source => 'UniProt',
		    type => 'protein'};
	}
	return undef;
    }
    
    sub ensemblLookup
    {
	my ($self, $strSeqID) = @_;
	my $strCMD = "wget -q -O - 'http://rest.ensembl.org/sequence/id/$strSeqID'";
	open(CMD, "$strCMD |");
	my $strSeq = undef;
	my $strType = 'unknown';
	while(<CMD>)
	{
	    chomp();
	    if($_ =~ m/\s*seq:\s+([A-Za-z]+)$/)
	    {
		$strSeq = $1;
	    }
	    elsif($_ =~ m/\s*molecule:\s+([A-Za-z]+)$/)
	    {
		$strType = $1;
	    }
	}
	close(CMD);
	if($strSeq)
	{
	    return {sequence => $strSeq,
		    source => 'Ensembl',
		    type => $strType};
	}
	return undef;
    }
}

1;