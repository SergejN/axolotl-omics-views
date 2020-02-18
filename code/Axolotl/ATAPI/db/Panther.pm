#!/usr/bin/env perl

#   File:
#       Panther.pm
#
#   Description:
#       Contains the Panther database module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       16.05.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use LWP::Simple;
use Axolotl::ATAPI::Constants;


package Panther;
{
    my $MODULE = 'Panther';
    my $VERSION = '1.0.1';
    my $DATE = '2014-05-16';
    
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
       return "Retrieves the details about the contig from the Panther database.";
    }
     
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
       
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
	my $strSampleID = 'NT_02200031423.1';
        my @arrMethods = ({_name => 'listGOterms',
                           _description => 'Retrieves the list of GO terms for the specified contigs',
			   _args => [{_name => 'contigs',
                                      _description => 'Comma-separated list of contig IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listGOterms&contigs=$strSampleID",
			   _remarks => "If the contig exists, but either has no homologs or the best homolog is missing the ENSEMBLE ID then the contig entry exists but is empty."},
			  
			  {_name => 'listPathways',
                           _description => 'Retrieves the list of pathways for the specified contigs',
			   _args => [{_name => 'contigs',
                                      _description => 'Comma-separated list of contig IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listPathways&contigs=$strSampleID",
			   _remarks => "If the contig exists, but either has no homologs or the best homolog is missing the ENSEMBLE ID then the contig entry exists but is empty."});
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
	if($strMethod eq 'listGOterms')
        {
            return $self->fetchData($refMethodParams, $xmldoc, $xmldata, $xmlerr, 'category');
        }
	if($strMethod eq 'listPathways')
        {
            return $self->fetchData($refMethodParams, $xmldoc, $xmldata, $xmlerr, 'pathway');
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub fetchData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr, $strType) = @_;
	if(!$refParams->{contigs})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my @arrContigs = split(/,/, $refParams->{contigs});
	my $strQuery = "SELECT Synonym.name AS ens_id, ".
			      "RefSeq.seq_id AS seq_id, ".
			      "Homology.evalue AS evalue, ".
			      "Homology.bitscore AS bitscore ".
		       "FROM RefSeq ".
		            "INNER JOIN Synonym ON RefSeq.rs_id=Synonym.rs_id ".
			    "INNER JOIN SynonymType ON Synonym.snt_id=SynonymType.snt_id ".
			    "INNER JOIN Homology ON RefSeq.rs_id=Homology.rs_id ".
			    "INNER JOIN SequenceType ON Homology.st_id=SequenceType.st_id ".
                       "WHERE Homology.seq_id=? AND SequenceType.name='transcript' AND SynonymType.name='ensembl'";
	my $statement = $self->{_db}->prepare($strQuery);
	foreach my $strContigID (@arrContigs)
	{
	    $strContigID =~ s/'//g;
	    # First, determine c_id of the contig.
            $strQuery = "SELECT c_id FROM Contig WHERE name='$strContigID';";
            my $refResult = $self->{_db}->selectrow_hashref($strQuery);
            next unless $refResult;
	    my $c_id = $refResult->{c_id};
	    $statement->execute($c_id);
	    my $refBestHomolog = undef;
	    while($refResult = $statement->fetchrow_hashref())
	    {
		if(!$refBestHomolog || ($refResult->{evalue}<=$refBestHomolog->{evalue} && $refResult->{bitscore}>$refBestHomolog->{bitscore}))
                {
                    $refBestHomolog = $refResult;
                }
	    }
	    my $contig = $xmldoc->createElement('contig');
	    $contig->addChild($xmldoc->createAttribute(name => $strContigID));
	    if($refBestHomolog)
	    {
		my $bestHomolog = $xmldoc->createElement('homolog');
		$bestHomolog->addChild($xmldoc->createAttribute(refseq_id => $refBestHomolog->{seq_id}));
		$bestHomolog->addChild($xmldoc->createAttribute(ens_id => $refBestHomolog->{ens_id}));
		my $strURL = "http://www.pantherdb.org/webservices/garuda/search.jsp?keyword=$refBestHomolog->{ens_id}&listType=$strType&type=getList";
		my $strResponse = LWP::Simple::get $strURL;
		my @arrEntries = split(/\n/, $strResponse);
		my $nEntries = 0;
		if($strType eq 'category')
		{
		    $strQuery = "SELECT name, definition, comment FROM GO WHERE go_id=?";
		    my $statementSelect = $self->{_db}->prepare($strQuery);
		    foreach(@arrEntries)
		    {
			chomp($_);
			if($_ = m/^(GO:[0-9]+)\s+(.+)$/)
			{
			    my $category = $xmldoc->createElement('category');
			    $category->addChild($xmldoc->createAttribute(id => $1));
			    $statementSelect->execute($1);
			    my ($strName, $strDef, $strComment) = $statementSelect->fetchrow_array();
			    my $name = $xmldoc->createElement('name');
			    $name->addChild($xmldoc->createTextNode($strName));
			    $category->addChild($name);
			    my $def = $xmldoc->createElement('definition');
			    $def->addChild($xmldoc->createTextNode($strDef));
			    $category->addChild($def);
			    my $comment = $xmldoc->createElement('comment');
			    $comment->addChild($xmldoc->createTextNode($strComment));
			    $category->addChild($comment);
			    $bestHomolog->appendChild($category);
			    $nEntries++;
			}
		    }
		}
		elsif($strType eq 'pathway')
		{
		    foreach(@arrEntries)
		    {
			chomp($_);
			my @arrChunks = split(/\t/, $_);
			if($arrChunks[0] =~ m/(P[0-9]+)/)
			{
			    my $pathway = $xmldoc->createElement('pathway');
			    $pathway->addChild($xmldoc->createAttribute(id => $arrChunks[0]));
			    $pathway->addChild($xmldoc->createTextNode($arrChunks[1]));
			    $bestHomolog->appendChild($pathway);
			    $nEntries++;
			}
		    }
		}
		$contig->appendChild($bestHomolog) if($nEntries>0);
	    }
	    $xmldata->addChild($contig);
	}
        return Constants::ERR_OK;
    }
    
}

1;