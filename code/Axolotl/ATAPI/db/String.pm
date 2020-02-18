#!/usr/bin/env perl

#   File:
#       String.pm
#
#   Description:
#       Contains the STRING database module of the Axolotl Transcriptome API (ATAPI).
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


package String;
{
    my $MODULE = 'String';
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
       return "Fetches the data from the STRING database.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'listOrganisms',
                           _description => 'Returns the list of organisms the data are available for',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listOrganisms"},
                          
                          {_name => 'listInteractors',
                           _description => 'Returns the list of interaction partners of the specified proteins',
                           _args => [{_name => 'proteins',
                                      _description => 'Comma-separated list of Ensembl IDs of proteins to retrieve interaction partners for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no protein ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listInteractors&seqIDs=ENSDARP00000000002"});
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
        elsif($strMethod eq 'listInteractors')
        {
            return $self->listInteractors($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
    
    sub listInteractors
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrProteins = ($refParams->{proteins}) ? split(/,/, $refParams->{proteins}) : ();
        if((scalar @arrProteins)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No protein ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT ens_id1, ".
                              "ens_id2, ".
                              "score, ".
                              "name AS type ".
                       "FROM PPI ".
                            "INNER JOIN PPIType ON PPI.ppit_id=PPIType.ppit_id ".
                       "WHERE ens_id1=? OR ens_id2=? ".
                       "ORDER BY ens_id1, ens_id2";
        my $statement = $self->{_db}->prepare($strQuery);
        foreach my $strProtein (@arrProteins)
        {
            $statement->execute($strProtein, $strProtein);
            next unless $statement->rows;
            my $query = $xmldoc->createElement('query');
            $query->addChild($xmldoc->createAttribute(name => $strProtein));
            my $strPartner = undef;
            my $partner = undef;
            while(my $refResult = $statement->fetchrow_hashref())
            {
                my $strPartnerID = ($refResult->{ens_id1} eq $strProtein) ? $refResult->{ens_id2} : $refResult->{ens_id1};
                if($strPartnerID ne $strPartner)
                {
                    $partner = $xmldoc->createElement('partner');
                    $partner->addChild($xmldoc->createAttribute(name => $strPartnerID));
                    $query->addChild($partner);
                    $strPartner = $strPartnerID;
                }
		if(lc($refResult->{type}) eq 'total')
		{
		    $partner->addChild($xmldoc->createAttribute(score => $refResult->{score}));
		}
		else
		{
		    my $evidence = $xmldoc->createElement('evidence');
		    $evidence->addChild($xmldoc->createAttribute(type => $refResult->{type}));
		    $evidence->addChild($xmldoc->createAttribute(score => $refResult->{score}));
		    $partner->addChild($evidence);
		}
            }
            $xmldata->addChild($query);
        }
        return Constants::ERR_OK;
    }
}

1;