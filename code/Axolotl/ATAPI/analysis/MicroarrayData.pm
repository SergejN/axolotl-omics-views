#!/usr/bin/env perl

#   File:
#       MicroarrayData.pm
#
#   Description:
#       Contains the MicroarrayData analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       21.02.2018
#
#   Copyright:
#       Sergej Nowoshilow, IMP

use strict;
use warnings;
use File::Temp;
use Storable;

use Axolotl::ATAPI::Constants;


package MicroarrayData;
{
    my $MODULE = 'MicroarrayData';
    my $VERSION = '1.0.1';
    my $DATE = '2018-02-21';
    
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
       return "Retrieves the data related to static microarray expression profiles of the sequences.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my $strExampleContig = 'NT_010001269873.2';
        my $strExampleProbe = 'CUST_2607_PI429953125_A44K';
        my @arrMethods = ({_name => 'getExperimentsList',
                           _description => 'Returns the list of available experiments',
			   _args => [{_name => 'sequences',
                                      _description => 'Comma-separated list of names of the sequences to retrieve experiments list for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence name specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getExperimentsList&sequences=$strExampleContig"},
                          
                          {_name => 'getExperimentDetails',
                           _description => 'Returns the detailed information about the static microarray experiment',
			   _args => [{_name => 'experiments',
                                      _description => 'Comma-separated list of experiment IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no experiment ID specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getExperimentDetails&experiments=28"},
                          
                          {_name => 'getExperimentData',
                           _description => 'Returns the expression level data for the specified sequence, experiment, and probes.',
			   _args => [{_name => 'sequence',
                                      _description => 'Name of the sequence to retrieve the data for',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'experiment',
                                      _description => "Experiment ID. Must be a value returned by $MODULE.getExperimentsList for this sequence",
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence name or no experiment ID specified'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no data are available for the specified contig and experiment'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getExperimentData&sequence=$strExampleContig&experiment=19"},
			  
			  {_name => 'getProbeData',
                           _description => 'Returns the experimental data for each specified probe',
                           _args => [{_name => 'probes',
                                      _description => 'Comma-separated list of probe names to retrieve experimental data for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'experiment',
                                      _description => "Experiment ID",
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no probe name or no experiment ID is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If the experiment with the specified ID does not exist'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getProbeData&probes=$strExampleProbe&experiment=28"});
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
        if($strMethod eq 'getExperimentsList')
        {
            return $self->getExperimentsList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getExperimentDetails')
        {
            return $self->getExperimentDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getExperimentData')
        {
            return $self->getExperimentData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getProbeData')
        {
            return $self->getProbeData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
    sub getExperimentsList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrSequences = (defined $refParams->{sequences}) ? split(/,/, $refParams->{sequences}) : ();
        if((scalar @arrSequences)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $_=~ s/'/\\'/g foreach @arrSequences;
        my $privilege = $refParams->{_user}->{privilege};
        my $strQuery = 'SELECT DISTINCT Experiment.name AS experiment, ' .
                                          'Experiment.description AS description, ' .
                                          'MAExperiment.date AS date, ' .
                                          'MAExperiment.groups AS groups, '.
                                          'Experiment.exp_id AS id, '.
                                          'Experiment.privilege AS privilege, '.
                                          'Author.name AS author ' .
                          'FROM MAExperiment '.
                               'INNER JOIN Experiment ON MAExperiment.exp_id=Experiment.exp_id '.
                               'INNER JOIN Author ON MAExperiment.au_id=Author.au_id '.
                               'INNER JOIN MicroarrayData ON MAExperiment.mae_id=MicroarrayData.mae_id '.
                               'INNER JOIN MicroarrayProbe ON MicroarrayData.map_id=MicroarrayProbe.map_id '.
                               'INNER JOIN MicroarrayProbeMapping ON MicroarrayProbe.map_id=MicroarrayProbeMapping.map_id '.
                          'WHERE MicroarrayProbeMapping.seq_id=? AND MicroarrayProbeMapping.st_id=?';
        my $statement = $self->{_db}->prepare($strQuery);
        foreach my $strSeqName (@arrSequences)
        {
            my ($seq_id) = $self->{_db}->selectrow_array("SELECT c_id FROM Contig WHERE name='$strSeqName'");
            my $st_id = undef;
            if($seq_id)
            {
                ($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
            }
            else
            {
                ($seq_id) = $self->{_db}->selectrow_array("SELECT ls_id FROM LibrarySequence WHERE name='$strSeqName'");
                ($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='libseq'");
            }
            next if(!$seq_id || !$st_id);
            my $sequence = $xmldoc->createElement('sequence');
            $sequence->addChild($xmldoc->createAttribute(name => $strSeqName));
            $statement->execute($seq_id, $st_id);

            while(my $refResult = $statement->fetchrow_hashref())
            {
                if(($refResult->{privilege} == 0) || (($refResult->{privilege} & $privilege) == $refResult->{privilege}))
                {
                    my $experiment = $xmldoc->createElement('experiment');
                    $experiment->addChild($xmldoc->createAttribute(name => $refResult->{experiment}));
                    $experiment->addChild($xmldoc->createAttribute(date => $refResult->{date}));
                    $experiment->addChild($xmldoc->createAttribute(author => $refResult->{author}));
                    $experiment->addChild($xmldoc->createAttribute(id => $refResult->{id}));
                    $experiment->addChild($xmldoc->createAttribute(groups => scalar(split(/;/, $refResult->{groups}))));
                    $experiment->addChild($xmldoc->createTextNode($refResult->{description}));
                    $sequence->addChild($experiment);
                }
                $refResult = $statement->fetchrow_hashref();
            }
            $xmldata->addChild($sequence);
        }
        return Constants::ERR_OK;
    }
    
    sub getExperimentDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrIDs = (defined $refParams->{experiments}) ? split(/,/, $refParams->{experiments}) : ();
        if((scalar @arrIDs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No experiment ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        
        use Data::Dumper;
        print "Content-type: text/html\n\n<pre>";
        print "Here2";
        exit(0);
        
        my $strQuery = 'SELECT DISTINCT Experiment.name AS experiment, ' .
                                       'Experiment.description AS description, ' .
                                       'MAExperiment.date AS date, ' .
                                       'MAExperiment.groups AS groups, '.
                                       'MAExperiment.samples AS samples, '.
                                       'Experiment.exp_id AS id, '.
                                       'Experiment.details AS details, '.
                                       'Author.name AS author ' .
                       'FROM MAExperiment '.
                            'INNER JOIN Experiment ON MAExperiment.exp_id=Experiment.exp_id '.
                            'INNER JOIN Author ON MAExperiment.au_id=Author.au_id '.
                       'WHERE Experiment.exp_id=?';
        my $statement = $self->{_db}->prepare($strQuery);
        foreach my $strExpID (@arrIDs)
        {
            $statement->execute($strExpID);
            my $refResult = $statement->fetchrow_hashref();
            next if(!$refResult);
            my $experiment = $xmldoc->createElement('experiment');
            $experiment->addChild($xmldoc->createAttribute(name => $refResult->{experiment}));
            $experiment->addChild($xmldoc->createAttribute(date => $refResult->{date}));
            $experiment->addChild($xmldoc->createAttribute(author => $refResult->{author}));
            $experiment->addChild($xmldoc->createAttribute(id => $refResult->{id}));
            $experiment->addChild($xmldoc->createTextNode($refResult->{description}));
            my $details = $xmldoc->createElement('details');
            $details->addChild($xmldoc->createTextNode($refResult->{details}));
            $experiment->addChild($details);
            my $groups = $xmldoc->createElement('groups');
            my @arrGroups = split(/;/, $refResult->{groups});
            my @arrGrpSamples = split(/\|/, $refResult->{samples});
            for(my $i=0;$i<(scalar @arrGroups);$i++)
            {
                my $group = $xmldoc->createElement('group');
                $group->addChild($xmldoc->createAttribute(name => $arrGroups[$i]));
                my @arrSamples = split(/;/, $arrGrpSamples[$i]);
                foreach my $strSample (@arrSamples)
                {
                    my $sample = $xmldoc->createElement('sample');
                    $sample->addChild($xmldoc->createAttribute(name => $strSample));
                    $group->addChild($sample);
                }
                $groups->addChild($group);
            }
            $experiment->addChild($groups);
            $xmldata->addChild($experiment);
        }
        return Constants::ERR_OK;
    }
 
    sub getExperimentData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strSeqName = $refParams->{sequence};
        if(!$strSeqName)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strSeqName =~ s/'/\\'/g;
        my $strExpID = $refParams->{experiment};
        if(!$strExpID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No experiment ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strExpID =~ s/'/\\'/g;
        my $strQuery = "SELECT Experiment.name, ".
                              "groups, ".
                              "samples, ".
                              "MAExperiment.mae_id AS mae_id ".
                       "FROM Experiment ".
                            "INNER JOIN MAExperiment ON Experiment.exp_id=MAExperiment.exp_id ".
                            "INNER JOIN ExperimentType ON Experiment.et_id=ExperimentType.et_id ".
                       "WHERE Experiment.exp_id=$strExpID";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid microarray experiment ID: '$strExpID'"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $sequence = $xmldoc->createElement('sequence');
        $sequence->addChild($xmldoc->createAttribute(name => $strSeqName));
        # Experiment details.
        my $experiment = $xmldoc->createElement('experiment');
        $experiment->addChild($xmldoc->createAttribute(id => $strExpID));
        $experiment->addChild($xmldoc->createAttribute(name => $refResult->{name}));
        $sequence->addChild($experiment);
        my ($seq_id) = $self->{_db}->selectrow_array("SELECT c_id FROM Contig WHERE name='$strSeqName'");
        my $st_id = undef;
        if($seq_id)
        {
            ($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
        }
        else
        {
            ($seq_id) = $self->{_db}->selectrow_array("SELECT ls_id FROM LibrarySequence WHERE name='$strSeqName'");
            ($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='libseq'");
        }
        if(!$seq_id || !$st_id)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No microarray data found for the specified sequence and experiment"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        
        return $self->getMicroarrayExperimentData($xmldoc, $xmldata, $xmlerr, {sequence => $sequence,
                                                                                experiment => $experiment,
                                                                                seq_id => $seq_id,
                                                                                st_id => $st_id,
                                                                                mae_id => $refResult->{mae_id},
                                                                                groups => $refResult->{groups},
                                                                                samples => $refResult->{samples}});
    }
	
	
    sub getMicroarrayExperimentData
    {
        my ($self, $xmldoc, $xmldata, $xmlerr, $refParams) = @_;
        my @arrGroups = split(/;/, $refParams->{groups});
        my %hmSamples = ();
        my @arrTmp = split(/\|/, $refParams->{samples});
        for(my $i=0;$i<(scalar @arrTmp);$i++)
        {
            my @arrSamples = split(/;/, $arrTmp[$i]);
            $hmSamples{$arrGroups[$i]} = \@arrSamples;
        }

        my $strQuery = "SELECT DISTINCT `group`, ".
                              "replicate, ".
                              "data, ".
                              "MicroarrayProbe.name AS probe, ".
                              "MicroarrayProbe.strand AS strand ".
                       "FROM MicroarrayData ".
                            "INNER JOIN MicroarrayProbeMapping ON MicroarrayProbeMapping.map_id=MicroarrayData.map_id ".
                            "INNER JOIN MicroarrayProbe ON MicroarrayProbeMapping.map_id=MicroarrayProbe.map_id ".
                       "WHERE MicroarrayData.mae_id=$refParams->{mae_id} ".
                            "AND MicroarrayProbeMapping.seq_id=$refParams->{seq_id} ".
                            "AND MicroarrayProbeMapping.st_id=$refParams->{st_id} ".
                       "ORDER BY probe, `group`, replicate";
                       
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        my $refResult = $statement->fetchrow_hashref();
        if($refResult)
        {
            my %hmStrands = ('U' => 'unknown strand',
                             'S' => 'sense strand',
                             'A' => 'antisense strand');
            my $probe = undef;
            my $strProbe = '';
            my $group = undef;
            my $strGroup = '';
            my @arrSamples = ();
            my %hmGroups = ();
            while($refResult)
            {
                # Probe
                if($strProbe ne $refResult->{probe})
                {
                    %hmGroups = ();
                    $probe = $xmldoc->createElement('probe');
                    $probe->addChild($xmldoc->createAttribute(name => $refResult->{probe}));
                    $probe->addChild($xmldoc->createAttribute(strand => $hmStrands{$refResult->{strand}}));
                    $probe->addChild($xmldoc->createAttribute(unit => 'Intensity'));
                    $refParams->{experiment}->addChild($probe);
                    $strProbe = $refResult->{probe};
                }
                # Group
                if($strGroup ne $refResult->{group})
                {
                    $group = $xmldoc->createElement('group');
                    $group->addChild($xmldoc->createAttribute(name => $refResult->{group}));
                    $probe->addChild($group);
                    $strGroup = $refResult->{group};
                    $hmGroups{$strGroup} = $group;
                }
                # Replicate
                @arrSamples = @{$hmSamples{$strGroup}};
                my $replicate = $xmldoc->createElement('replicate');
                $replicate->addChild($xmldoc->createAttribute(name => $refResult->{replicate}));
                my @arrValues = split(/;/, $refResult->{data});
                for(my $i=0;$i<(scalar @arrSamples);$i++)
                {
                    my $sample = $xmldoc->createElement('sample');
                    $sample->addChild($xmldoc->createAttribute(name => $arrSamples[$i]));
                    $sample->addChild($xmldoc->createAttribute(value => $arrValues[$i]));
                    $sample->addChild($xmldoc->createAttribute(index => $i+1));
                    $replicate->addChild($sample);
                }
                $hmGroups{$strGroup}->addChild($replicate);
                
                $refResult = $statement->fetchrow_hashref();
            }
            $xmldata->addChild($refParams->{sequence});
        }
        return Constants::ERR_OK;
    }
    
    sub getProbeData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrProbes = (defined $refParams->{probes}) ? split(/,/, $refParams->{probes}) : ();
            if((scalar @arrProbes)==0)
            {
                $xmlerr->addChild($xmldoc->createTextNode("No probe name specified"));
                return Constants::ERR_NOT_ENOUGH_PARAMETERS;
            }
        $_=~ s/'/\\'/g foreach @arrProbes;
        my $strExpID = $refParams->{experiment};
            if(!$strExpID)
            {
                $xmlerr->addChild($xmldoc->createTextNode("No experiment ID specified"));
                return Constants::ERR_NOT_ENOUGH_PARAMETERS;
            }
            $strExpID =~ s/'/\\'/g;
        my $strQuery = "SELECT Experiment.name, ".
                                  "labels, ".
                                  "timepoints, ".
                      "TCExperiment.tce_id AS tce_id ".
                           "FROM Experiment ".
                                  "INNER JOIN TCExperiment ON Experiment.exp_id=TCExperiment.exp_id ".
                      "INNER JOIN ExperimentType ON Experiment.et_id=ExperimentType.et_id ".
                           "WHERE Experiment.exp_id=$strExpID";
            my ($strExpName, $strLabels, $strTimepoints, $tce_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$tce_id)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified experiment does not exist"));
                return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strQuery = "SELECT sample, replicate, data ".
                    "FROM TCMicroarrayData ".
                     "INNER JOIN MicroarrayProbe ON TCMicroarrayData.map_id=MicroarrayProbe.map_id ".
                "WHERE MicroarrayProbe.name = ? AND TCMicroarrayData.tce_id=$tce_id ".
                "ORDER BY sample, replicate";	    
        my $statement = $self->{_db}->prepare($strQuery);
        my @arrTP = split(/;/, $strTimepoints);
        my @arrLabels = split(/;/, $strLabels);
        my $nTP = scalar @arrTP;
        foreach my $strProbe (@arrProbes)
        {
            $statement->execute($strProbe);
            my $probe = $xmldoc->createElement('probe');
                $probe->addChild($xmldoc->createAttribute(name => $strProbe));
            my $experiment = $xmldoc->createElement('experiment');
            $experiment->addChild($xmldoc->createAttribute(name => $strExpName));
            $experiment->addChild($xmldoc->createAttribute(id => $strExpID));
            my $strSample = '';
            my @arrProbeTPs = ();
            my $sample = undef;
            for(my $i=0;$i<$nTP;$i++)
            {
            my $timepoint = $xmldoc->createElement('timepoint');
            $timepoint->addChild($xmldoc->createAttribute(time => $arrTP[$i]));
            $timepoint->addChild($xmldoc->createAttribute(label => $arrLabels[$i]));
            $experiment->addChild($timepoint);
            push(@arrProbeTPs, {timepoint => $arrTP[$i],
                        element => $timepoint,
                        index => $i});
            }
            while(my $refResult = $statement->fetchrow_hashref())
            {
            if($strSample ne $refResult->{sample})
                    {
                        foreach my $probeTP (@arrProbeTPs)
                        {
                            $sample = $xmldoc->createElement('sample');
                            $sample->addChild($xmldoc->createAttribute(name => $refResult->{sample}));
                            $experiment->addChild($sample);
                            $strSample = $refResult->{sample};
                            $probeTP->{element}->addChild($sample);
                            $probeTP->{$strSample} = $sample;
                        }
                    }
            # Replicate
                    my @arrData = split(/;/, $refResult->{data});
                    foreach my $probeTP (@arrProbeTPs)
                    {
                        my $iIndex = $probeTP->{index};
                        next if($arrData[$iIndex] eq 'NA');
                        my $replicate = $xmldoc->createElement('replicate');
                        $replicate->addChild($xmldoc->createAttribute(name => $refResult->{replicate}));
                        $replicate->addChild($xmldoc->createTextNode($arrData[$iIndex]));
                        $probeTP->{$strSample}->addChild($replicate);
                    }
            }
            $probe->addChild($experiment);
            $xmldata->addChild($probe);
        }
        return Constants::ERR_OK;
    }
}

1;
