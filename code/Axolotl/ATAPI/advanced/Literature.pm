#!/usr/bin/env perl

#   File:
#       Literature.pm
#
#   Description:
#       Contains the Literature advanced module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       25.08.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use LWP::Simple;
use XML::Simple;
use Axolotl::ATAPI::Constants;


package Literature;
{
    my $MODULE = 'Literature';
    my $VERSION = '1.0.1';
    my $DATE = '2013-08-25';
    
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
       return "Retrieves the list of related literature, i.e. list of abstracts containing the annotated protein symbol.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'getAbstractsList',
                           _description => 'Returns the list of related publications',
			   _args => [{_name => 'contigs',
                                      _description => 'Comma-separated list of contig IDs to retrieve related literature for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getAbstractsList&contigs=NT_010001267763.1",
                           _remarks => "No entry is created in the resulting XML if the contig ID is invalid or if the contig has no annotation. If, however, there are just no ".
                                            "related publications an empty node is created."});
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
        if($strMethod eq 'getAbstractsList')
        {
            return $self->getAbstractsList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    # Private module methods.
    sub getAbstractsList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrContigs = (defined $refParams->{contigs}) ? split(/,/, $refParams->{contigs}) : ();
        if((scalar @arrContigs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        foreach my $strContigID (@arrContigs)
        {
            my $strQuery = "SELECT symbol FROM Annotation INNER JOIN Contig ON Contig.an_id=Annotation.an_id WHERE Contig.name='$strContigID';";
            my $refResult = $self->{_db}->selectrow_hashref($strQuery);
            next if !$refResult;
            my $contig = $xmldoc->createElement('contig');
            $contig->addChild($xmldoc->createAttribute('name' => $strContigID)); 
            # Get the list of related publication IDs (PMIDs).
	    next if((!$refResult->{symbol}) || (lc($refResult->{symbol}) eq 'n/a'));
            my $strURL = "http://string-db.org/api/json/abstractsList?identifiers=$refResult->{symbol}";
            my $strResponse = LWP::Simple::get $strURL;
            my @arrPubIDs = ();
            push(@arrPubIDs, $1) while($strResponse =~ m/PMID:([0-9]+)/g);
            $strURL = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id='.join(',', @arrPubIDs);
            $strResponse = LWP::Simple::get $strURL;
            my $xml = XML::Simple::XMLin($strResponse, ForceArray => ['PubmedArticle', 'Author', 'AbstractText'], KeepRoot => 1);
            my @arrPubs = @{$xml->{PubmedArticleSet}->{PubmedArticle}};
            foreach my $pub (@arrPubs)
            {
                my $publication = $xmldoc->createElement('publication');
                # General details.
                my $mlc = $pub->{MedlineCitation};
                # Title.
                $publication->addChild($xmldoc->createAttribute('title' => $mlc->{Article}->{ArticleTitle}));
                # PMID.
                $publication->addChild($xmldoc->createAttribute('PMID' => $mlc->{PMID}->{content}));
                # Journal.
                my $journal = $mlc->{Article}->{Journal};
                $publication->addChild($xmldoc->createAttribute('journal' => $journal->{ISOAbbreviation}));
                $publication->addChild($xmldoc->createAttribute('volume' => $journal->{JournalIssue}->{Volume}));
                $publication->addChild($xmldoc->createAttribute('issue' => $journal->{JournalIssue}->{Issue}));
                $publication->addChild($xmldoc->createAttribute('date' => "$journal->{JournalIssue}->{PubDate}->{Month} $journal->{JournalIssue}->{PubDate}->{Year}"));
                $publication->addChild($xmldoc->createAttribute('pages' => $mlc->{Article}->{Pagination}->{MedlinePgn}));
                # Authors.
                my $authors = $xmldoc->createElement('authors');
                my @arrAuthors = @{$mlc->{Article}->{AuthorList}->{Author}};
                foreach my $au (@arrAuthors)
                {
                    my $author = $xmldoc->createElement('author');
                    $author->addChild($xmldoc->createAttribute('name' => "$au->{LastName}, $au->{Initials}"));
                    $authors->addChild($author); 
                }
                $publication->addChild($authors); 
                # Link.
                my $link = $xmldoc->createElement('link');
                $link->addChild($xmldoc->createTextNode("http://www.ncbi.nlm.nih.gov/pubmed/$mlc->{PMID}->{content}/"));
                $publication->addChild($link);
                # Abstract.
                my $strAbstract = '';
		if($mlc->{Article}->{Abstract}->{AbstractText})
		{
		    if((scalar @{$mlc->{Article}->{Abstract}->{AbstractText}})>1)
		    {
			$strAbstract .= "$_->{content} " foreach(@{$mlc->{Article}->{Abstract}->{AbstractText}});
		    }
		    else
		    {
			$strAbstract = @{$mlc->{Article}->{Abstract}->{AbstractText}}[0];
		    }
		}
		else
		{
		    $strAbstract = 'No abstract is available for this article.';
		}
                $publication->addChild($xmldoc->createTextNode($strAbstract));
                $contig->addChild($publication);
            }
            $xmldata->addChild($contig);
        }
        return Constants::ERR_OK;
    }

}

1;