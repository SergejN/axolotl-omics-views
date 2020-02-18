#!/usr/bin/env perl

#   File:
#       Chimeras.pm
#
#   Description:
#       Contains the Chimeras advanced module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       13.01.2015
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Chimeras;
{
    my $MODULE = 'Chimeras';
    my $VERSION = '1.0.1';
    my $DATE = '2015-13-01';
    
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
       return "Retrieves the chimera information for the contigs";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
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
        if($strMethod eq 'listRegions')
        {
            return $self->listRegions($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub listRegions
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqIDs = (defined $refParams->{sequences}) ? split(/,/, $refParams->{sequences}) : ();
        if((scalar @arrSeqIDs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my $strQuery = "SELECT Chimera.*, ".
	                      "LENGTH(Contig.sequence) AS length ".
	               "FROM Chimera ".
		            "INNER JOIN Contig ON Chimera.c_id=Contig.c_id ".
		       "WHERE Contig.name=?";
	my $stmtSelect = $self->{_db}->prepare($strQuery);
	foreach my $strSeqID (@arrSeqIDs)
	{
	    $stmtSelect->execute($strSeqID);
	    next unless($stmtSelect->rows);
	    my $sequence = $xmldoc->createElement('sequence');
            $sequence->addChild($xmldoc->createAttribute('name' => $strSeqID));
	    my $refResult = $stmtSelect->fetchrow_hashref();
	    $sequence->addChild($xmldoc->createAttribute('length' => $refResult->{length}));
	    while($refResult)
	    {
		my $homolog = $xmldoc->createElement('homolog');
		$homolog->addChild($xmldoc->createAttribute(name => $refResult->{refseq_id}));
		$homolog->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
		$homolog->addChild($xmldoc->createAttribute(organism => $refResult->{organism}));
		$homolog->addChild($xmldoc->createTextNode($refResult->{definition}));
		
		my $alignment = $xmldoc->createElement('alignment');
		
		my $hsp = $xmldoc->createElement('hsp');
		$hsp->addChild($xmldoc->createAttribute(score => $refResult->{bitscore}));
		$hsp->addChild($xmldoc->createAttribute(evalue => $refResult->{evalue}));
		$hsp->addChild($xmldoc->createTextNode($refResult->{midline}));
		
		my $q_aln = $xmldoc->createElement('query');
		my $iQStart = $refResult->{qstart};
		my $iFrame = $refResult->{qframe};
		$iQStart = $iFrame+$iQStart*3;
		
		$q_aln->addChild($xmldoc->createAttribute(frame => $refResult->{qframe}));
		$q_aln->addChild($xmldoc->createAttribute(start => $iQStart));
		$q_aln->addChild($xmldoc->createTextNode($refResult->{query}));
		$hsp->addChild($q_aln);
		
		my $h_aln = $xmldoc->createElement('hit');
		$h_aln->addChild($xmldoc->createAttribute(frame => $refResult->{hframe}));
		$h_aln->addChild($xmldoc->createAttribute(start => $refResult->{hstart}));
		$h_aln->addChild($xmldoc->createTextNode($refResult->{hit}));
		$hsp->addChild($h_aln);
		
		$alignment->addChild($hsp);
		$homolog->addChild($alignment);
		$sequence->addChild($homolog);
		$refResult = $stmtSelect->fetchrow_hashref();
	    }
	    $xmldata->addChild($sequence);
	}
	return Constants::ERR_OK;
    }

}

1;  