#!/usr/bin/env perl

#   File:
#       Clustering.pm
#
#   Description:
#       Contains the Clustering analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       22.09.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use File::Temp;

use Axolotl::ATAPI::Constants;


package Clustering;
{
    my $MODULE = 'Clustering';
    my $VERSION = '1.0.1';
    my $DATE = '2014-09-22';
    
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
       return "Retrieves the data related to mapping of the individual reads to the contigs.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
	my $strExampleProbe = 'CUST_2607_PI429953125_A44K';
        my @arrMethods = ({_name => 'findSimilarMicroarrayProbes',
                           _description => 'Returns the list datasets with the mapping data for the specified sequences',
			   _args => [{_name => 'probe',
                                      _description => 'Name of the probe to retrieve the probes with similar profiles for',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'experiment',
                                      _description => "ID of the time-course experiment to use for comparison. Must be one of the IDs returned by TimeCourse.listExperimentsForProbes for this probe",
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no probe name or experiment ID specified'},
                                           {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If the experiment ID is not an integer'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If the specified ID is not a valid time course experiment ID or the specified probe does not exist'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.findSimilarMicroarrayProbes&probe=$strExampleProbe&experiment=19"});
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
        if($strMethod eq 'findSimilarMicroarrayProbes')
        {
            return $self->findSimilarMicroarrayProbes($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
    sub findSimilarMicroarrayProbes
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{probe})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No probe name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{probe} =~ s/'//g;
        my $strQuery = "SELECT COUNT(*) FROM MicroarrayProbe WHERE name='$refParams->{probe}'";
        my $nCount = $self->{_db}->selectrow_array($strQuery);
        if(!$nCount)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified probe does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        # Check if the experiment ID is valid.
        if(!$refParams->{experiment})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No experiment ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!($refParams->{experiment} =~ m/^[0-9]+$/))
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid experiment ID"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        $strQuery = "SELECT COUNT(*) from TCExperiment WHERE exp_id=$refParams->{experiment}";
        $nCount = $self->{_db}->selectrow_array($strQuery);
        if(!$nCount)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified experiment is not a time-course experiment"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $cluster = $xmldoc->createElement('cluster');
        $cluster->addChild($xmldoc->createAttribute(size => 10));
        $cluster->addChild($xmldoc->createAttribute(experiment => $refParams->{experiment}));
        for(my $i=0;$i<10;$i++)
        {
            my $probe = $xmldoc->createElement('probe');
            $probe->addChild($xmldoc->createAttribute(name => $refParams->{probe}));
            if($i==0)
            {
                $probe->addChild($xmldoc->createAttribute(pattern => 'true'));
            }
            else
            {
                $probe->addChild($xmldoc->createAttribute(similarity => '1'));
            }
            $cluster->addChild($probe);
        }
        $xmldata->addChild($cluster);
        return Constants::ERR_OK;
    }
}

1;