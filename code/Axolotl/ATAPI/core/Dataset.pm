#!/usr/bin/env perl

#   File:
#       Dataset.pm
#
#   Description:
#       Contains the Dataset core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.14
#
#   Date:
#       16.01.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use File::Temp;
use Axolotl::ATAPI::Constants;


package Dataset;
{
    my $MODULE = 'Dataset';
    my $VERSION = '1.0.15';
    my $DATE = '2013-12-26';
    
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
	$self->{_quality} = $ps->getSetting('DATASET', 'quality');
	$self->{_duplication} = $ps->getSetting('DATASET', 'duplication');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the details about the dataset, such as author, tissue and some plots.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'getList',
                           _description => 'Returns the list of available datasets',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getList"},
			  
			  {_name => 'getDetails',
                           _description => 'Returns the list of available datasets',
			   _args => [{_name => 'names',
                                      _description => 'Comma-separated list of dataset names to retrieve details for. ' .
							"If no name is specified, the behavior is identical to that of $MODULE.getList",
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid dataset name is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getDetails&names=mSC",
			   _remarks => "The resulting XML only contains entries for valid dataset names."},
			  
			  {_name => 'getStatisticData',
                           _description => 'Returns the data for the specified statistic',
			   _args => [{_name => 'dataset',
                                      _description => 'Name of the dataset to retrieve statistic data for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'type',
                                      _description => "Statistic type. Must be a value returned by $MODULE.getDetails for this dataset",
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'maxcount',
                                      _description => '(only if type="duplication") maximal duplication level',
                                      _type => 'optional',
                                      _default => '25'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If either dataset name or statistic type is not specified'},
					   {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid statistic type is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid dataset name is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getStatisticData&dataset=mSC&type=quality"});
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
        if($strMethod eq 'getList')
        {
            return $self->getList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getDetails')
        {
            return $self->getDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getStatisticData')
        {
            return $self->getStatisticData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        return $self->getDetails($refParams, $xmldoc, $xmldata, $xmlerr, 1);
    }
    
    sub getDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr, $bListAll) = @_;
        my @arrDatasets = (defined $refParams->{names}) ? split(/,/, $refParams->{names}) : ();
        my $privilege = $refParams->{_user}->{privilege};
	    # Escape hyphens in the dataset names.
	    $_=~ s/'/\\'/g foreach @arrDatasets;
        $_ = "'$_'" foreach @arrDatasets;
        $bListAll = 1 if (scalar @arrDatasets)==0;
        # First, retrieve ds_id, name, description, reads, technology and tissue description.
        my $strQuery = "SELECT ds_id, ".
            			      "Dataset.name AS dsname, ".
            			      "Dataset.description AS dsdesc, ".
            			      "sortindex, ".
            			      "SRA, ".
            			      "Dataset.privilege, ".
            			      "`reads`, ".
            			      "technology, ".
            			      "paired, ".
            			      "Tissue.description AS tdesc, ".
            			      "Experiment.name AS ename, ".
            			      "Author.name AS aname, ".
            			      "Author.email AS email ".
                       "FROM Dataset ".
			                "INNER JOIN Tissue ON Dataset.t_id=Tissue.t_id ".
            			    "INNER JOIN Experiment ON Dataset.exp_id=Experiment.exp_id ".
            			    "INNER JOIN Author ON Dataset.au_id=Author.au_id";
        if(!$bListAll)
        {
            $strQuery .= " WHERE Dataset.name IN (" . join(',', @arrDatasets). ")";
        }
        my %hmFields = ('name' => {_column => 'dsname', _type => Constants::NT_ATTRIBUTE},
                        'reads' => {_column => 'reads', _type => Constants::NT_ATTRIBUTE},
                        'technology' => {_column => 'technology', _type => Constants::NT_ATTRIBUTE},
                        'sortindex' => {_column => 'sortindex', _type => Constants::NT_ATTRIBUTE},
			'SRA' => {_column => 'SRA', _type => Constants::NT_ATTRIBUTE},
                        'tissue' => {_column => 'tdesc', _type => Constants::NT_ATTRIBUTE},
                        'experiment' => {_column => 'ename', _type => Constants::NT_ATTRIBUTE},
			'author' => {_column => 'aname', _type => Constants::NT_ATTRIBUTE},
			'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE},
                        'description' => {_column => 'dsdesc', _type => Constants::NT_TEXT},
                        'type' => {_column => 'paired', _type => Constants::NT_ATTRIBUTE, _replace => {'0' => 'single-end', '1' => 'paired-end'}});
        my %hmAFields = ('name' => {_column => 'name', _type => Constants::NT_ATTRIBUTE},
                         'version' => {_column => 'version', _type => Constants::NT_ATTRIBUTE});
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
    	if($statement->rows > 0)
    	{
    	    while(my $refResult = $statement->fetchrow_hashref())
    	    {
        	    next if($privilege && ($refResult->{privilege} & $privilege != $refResult->{privilege}));
        		my $dataset = $xmldoc->createElement('dataset');
        		$self->{_fnAddNodes}->($xmldoc, $dataset, \%hmFields, $refResult);
        		# Additionally add the list of assemblies this dataset is used in.
        		my $strAQuery = "SELECT name, ".
        		                       "version ".
        				"FROM Assembly ".
        				     "INNER JOIN AssemblyComposition ON Assembly.a_id=AssemblyComposition.a_id ".
        				"WHERE AssemblyComposition.ds_id=$refResult->{ds_id};";
        		my $a_statement = $self->{_db}->prepare($strAQuery);
        		$a_statement->execute();
        		while(my $refAResult = $a_statement->fetchrow_hashref())
        		{
        		    my $assembly = $xmldoc->createElement('assembly');
        		    $self->{_fnAddNodes}->($xmldoc, $assembly, \%hmAFields, $refAResult);
        		    $dataset->addChild($assembly);
        		}
        		# Statistics.
        		my $nEntries = 0;
        		my $statistics = $xmldoc->createElement('statistics');
        		# Quality, CG content and base content.
        		if(-e "$self->{_quality}/$refResult->{dsname}/$refResult->{dsname}_left.stat")
        		{
        		    # Quality.
        		    my $statistic = $xmldoc->createElement('statistic');
        		    $statistic->addChild($xmldoc->createAttribute('type' => 'quality'));
        		    $statistic->addChild($xmldoc->createAttribute('name' => 'Quality'));
        		    $statistic->addChild($xmldoc->createAttribute('category' => 'General'));
        		    $statistic->addChild($xmldoc->createAttribute('description' => 'Average base call score along the read'));
        		    $statistics->addChild($statistic);
        		    # GC content.
        		    $statistic = $xmldoc->createElement('statistic');
        		    $statistic->addChild($xmldoc->createAttribute('type' => 'gc'));
        		    $statistic->addChild($xmldoc->createAttribute('name' => 'GC content'));
        		    $statistic->addChild($xmldoc->createAttribute('category' => 'General'));
        		    $statistic->addChild($xmldoc->createAttribute('description' => 'GC content distribution'));
        		    $statistics->addChild($statistic);
        		    # Bases content.
        		    $statistic = $xmldoc->createElement('statistic');
        		    $statistic->addChild($xmldoc->createAttribute('type' => 'bases'));
        		    $statistic->addChild($xmldoc->createAttribute('name' => 'Bases distribution'));
        		    $statistic->addChild($xmldoc->createAttribute('category' => 'General'));
        		    $statistic->addChild($xmldoc->createAttribute('description' => 'Bases distribution along the reads'));
        		    $statistics->addChild($statistic);
        		    $nEntries++;
        		}
        		# Duplication.
        		if(-e "$self->{_duplication}/$refResult->{dsname}/$refResult->{dsname}_left.dup")
        		{
        		    my $statistic = $xmldoc->createElement('statistic');
        		    $statistic->addChild($xmldoc->createAttribute('type' => 'duplication'));
        		    $statistic->addChild($xmldoc->createAttribute('name' => 'Duplication'));
        		    $statistic->addChild($xmldoc->createAttribute('category' => 'General'));
        		    $statistic->addChild($xmldoc->createAttribute('description' => 'Duplication level of the reads in the dataset'));
        		    $statistics->addChild($statistic);
        		    $nEntries++;
        		}
        		# Mapping.
        		my $strQuery_DS = "SELECT COUNT(*) AS count FROM MappingData WHERE ds_id=$refResult->{ds_id};";
        		my $refResult_DS = $self->{_db}->selectrow_hashref($strQuery_DS);
        		if($refResult_DS->{count})
        		{
        		    my $statistic = $xmldoc->createElement('statistic');
        		    $statistic->addChild($xmldoc->createAttribute('type' => 'mapping'));
        		    $statistic->addChild($xmldoc->createAttribute('name' => 'Reference mapping'));
        		    $statistic->addChild($xmldoc->createAttribute('category' => 'Mapping'));
        		    $statistic->addChild($xmldoc->createAttribute('description' => 'Proportions of mapped reads and covered contigs for different assemblies'));
        		    $statistics->addChild($statistic);
        		    $nEntries++;
        		}
        		$dataset->addChild($statistics) if $nEntries;
        		$xmldata->addChild($dataset);
    	    }
    	    return Constants::ERR_OK;
    	}
    	else
    	{
    	    $xmlerr->addChild($xmldoc->createTextNode("No valid dataset name specified"));
                return Constants::ERR_DATA_NOT_FOUND;
    	}
    }
    
    sub getStatisticData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{dataset})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No dataset name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!$refParams->{type})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No plot type specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	    my $statistic = $xmldoc->createElement('statistic');
        $statistic->addChild($xmldoc->createAttribute('dataset' => $refParams->{dataset}));
        $statistic->addChild($xmldoc->createAttribute('type' => $refParams->{type}));
    	# Quality.
    	if($refParams->{type} eq 'quality')
        {
            my @arrStrands = ('left', 'right');
            foreach (@arrStrands)
            {
                my $strFilename = "$self->{_quality}/$refParams->{dataset}/$refParams->{dataset}_$_.stat";
                next if ! -e $strFilename;
        		my $end = $xmldoc->createElement('end');
        		$end->addChild($xmldoc->createAttribute('type' => $_));
                open(IN, $strFilename);
                my $bStart = 0;
                while(my $strLine = <IN>)
                {
                    chomp($strLine);
		            next if(substr($strLine,0,1) eq '#');
                    if($strLine =~ m/>>Per base sequence quality/)
        		    {
        			 $bStart = 1;
        			 next;
        		    }
                    next unless $bStart;
                    last if $strLine =~ m/>>END_MODULE/;
                    # Parse the line content.
        		    my @arrChunks = split(/\t/, $strLine);
        		    my $range = $xmldoc->createElement('range');
        		    $range->addChild($xmldoc->createAttribute('positions' => $arrChunks[0]));
        		    $range->addChild($xmldoc->createAttribute('mean' => $arrChunks[1]));
        		    $range->addChild($xmldoc->createAttribute('median' => $arrChunks[2]));
        		    $range->addChild($xmldoc->createAttribute('quartile_25' => $arrChunks[3]));
        		    $range->addChild($xmldoc->createAttribute('quartile_75' => $arrChunks[4]));
        		    $range->addChild($xmldoc->createAttribute('percentile_10' => $arrChunks[5]));
        		    $range->addChild($xmldoc->createAttribute('percentile_90' => $arrChunks[6]));
        		    $end->addChild($range);
                }
                close(IN);
		        $statistic->addChild($end);
            }
	    $xmldata->addChild($statistic);
	}
	# CG content.
	elsif($refParams->{type} eq 'gc')
        {
            my @arrStrands = ('left', 'right');
            foreach (@arrStrands)
            {
                my $strFilename = "$self->{_quality}/$refParams->{dataset}/$refParams->{dataset}_$_.stat";
                next if ! -e $strFilename;
		my $end = $xmldoc->createElement('end');
		$end->addChild($xmldoc->createAttribute('type' => $_));
                open(IN, $strFilename);
                my $bStart = 0;
                while(my $strLine = <IN>)
                {
                    chomp($strLine);
		    next if(substr($strLine,0,1) eq '#');
                    if($strLine =~ m/>>Per sequence GC content/)
		    {
			$bStart = 1;
			next;
		    }
                    next unless $bStart;
                    last if $strLine =~ m/>>END_MODULE/;
                    # Parse the line content.
		    my @arrChunks = split(/\t/, $strLine);
		    my $content = $xmldoc->createElement('content');
		    $content->addChild($xmldoc->createAttribute('percent' => $arrChunks[0]));
		    $content->addChild($xmldoc->createAttribute('count' => $arrChunks[1]));
		    $end->addChild($content);
                }
                close(IN);
		$statistic->addChild($end);
            }
	    $xmldata->addChild($statistic);
	}
	# Bases distribution.
	elsif($refParams->{type} eq 'bases')
        {
            my @arrStrands = ('left', 'right');
            foreach (@arrStrands)
            {
                my $strFilename = "$self->{_quality}/$refParams->{dataset}/$refParams->{dataset}_$_.stat";
                next if ! -e $strFilename;
		my $end = $xmldoc->createElement('end');
		$end->addChild($xmldoc->createAttribute('type' => $_));
                open(IN, $strFilename);
                my $bStart = 0;
                while(my $strLine = <IN>)
                {
                    chomp($strLine);
		    next if(substr($strLine,0,1) eq '#');
                    if($strLine =~ m/>>Per base sequence content/)
		    {
			$bStart = 1;
			next;
		    }
                    next unless $bStart;
                    last if $strLine =~ m/>>END_MODULE/;
                    # Parse the line content.
		    my @arrChunks = split(/\t/, $strLine);
		    my $range = $xmldoc->createElement('range');
		    $range->addChild($xmldoc->createAttribute('positions' => $arrChunks[0]));
		    $range->addChild($xmldoc->createAttribute('G' => $arrChunks[1]));
		    $range->addChild($xmldoc->createAttribute('A' => $arrChunks[2]));
		    $range->addChild($xmldoc->createAttribute('T' => $arrChunks[3]));
		    $range->addChild($xmldoc->createAttribute('C' => $arrChunks[4]));
		    $end->addChild($range);
                }
                close(IN);
		$statistic->addChild($end);
            }
	    $xmldata->addChild($statistic);
	}
	elsif($refParams->{type} eq 'duplication')
        {
            use Storable;
            $refParams->{maxcount} = 25 unless $refParams->{maxcount};
            my @arrStrands = ('left', 'right', 'both');
            foreach (@arrStrands)
            {
                my $strFilename = "$self->{_duplication}/$refParams->{dataset}/$refParams->{dataset}_$_.dup";
                next if ! -e $strFilename;
		my $end = $xmldoc->createElement('end');
		$end->addChild($xmldoc->createAttribute('type' => $_));
                my %hmCounts = ();
		open(IN, $strFilename);
		my $nTotal = 0;
		while(my $strLine = <IN>)
		{
		    chomp($strLine);
		    my ($nRepeats, $nCount) = split(/\t/, $strLine, 2);
		    my $nSequences = $nRepeats*$nCount;
		    $nRepeats = $refParams->{maxcount}+1 if($nRepeats>$refParams->{maxcount});
		    $hmCounts{$nRepeats} += $nSequences;
		    $nTotal += $nSequences;
		}
		close(IN);
		foreach my $nCount (keys %hmCounts)
		{
		    my $reads = $xmldoc->createElement('reads');
		    if($nCount==($refParams->{maxcount}+1))
		    {
			$reads->addChild($xmldoc->createAttribute('copynumber' => ">$refParams->{maxcount}"));
		    }
		    else
		    {
			$reads->addChild($xmldoc->createAttribute('copynumber' => $nCount));
		    }
		    $reads->addChild($xmldoc->createAttribute('proportion' => $hmCounts{$nCount}/$nTotal));
		    $end->addChild($reads);
		}
		$statistic->addChild($end);
            }
	    $xmldata->addChild($statistic);
	}
	elsif($refParams->{type} eq 'mapping')
        {
	    my $strQuery = "SELECT Assembly.name AS name, ".
				  "Assembly.version, ".
				  "Assembly.a_id AS a_id, ".
				  "Dataset.`reads` AS nreads, ".
				  "Dataset.ds_id AS ds_id, ".
				  "mapped, ".
				  "contigs AS covered ".
			   "FROM Dataset ".
				"INNER JOIN MappingData ON MappingData.ds_id=Dataset.ds_id ".
				"INNER JOIN Assembly ON MappingData.a_id=Assembly.a_id ".
			   "WHERE Dataset.name='$refParams->{dataset}';";
	    my $nReadCount = undef;
	    my $statement = $self->{_db}->prepare($strQuery);
	    $statement->execute();
	    while(my $refResult = $statement->fetchrow_hashref())
	    {
		$nReadCount = $refResult->{nreads} if(!$nReadCount);
		my $assembly = $xmldoc->createElement('assembly');
		$assembly->addChild($xmldoc->createAttribute('name' => $refResult->{name}));
		$assembly->addChild($xmldoc->createAttribute('version' => $refResult->{version}));
		$assembly->addChild($xmldoc->createAttribute('mapped' => $refResult->{mapped}));
		$assembly->addChild($xmldoc->createAttribute('covered' => $refResult->{covered}));
		# Retrieve the number of reads from the current dataset used for the current assembly.
		my ($nReads) = $self->{_db}->selectrow_array("SELECT `reads` ".
							     "FROM AssemblyComposition ".
							     "WHERE a_id=$refResult->{a_id} AND ds_id=$refResult->{ds_id};");
		$nReads = 0 if(!$nReads);
		$assembly->addChild($xmldoc->createAttribute('used' => "$nReads"));
		# Count the contigs in the assembly.
		my ($nCount) = $self->{_db}->selectrow_array("SELECT COUNT(*) FROM Contig WHERE a_id=$refResult->{a_id};");
		$assembly->addChild($xmldoc->createAttribute('contigs' => $nCount));
		$statistic->addChild($assembly);
	    }
	    $statistic->addChild($xmldoc->createAttribute('reads' => $nReadCount));
	    $xmldata->addChild($statistic);
	}
	else
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid plot type specified"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        return Constants::ERR_OK;
    }

}

1;
