#!/usr/bin/env perl

#   File:
#       TimeCourse.pm
#
#   Description:
#       Contains the TimeCourse analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.2.1
#
#   Date:
#       14.07.2015
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use File::Temp;
use Storable;

use Axolotl::ATAPI::Constants;


package TimeCourse;
{
    my $MODULE = 'TimeCourse';
    my $VERSION = '1.2.1';
    my $DATE = '2015-07-14';
    
    my $PROFILES_COUNT = 25;
    
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
	$self->{_distances} = $ps->getSetting('TIMECOURSE', 'distances');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the data related to time-course expression profiles of the sequences.";
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
                           _description => 'Returns the detailed information about the time-course experiment',
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
                           _sample => "$refParams->{_base}/api?method=$MODULE.getExperimentDetails&experiments=20"},
                          
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
			  
			  {_name => 'listExperimentsForProbes',
                           _description => 'Returns the list of experiments for each specified probe',
                           _args => [{_name => 'probes',
                                      _description => 'Comma-separated list of probe names to retrieve experiments for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no probe name is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listExperimentsForProbes&probes=$strExampleProbe"},
			  
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
                           _sample => "$refParams->{_base}/api?method=$MODULE.getProbeData&probes=$strExampleProbe&experiment=19"},
			  
			  {_name => 'findSimilarProfiles',
                           _description => 'Returns the list of probes with the similar profiles in the specified experiment',
                           _args => [{_name => 'probe',
                                      _description => 'Probe name to retrieve similar profiles for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'experiment',
                                      _description => "Experiment ID",
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'measure',
                                      _description => "Measure name. Must be one of the values returned by $MODULE.listSimilarityMeasures",
                                      _type => 'optional',
                                      _default => 'euclidean'},
				     {_name => 'count',
                                      _description => "Number of profiles to return",
                                      _type => 'optional',
                                      _default => '25'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no probe name or no experiment ID is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If the experiment with the specified ID does not exist'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.findSimilarProfiles&probe=$strExampleProbe&experiment=19"},
			  
			  {_name => 'listSimilarityMeasures',
                           _description => 'Returns the list of supported measures to estimate the similarity between two profiles',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.listSimilarityMeasures"});
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
	elsif($strMethod eq 'listExperimentsForProbes')
        {
            return $self->listExperimentsForProbes($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getProbeData')
        {
            return $self->getProbeData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'findSimilarProfiles')
        {
            return $self->findSimilarProfiles($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'listSimilarityMeasures')
        {
            return $self->listSimilarityMeasures($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
        my $strQuery_MA = 'SELECT DISTINCT Experiment.name AS experiment, ' .
                                          'Experiment.description AS description, ' .
                                          'TCExperiment.date AS date, ' .
                                          'TCExperiment.timepoints AS tp, '.
                                          'Experiment.exp_id AS id, '.
                                          'Experiment.privilege AS privilege, '.
                                          'Author.name AS author ' .
                          'FROM TCExperiment '.
                               'INNER JOIN Experiment ON TCExperiment.exp_id=Experiment.exp_id '.
                               'INNER JOIN Author ON TCExperiment.au_id=Author.au_id '.
                               'INNER JOIN TCMicroarrayData ON TCExperiment.tce_id=TCMicroarrayData.tce_id '.
                               'INNER JOIN MicroarrayProbe ON TCMicroarrayData.map_id=MicroarrayProbe.map_id '.
                               'INNER JOIN MicroarrayProbeMapping ON MicroarrayProbe.map_id=MicroarrayProbeMapping.map_id '.
                          'WHERE MicroarrayProbeMapping.seq_id=? AND MicroarrayProbeMapping.st_id=?';
        my $strQuery_NGS = 'SELECT DISTINCT Experiment.name AS experiment, ' .
                                           'Experiment.description AS description, ' .
                                           'TCExperiment.date AS date, ' .
                                           'TCExperiment.timepoints AS tp, '.
                                           'Experiment.exp_id AS id, ' .
                                           'Experiment.privilege AS privilege, '.
                                           'Author.name AS author ' .
                           'FROM TCExperiment '.
                                'INNER JOIN Experiment ON TCExperiment.exp_id=Experiment.exp_id '.
                                'INNER JOIN Author ON TCExperiment.au_id=Author.au_id '.
                                'INNER JOIN TCRNASeqData ON TCExperiment.tce_id=TCRNASeqData.tce_id '.
                           'WHERE TCRNASeqData.seq_id=? AND TCRNASeqData.st_id=?';
        my @arrExperiments = ({_category => 'Microarray experiments', _query => $strQuery_MA},
			                  {_category => 'RNA-seq experiments', _query => $strQuery_NGS});
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
            my $nExperiments = 0;

            #print "Content-type: text/html\n\n<pre>";
            #print "TEST\n";
            #use Data::Dumper;

            foreach my $exp (@arrExperiments)
            {
                my $statement = $self->{_db}->prepare($exp->{_query});
                $statement->execute($seq_id, $st_id);
                my $category = $xmldoc->createElement('category');
                $category->addChild($xmldoc->createAttribute(name => $exp->{_category}));
                my $refResult = $statement->fetchrow_hashref();
                my $nAdded = 0;
                while($refResult)
                {
                    #print Dumper $refResult;
                    if(($refResult->{privilege} == 0) || (($refResult->{privilege} & $privilege) == $refResult->{privilege}))
                    {
                        my $experiment = $xmldoc->createElement('experiment');
                        $experiment->addChild($xmldoc->createAttribute(name => $refResult->{experiment}));
                        $experiment->addChild($xmldoc->createAttribute(date => $refResult->{date}));
                        $experiment->addChild($xmldoc->createAttribute(author => $refResult->{author}));
                        $experiment->addChild($xmldoc->createAttribute(id => $refResult->{id}));
                        $experiment->addChild($xmldoc->createAttribute(timepoints => scalar(split(/;/, $refResult->{tp}))));
                        $experiment->addChild($xmldoc->createTextNode($refResult->{description}));
                        $category->addChild($experiment);
                        $nAdded++;
                    }
                    $refResult = $statement->fetchrow_hashref();
                }
                if($nAdded > 0) {
                  $sequence->addChild($category);
                  $nExperiments++;
                }
            }
            $xmldata->addChild($sequence) if $nExperiments>0;
            #exit(0);
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
        my $strQuery = 'SELECT DISTINCT Experiment.name AS experiment, ' .
                                       'Experiment.description AS description, ' .
                                       'TCExperiment.date AS date, ' .
                                       'TCExperiment.timepoints AS timepoints, '.
                                       'TCExperiment.labels AS labels, '.
                                       'Experiment.exp_id AS id, '.
                                       'Experiment.details AS details, '.
                                       'Author.name AS author ' .
                       'FROM TCExperiment '.
                            'INNER JOIN Experiment ON TCExperiment.exp_id=Experiment.exp_id '.
                            'INNER JOIN Author ON TCExperiment.au_id=Author.au_id '.
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
            my $timepoints = $xmldoc->createElement('timepoints');
            my @arrTP = split(/;/, $refResult->{timepoints});
            my @arrLabels = split(/;/, $refResult->{labels});
            for(my $i=0;$i<(scalar @arrTP);$i++)
            {
                my $timepoint = $xmldoc->createElement('timepoint');
                $timepoint->addChild($xmldoc->createAttribute(time => $arrTP[$i]));
                $timepoint->addChild($xmldoc->createAttribute(label => $arrLabels[$i]));
                $timepoints->addChild($timepoint);
            }
            $experiment->addChild($timepoints);
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
                              "labels, ".
                              "timepoints, ".
			      "ExperimentType.name AS type, ".
			      "TCExperiment.tce_id AS tce_id ".
                       "FROM Experiment ".
                              "INNER JOIN TCExperiment ON Experiment.exp_id=TCExperiment.exp_id ".
			      "INNER JOIN ExperimentType ON Experiment.et_id=ExperimentType.et_id ".
                       "WHERE Experiment.exp_id=$strExpID";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid timecourse experiment ID: '$strExpID'"));
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
  	    $xmlerr->addChild($xmldoc->createTextNode("No timecourse data found for the specified sequence and experiment"));
  	    return Constants::ERR_DATA_NOT_FOUND;
  	}
  	else
  	{
  	    if(lc($refResult->{type}) eq 'microarray')
  	    {
  		return $self->getMicroarrayExperimentData($xmldoc, $xmldata, $xmlerr, {sequence => $sequence,
  										       experiment => $experiment,
  										       seq_id => $seq_id,
  										       st_id => $st_id,
  										       tce_id => $refResult->{tce_id},
  										       timepoints => $refResult->{timepoints},
  										       labels => $refResult->{labels}});
  	    }
  	    if(lc($refResult->{type}) eq 'sequencing')
  	    {
  		    return $self->getNGSExperimentData($xmldoc, $xmldata, $xmlerr, {sequence => $sequence,
  										experiment => $experiment,
  										seq_id => $seq_id,
  										st_id => $st_id,
  										tce_id => $refResult->{tce_id},
  										timepoints => $refResult->{timepoints},
  										labels => $refResult->{labels}});
  	    }
  	    else
  	    {
  		    return Constants::ERR_OK;
  	    }
  	}
  }
	
	
    sub getMicroarrayExperimentData
    {
        my ($self, $xmldoc, $xmldata, $xmlerr, $refParams) = @_;
        my @arrTP = split(/;/, $refParams->{timepoints});
        my @arrLabels = split(/;/, $refParams->{labels});
        my $nTP = scalar @arrTP;
        my $strQuery = "SELECT sample, ".
                              "replicate, ".
                              "data, ".
                              "MicroarrayProbe.name AS probe, ".
                              "MicroarrayProbe.strand AS strand ".
                       "FROM TCMicroarrayData ".
                            "INNER JOIN MicroarrayProbeMapping ON MicroarrayProbeMapping.map_id=TCMicroarrayData.map_id ".
                            "INNER JOIN MicroarrayProbe ON MicroarrayProbeMapping.map_id=MicroarrayProbe.map_id ".
                       "WHERE TCMicroarrayData.tce_id=$refParams->{tce_id} ".
		                        "AND MicroarrayProbeMapping.seq_id=$refParams->{seq_id} ".
			                      "AND MicroarrayProbeMapping.st_id=$refParams->{st_id} ".
                       "GROUP BY data ".
                       "ORDER BY probe, sample, replicate";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        my $refResult = $statement->fetchrow_hashref();
        if($refResult)
        {
            $refParams->{experiment}->addChild($xmldoc->createAttribute(type => 'microarray'));
            my %hmStrands = ('U' => 'unknown strand',
                             'S' => 'sense strand',
                             'A' => 'antisense strand');
            my $item = undef;
            my $strProbe = '';
            my $sample = undef;
            my $strSample = '';
            my @arrProbeTPs = ();
            while($refResult)
            {
                # Probe
                if($strProbe ne $refResult->{probe})
                {
                    $item = $xmldoc->createElement('item');
                    $item->addChild($xmldoc->createAttribute(type => 'microarray probe'));
                    $item->addChild($xmldoc->createAttribute(name => $refResult->{probe}));
                    $item->addChild($xmldoc->createAttribute(details => $hmStrands{$refResult->{strand}}));
                    $item->addChild($xmldoc->createAttribute(unit => 'Intensity'));
                    $item->addChild($xmldoc->createAttribute(scale => 'log2'));
                    $refParams->{experiment}->addChild($item);
                    $strProbe = $refResult->{probe};
                    $strSample = '';
                    @arrProbeTPs = ();
                    for(my $i=0;$i<$nTP;$i++)
                    {
                        my $timepoint = $xmldoc->createElement('timepoint');
                        $timepoint->addChild($xmldoc->createAttribute(time => $arrTP[$i]));
                        $timepoint->addChild($xmldoc->createAttribute(label => $arrLabels[$i]));
                        $item->addChild($timepoint);
                        push(@arrProbeTPs, {timepoint => $arrTP[$i],
					                                  element => $timepoint,
					                                  index => $i});
                    }
                }
                # Sample
                if($strSample ne $refResult->{sample})
                {
                    foreach my $probeTP (@arrProbeTPs)
                    {
                        $sample = $xmldoc->createElement('sample');
                        $sample->addChild($xmldoc->createAttribute(name => $refResult->{sample}));
                        $item->addChild($sample);
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
                    my $replicate = $xmldoc->createElement('replicate');
                    $replicate->addChild($xmldoc->createAttribute(name => $refResult->{replicate}));
                    $replicate->addChild($xmldoc->createAttribute(value => $arrData[$iIndex]));
                    $probeTP->{$strSample}->addChild($replicate);
                }
                $refResult = $statement->fetchrow_hashref();
            }
            $xmldata->addChild($refParams->{sequence});
        }
        return Constants::ERR_OK;
    }
    
    sub getNGSExperimentData
    {
        my ($self, $xmldoc, $xmldata, $xmlerr, $refParams) = @_;
        my @arrTP = split(/;/, $refParams->{timepoints});
        my @arrLabels = split(/;/, $refParams->{labels});
        my $nTP = scalar @arrTP;
        my $strQuery = "SELECT sample, ".
                              "replicate, ".
                              "data ".
                       "FROM TCRNASeqData ".
                       "WHERE tce_id=$refParams->{tce_id} ".
		                         "AND seq_id=$refParams->{seq_id} ".
			                       "AND st_id=$refParams->{st_id} ".
                       "ORDER BY sample, replicate";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
	my $refResult = $statement->fetchrow_hashref();
	if($refResult)
	{
	    $refParams->{experiment}->addChild($xmldoc->createAttribute(type => 'RNAseq'));
	    my $item = $xmldoc->createElement('item');
	    $item->addChild($xmldoc->createAttribute(unit => 'FPKM'));
      $item->addChild($xmldoc->createAttribute(scale => 'raw'));
	    $refParams->{experiment}->addChild($item);
	    my $sample = undef;
	    my $strSample = '';
	    my @arrProbeTPs = ();
	    for(my $i=0;$i<$nTP;$i++)
	    {
		my $timepoint = $xmldoc->createElement('timepoint');
		$timepoint->addChild($xmldoc->createAttribute(time => $arrTP[$i]));
		$timepoint->addChild($xmldoc->createAttribute(label => $arrLabels[$i]));
		$item->addChild($timepoint);
		push(@arrProbeTPs, {timepoint => $arrTP[$i], element => $timepoint, index => $i});
	    }
	    while($refResult)
	    {
		# Sample
		if($strSample ne $refResult->{sample})
		{
		    foreach(@arrProbeTPs)
		    {
			$sample = $xmldoc->createElement('sample');
			$sample->addChild($xmldoc->createAttribute(name => $refResult->{sample}));
			$item->addChild($sample);
			$strSample = $refResult->{sample};
			$_->{element}->addChild($sample);
			$_->{$strSample} = $sample;
		    }
		}
		# Replicate
		my @arrData = split(/;/, $refResult->{data});
		foreach(@arrProbeTPs)
		{
		    my $iIndex = $_->{index};
		    next if($arrData[$iIndex] eq 'NA');
		    my $replicate = $xmldoc->createElement('replicate');
		    $replicate->addChild($xmldoc->createAttribute(name => $refResult->{replicate}));
        $replicate->addChild($xmldoc->createAttribute(value => $arrData[$iIndex]));
		    $_->{$strSample}->addChild($replicate);
		}
		$refResult = $statement->fetchrow_hashref();   
	    }
	    $xmldata->addChild($refParams->{sequence});
	}
	return Constants::ERR_OK;
    }
    
    sub listExperimentsForProbes
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my @arrProbes = (defined $refParams->{probes}) ? split(/,/, $refParams->{probes}) : ();
        if((scalar @arrProbes)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No probe name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my $strQuery = "SELECT DISTINCT(Experiment.name), ".
	                      "Experiment.description, ".
			      "Experiment.exp_id AS id, ".
			      "TCExperiment.date AS date, ".
			      "Author.name AS author ".
		       "FROM TCMicroarrayData ".
			    "INNER JOIN TCExperiment ON TCExperiment.tce_id=TCMicroarrayData.tce_id ".
			    "INNER JOIN Experiment ON TCExperiment.exp_id=Experiment.exp_id ".
			    "INNER JOIN MicroarrayProbe ON TCMicroarrayData.map_id=MicroarrayProbe.map_id ".
			    "INNER JOIN Author ON TCExperiment.au_id=Author.au_id ".
		       "WHERE MicroarrayProbe.name = ?";
	my $statement = $self->{_db}->prepare($strQuery);
	foreach my $strProbe (@arrProbes)
	{
	    $statement->execute($strProbe);
	    next if($statement->rows==0);
	    my $probe = $xmldoc->createElement('probe');
            $probe->addChild($xmldoc->createAttribute(name => $strProbe));
	    while(my $refResult = $statement->fetchrow_hashref())
	    {
		my $experiment = $xmldoc->createElement('experiment');
		$experiment->addChild($xmldoc->createAttribute(name => $refResult->{name}));
		$experiment->addChild($xmldoc->createAttribute(id => $refResult->{id}));
		$experiment->addChild($xmldoc->createAttribute(date => $refResult->{date}));
		$experiment->addChild($xmldoc->createAttribute(author => $refResult->{author}));
		$experiment->addChild($xmldoc->createTextNode($refResult->{description}));
		$probe->addChild($experiment);
	    }
	    $xmldata->addChild($probe);
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
    
    sub findSimilarProfiles
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{probe})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No probe name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$refParams->{probe} =~ s/'/\\'/g;
	my $strExpID = $refParams->{experiment};
        if(!$strExpID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No experiment ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strExpID =~ s/'/\\'/g;
	my $strQuery = "SELECT Experiment.name, ".
			      "TCExperiment.tce_id AS tce_id ".
                       "FROM Experiment ".
                              "INNER JOIN TCExperiment ON Experiment.exp_id=TCExperiment.exp_id ".
			      "INNER JOIN ExperimentType ON Experiment.et_id=ExperimentType.et_id ".
                       "WHERE Experiment.exp_id=$strExpID";
        my ($strExpName, $tce_id) = $self->{_db}->selectrow_array($strQuery);
	if(!$tce_id)
	{
	    $xmlerr->addChild($xmldoc->createTextNode("The specified experiment does not exist"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
	}
	$refParams->{measure} = 'euclidean' unless $refParams->{measure};
	my @arrMeasures = ('euclidean', 'deviation', 'angle');
	if(!grep(/^$refParams->{measure}$/, @arrMeasures))
	{
	    $refParams->{measure} = 'euclidean';
	}
	$refParams->{count} = $PROFILES_COUNT if(!(int($refParams->{count})));
	my $probe = $xmldoc->createElement('probe');
        $probe->addChild($xmldoc->createAttribute(name => $refParams->{probe}));
	$probe->addChild($xmldoc->createAttribute(measure => $refParams->{measure}));
	my $experiment = $xmldoc->createElement('experiment');
	$experiment->addChild($xmldoc->createAttribute(name => $strExpName));
	$experiment->addChild($xmldoc->createAttribute(id => $strExpID));
	my $strRoot = "$self->{_distances}/$tce_id";
	my $hDir = undef;
	opendir($hDir, $strRoot);
	foreach my $strSample (grep {-d "$strRoot" && ! /^\.{1,2}$/ && ! /^data\.dat$/} readdir($hDir))
	{
	    my $sample = $xmldoc->createElement('sample');
	    $sample->addChild($xmldoc->createAttribute(name => $strSample));
	    my $strFilename = "$strRoot/$strSample/$refParams->{probe}.dat";
	    next if(! -e $strFilename);
	    my $refData = Storable::retrieve($strFilename);
	    my @arrData = splice(@{$refData}, 0, $refParams->{count});
	    foreach my $refProbe (@arrData)
	    {
		my $probe = $xmldoc->createElement('probe');
		$probe->addChild($xmldoc->createAttribute(name => $refProbe->{probe}));
		$probe->addChild($xmldoc->createAttribute(sample => $refProbe->{sample}));
		$probe->addChild($xmldoc->createAttribute(distance => $refProbe->{distance}));
		$sample->addChild($probe);
	    }
	    $experiment->addChild($sample);
	}
	closedir($hDir);
	$probe->addChild($experiment);
	$xmldata->addChild($probe);
	return Constants::ERR_OK;
    }
    
    sub listSimilarityMeasures
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my @arrMeasures = ({name => 'Euclidean',
			    value => 'euclidean',
			    description => 'Estimates the distance between two probes as Euclidean distance'},
			   {name => 'Shifted Euclidean',
			    value => 'deviation',
			    description => 'Estimates the distance between two probes as Euclidean distance, '.
			                   'but shifts the second probe in a way that both profiles virtually start at the same value'},
			   {name => 'Angle',
			    value => 'angle',
			    description => 'For each timepoint calculates the angle between the line connecting the previous and the current '.
			                   'timepoints and the perpendicular, and estimates the distance as Euclidean distance of the angle values'});
	my $measures = $xmldoc->createElement('measures');
	foreach my $refMeasure (@arrMeasures)
	{
	    my $measure = $xmldoc->createElement('measure');
	    $measure->addChild($xmldoc->createAttribute(name => $refMeasure->{name}));
	    $measure->addChild($xmldoc->createAttribute(sample => $refMeasure->{value}));
	    $measure->addChild($xmldoc->createTextNode($refMeasure->{description}));
	    $measures->addChild($measure);
	}
	$xmldata->addChild($measures);
	return Constants::ERR_OK;
    }
}

1;
