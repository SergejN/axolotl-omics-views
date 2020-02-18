#!/usr/bin/env perl

#   File:
#       Gene.pm
#
#   Description:
#       Contains the Gene core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       25.10.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Gene;
{
    my $MODULE = 'Gene';
    my $VERSION = '1.0.1';
    my $DATE = '2014-25-10';
    
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
       return "Retrieves the basic details about the gene, such as name, length, sequence, annotation, and regions.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my $strExampleGene = 'AMex_02200010705.1';
        my @arrMethods = ({_name => 'getSummary',
                           _description => 'Returns the gene sequence, chromosome location, and annotation',
                           _args => [{_name => 'genes',
                                        _description => 'Comma-separated list of gene names to retrieve information for',
                                        _type => 'required',
                                        _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no gene names are specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getSummary&genes=$strExampleGene",
			   _remarks => "The resulting XML only contains entries for valid gene names."},
                          {_name => 'listRegions',
                           _description => 'Returns the list of regions annotated to the specified genes',
                           _args => [{_name => 'genes',
                                        _description => 'Comma-separated list of gene names to retrieve list of regions for',
                                        _type => 'required',
                                        _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no gene names are specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listRegions&genes=$strExampleGene",
			   _remarks => "The resulting XML only contains entries for valid gene names."});
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
        if($strMethod eq 'getSummary')
        {
            return $self->getSummary($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'listRegions')
        {
            return $self->listRegions($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getSummary
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrGenes = (defined $refParams->{genes}) ? split(/,/, $refParams->{genes}) : ();
        $_=~ s/'/\\'/g foreach @arrGenes;
        if((scalar @arrGenes)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No gene name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        foreach my $strGene (@arrGenes)
        {
            my $strQuery = "SELECT chr AS chromosome, ".
                                  "sequence, ".
                                  "LENGTH(sequence) AS length, ".
                                  "symbol, ".
                                  "definition ".
                           "FROM Gene ".
                                "LEFT JOIN Annotation ON Gene.an_id=Annotation.an_id ".
                           "WHERE Gene.name='$strGene'";
            my $statement = $self->{_db}->prepare($strQuery);
            $statement->execute();
            my $refResult = $statement->fetchrow_hashref();
            next if(!$refResult);
            my $gene = $xmldoc->createElement('gene');
            $gene->addChild($xmldoc->createAttribute(name => $strGene));
            $gene->addChild($xmldoc->createAttribute(length => $refResult->{length}));
            $gene->addChild($xmldoc->createAttribute(chromosome => ($refResult->{chromosome} ? $refResult->{chromosome} : 'N/A')));
            $gene->addChild($xmldoc->createTextNode($refResult->{sequence}));
            if($refResult->{definition})
            {
                my $annotation = $xmldoc->createElement('annotation');
                $annotation->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
                $annotation->addChild($xmldoc->createTextNode($refResult->{definition}));
                $gene->addChild($annotation);
            }
            $xmldata->addChild($gene);
        }
        return Constants::ERR_OK;
    }
    
    sub listRegions
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrGenes = (defined $refParams->{genes}) ? split(/,/, $refParams->{genes}) : ();
        $_=~ s/'/\\'/g foreach @arrGenes;
        if((scalar @arrGenes)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No gene name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        foreach my $strGene (@arrGenes)
        {
            my $strQuery = "SELECT GeneRegion.name AS name, ".
                                  "GeneRegion.type AS type, ".
                                  "GeneRegion.sequence AS sequence, ".
                                  "LENGTH(Gene.sequence) AS length, ".
                                  "start, ".
                                  "end ".
                           "FROM GeneRegion ".
                                "INNER JOIN Gene ON GeneRegion.g_id=Gene.g_id ".
                           "WHERE Gene.name='$strGene' ".
                           "ORDER BY GeneRegion.name, GeneRegion.type, start";
            my $statement = $self->{_db}->prepare($strQuery);
            $statement->execute();
            my $refResult = $statement->fetchrow_hashref();
            next if(!$refResult);
            my $gene = $xmldoc->createElement('gene');
            $gene->addChild($xmldoc->createAttribute(name => $strGene));
            $gene->addChild($xmldoc->createAttribute(length => $refResult->{length}));
            my $region = undef;
            my $strRegName = undef;
            my $strRegType = undef;
            while($refResult)
            {
                if(($strRegName ne $refResult->{name}) ||
                   ($strRegType ne $refResult->{type}))
                {
                    $strRegName = $refResult->{name};
                    $strRegType = $refResult->{type};
                    $region = $xmldoc->createElement('region');
                    $region->addChild($xmldoc->createAttribute(name => $refResult->{name}));
                    $region->addChild($xmldoc->createAttribute(type => $refResult->{type}));
                    $gene->addChild($region);
                }
                my $fragment = $xmldoc->createElement('fragment');
                $fragment->addChild($xmldoc->createAttribute(start => $refResult->{start}));
                $fragment->addChild($xmldoc->createAttribute(end => $refResult->{end}));
                $fragment->addChild($xmldoc->createTextNode($refResult->{sequence}));
                $region->addChild($fragment);
                $refResult = $statement->fetchrow_hashref();
            }
            $xmldata->addChild($gene);
        }
        return Constants::ERR_OK;
    }
    
}

1;