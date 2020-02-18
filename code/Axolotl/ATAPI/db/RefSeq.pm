#!/usr/bin/env perl

#   File:
#       RefSeq.pm
#
#   Description:
#       Contains the RefSeq database module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       27.10.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package RefSeq;
{
    my $MODULE = 'RefSeq';
    my $VERSION = '1.0.1';
    my $DATE = '2014-27-10';
    
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
       return "Retrieves the basic details about the RefSeq database.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'listOrganisms',
                           _description => 'Returns the list of available organisms and corresponding sequence counts',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listOrganisms"},
                          
                          {_name => 'getComposition',
                           _description => 'Returns the list of available organisms and corresponding sequence counts',
                           _args => [{_name => 'organisms',
                                      _description => 'Comma-separated list of organisms to retrieve composition for',
                                      _type => 'optional',
                                      _default => 'all available organisms'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listOrganisms"},
                          
                          {_name => 'getSynonyms',
                           _description => 'Returns the list of synonyms for the specified RefSeq IDs',
                           _args => [{_name => 'seqIDs',
                                      _description => 'Comma-separated list of RefSeqIDs to retrieve synonyms for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no RefSeq ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getSynonyms&seqIDs=NP_034468.2"},
                          
                          {_name => 'getRefSeqID',
                           _description => 'Returns the RefSeq IDs for the specified alternative IDs (e.g. Ensembl)',
                           _args => [{_name => 'seqIDs',
                                      _description => 'Comma-separated list of IDs to retrieve RefSeq IDs for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getRefSeqID&seqIDs=Q9QY42"});
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
        if($strMethod eq 'listOrganisms')
        {
            return $self->listOrganisms($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getComposition')
        {
            return $self->getComposition($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getSynonyms')
        {
            return $self->getSynonyms($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getRefSeqID')
        {
            return $self->getRefSeqID($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub listOrganisms
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = "SELECT name, ".
                              "sequences, ".
                              "tax_id ".
                       "FROM RefSeqOrganism";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $organism = $xmldoc->createElement('organism');
            $organism->addChild($xmldoc->createAttribute(name => $refResult->{name}));
            $organism->addChild($xmldoc->createAttribute(sequences => $refResult->{sequences}));
            $organism->addChild($xmldoc->createAttribute(taxonomy => $refResult->{tax_id}));
            $xmldata->addChild($organism);
        }
        return Constants::ERR_OK;
    }
    
    sub getComposition
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrOrganisms = ($refParams->{organisms}) ? split(/,/, $refParams->{organisms}) : ();
        my $strQuery = "SELECT SUBSTRING(seq_id,1,2) AS prefix, ".
                              "COUNT(SUBSTRING(seq_id,1,2)) AS count, ".
                              "RefSeqOrganism.name AS name ".
                       "FROM RefSeq ".
                            "INNER JOIN RefSeqOrganism ON RefSeq.rso_id=RefSeqOrganism.rso_id";
        if(scalar @arrOrganisms)
        {
            $_ =~ s/'/\\'/g foreach @arrOrganisms;
            $_ = "'$_'" foreach @arrOrganisms;
            my $strOrgList = join(',', @arrOrganisms);
            $strQuery .= " WHERE RefSeqOrganism.name IN ($strOrgList)";
        }
        $strQuery .= " "."GROUP BY prefix, RefSeqOrganism.rso_id ".
                         "ORDER BY name";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        my %hmTypes = ('NP' => {name => 'curated', description => 'Products mainly derived from GenBank cDNA and EST data'},
                       'XP' => {name =>'predicted', description => 'Products generated by genome annotation pipeline'},
                       'YP' => {name => 'mitochondrial', description => 'Mitochondrial proteins'});
        my $strOrg = undef;
        my $organism = undef;
        while(my $refResult = $statement->fetchrow_hashref())
        {
            if($refResult->{name} ne $strOrg)
            {
                $organism = $xmldoc->createElement('organism');
                $organism->addChild($xmldoc->createAttribute(name => $refResult->{name}));
                $strOrg = $refResult->{name};
                $xmldata->addChild($organism);
            }
            my $type = $xmldoc->createElement('type');
            $type->addChild($xmldoc->createAttribute(type => $hmTypes{$refResult->{prefix}}->{name}));
            $type->addChild($xmldoc->createAttribute(count => $refResult->{count}));
            $type->addChild($xmldoc->createTextNode($hmTypes{$refResult->{prefix}}->{description}));
            $organism->addChild($type);
        }
        return Constants::ERR_OK;
    }
    
    sub getSynonyms
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqIDs = ($refParams->{seqIDs}) ? split(/,/, $refParams->{seqIDs}) : ();
        if((scalar @arrSeqIDs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT Synonym.name AS seq_id, ".
                              "SynonymType.name AS type ".
                       "FROM RefSeq ".
                            "INNER JOIN Synonym ON RefSeq.rs_id=Synonym.rs_id ".
                            "INNER JOIN SynonymType ON Synonym.snt_id=SynonymType.snt_id ".
                       "WHERE RefSeq.seq_id=?";
        my $statement = $self->{_db}->prepare($strQuery);
        foreach my $strID (@arrSeqIDs)
        {
            $statement->execute($strID);
            next unless $statement->rows;
            my $refseq = $xmldoc->createElement('RefSeq');
            $refseq->addChild($xmldoc->createAttribute(id => $strID));
            while(my $refResult = $statement->fetchrow_hashref())
            {
                my $synonym = $xmldoc->createElement('synonym');
                $synonym->addChild($xmldoc->createAttribute(id => $refResult->{seq_id}));
                $synonym->addChild($xmldoc->createAttribute(type => $refResult->{type}));
                $refseq->addChild($synonym);
            }
            $xmldata->addChild($refseq);
        }
        return Constants::ERR_OK;
    }
    
    sub getRefSeqID
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSeqIDs = ($refParams->{seqIDs}) ? split(/,/, $refParams->{seqIDs}) : ();
        if((scalar @arrSeqIDs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT RefSeq.seq_id AS seq_id, ".
	                      "RefSeq.symbol AS symbol, ".
			      "RefSeq.definition AS definition ".
                       "FROM RefSeq ".
                            "INNER JOIN Synonym ON RefSeq.rs_id=Synonym.rs_id ".
                       "WHERE Synonym.name=?";
        my $statement = $self->{_db}->prepare($strQuery);
        foreach my $strID (@arrSeqIDs)
        {
            $statement->execute($strID);
            next unless $statement->rows;
            my $query = $xmldoc->createElement('query');
            $query->addChild($xmldoc->createAttribute(id => $strID));
            while(my $refResult = $statement->fetchrow_hashref())
            {
                my $refseq = $xmldoc->createElement('RefSeq');
                $refseq->addChild($xmldoc->createAttribute(id => $refResult->{seq_id}));
		$refseq->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol})) if($refResult->{symbol} ne 'N/A');
		$refseq->addChild($xmldoc->createTextNode($refResult->{definition}));
                $query->addChild($refseq);
            }
            $xmldata->addChild($query);
        }
        return Constants::ERR_OK;
    }
}

1;