#!/usr/bin/env perl

#   File:
#       Domains.pm
#
#   Description:
#       Contains the Domains advanced module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.4.1
#
#   Date:
#       04.06.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Domains;
{
    my $MODULE = 'Domains';
    my $VERSION = '1.4.1';
    my $DATE = '2014-10-14';
    
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
       return "Retrieves the domains information for the contigs";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'listDomains',
                           _description => 'Returns the list of domains annotated to the specified sequences',
			   _args => [{_name => 'sequences',
                                      _description => 'Comma-separated list of sequence IDs to retrieve domain details for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listDomains&sequences=AC_02200035550.2"},
                          
                          {_name => 'findSequencesWithDomain',
                           _description => 'Returns the list of sequences that have the specified domain',
			   _args => [{_name => 'domain',
                                      _description => 'Signature ID of the domain',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'assemblies',
                                      _description => 'Comma-separated list of assemblies to consider',
                                      _type => 'optional',
                                      _default => 'all available'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If the domain ID is not specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.findSequencesWithDomain&domain=PF09103"});
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
        if($strMethod eq 'listDomains')
        {
            return $self->listDomains($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'findSequencesWithDomain')
        {
            return $self->findSequencesWithDomain($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub listDomains
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqIDs = (defined $refParams->{sequences}) ? split(/,/, $refParams->{sequences}) : ();
        if((scalar @arrSeqIDs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT Domain.frame AS frame, ".
                              "Domain.analysis AS analysis, ".
                              "Domain.sig_acc AS sig_acc, ".
                              "Domain.sig_desc AS sig_desc, ".
                              "Domain.start AS dstart, ".
                              "Domain.end AS end, ".
                              "Domain.evalue AS evalue, ".
                              "Domain.ips_acc AS ips_acc, ".
                              "Domain.ips_desc AS ips_desc, ".
                              "ORF.start AS orfstart, ".
                              "LENGTH(ORF.sequence) AS orflen, ".
                              "ORFType.name AS orftype, ".
                              "ORFType.description AS orfdesc, ".
                              "LENGTH(Contig.sequence) AS seqlen ".
                       "FROM Domain ".
                            "INNER JOIN Contig ON Domain.seq_id=Contig.c_id ".
                            "LEFT JOIN ORF ON Contig.c_id=ORF.c_id ".
                            "LEFT JOIN ORFType ON ORF.orft_id_id=ORFType.orft_id ".
                       "WHERE Domain.seq_id=? AND Domain.st_id=? ".
                       "ORDER BY analysis";
        my $stmtTranscript = $self->{_db}->prepare($strQuery);
        $strQuery = "SELECT Domain.frame AS frame, ".
                           "Domain.analysis AS analysis, ".
                           "Domain.sig_acc AS sig_acc, ".
                           "Domain.sig_desc AS sig_desc, ".
                           "Domain.start AS dstart, ".
                           "Domain.end AS end, ".
                           "Domain.evalue AS evalue, ".
                           "Domain.ips_acc AS ips_acc, ".
                           "Domain.ips_desc AS ips_desc, ".
                           "LENGTH(LibrarySequence.sequence) AS seqlen ".
                       "FROM Domain ".
                            "INNER JOIN LibrarySequence ON Domain.seq_id=LibrarySequence.ls_id ".
                       "WHERE Domain.seq_id=? AND Domain.st_id=? ".
                       "ORDER BY analysis";
        my $stmtLibSeq = $self->{_db}->prepare($strQuery);
        foreach my $strSeqID (@arrSeqIDs)
        {
            $strSeqID =~ s/'//g;
            my $stmt = undef;
	    my ($seq_id) = $self->{_db}->selectrow_array("SELECT c_id FROM Contig WHERE name='$strSeqID'");
	    my $st_id = undef;
	    if($seq_id)
	    {
		($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
		$stmt = $stmtTranscript;
	    }
	    else
	    {
		($seq_id) = $self->{_db}->selectrow_array("SELECT ls_id FROM LibrarySequence WHERE name='$strSeqID'");
		($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='libseq'");
		$stmt = $stmtLibSeq;
	    }
	    next if(!$seq_id || !$st_id);
            my $sequence = $xmldoc->createElement('sequence');
            $sequence->addChild($xmldoc->createAttribute('name' => $strSeqID));
            my $orf = undef;
            my $nLen = 0;
            my $strLastAnalysis = undef;
            my $analysis = undef;
            $stmt->execute($seq_id, $st_id);
            next if $stmt->rows==0;
            while(my $refResult = $stmt->fetchrow_hashref())
            {
                $nLen = $refResult->{seqlen};
                if($refResult->{orfstart} && !$orf)
                {
                    $orf = $xmldoc->createElement('orf');
                    $orf->addChild($xmldoc->createAttribute(start => $refResult->{orfstart}));
                    $orf->addChild($xmldoc->createAttribute(length => $refResult->{orflen}));
                    $orf->addChild($xmldoc->createAttribute(class => $refResult->{orftype}));
                    $orf->addChild($xmldoc->createTextNode($refResult->{orfdesc}));
                    $sequence->addChild($orf);
                }
                if($refResult->{analysis} ne $strLastAnalysis)
                {
                    $analysis = $xmldoc->createElement('analysis');
                    $analysis->addChild($xmldoc->createAttribute(name => $refResult->{analysis}));
                    $sequence->addChild($analysis);
                    $strLastAnalysis = $refResult->{analysis};
                }
                my $domain = $xmldoc->createElement('domain');
                $domain->addChild($xmldoc->createAttribute(start => $refResult->{dstart}));
                $domain->addChild($xmldoc->createAttribute(end => $refResult->{end}));
                $domain->addChild($xmldoc->createAttribute(evalue => $refResult->{evalue}));
                $domain->addChild($xmldoc->createAttribute(frame => $refResult->{frame}));
                my $signature = $xmldoc->createElement('signature');
                $signature->addChild($xmldoc->createAttribute(accession => $refResult->{sig_acc}));
                $signature->addChild($xmldoc->createTextNode($refResult->{sig_desc}));
                $domain->addChild($signature);
                if($refResult->{ips_acc})
                {
                    my $interpro = $xmldoc->createElement('interpro');
                    $interpro->addChild($xmldoc->createAttribute(accession => $refResult->{ips_acc}));
                    $interpro->addChild($xmldoc->createTextNode($refResult->{ips_desc}));
                    $domain->addChild($interpro);
                }
                $analysis->addChild($domain);
            }
            if($nLen)
            {
                $sequence->addChild($xmldoc->createAttribute(length => $nLen));
                $xmldata->addChild($sequence);
            }
        }
        return Constants::ERR_OK;
    }
    
    sub findSequencesWithDomain
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{domain})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No domain ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        return Constants::ERR_OK;
    }
}

1;