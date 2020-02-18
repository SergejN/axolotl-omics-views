#!/usr/bin/env perl

#   File:
#       Assembly.pm
#
#   Description:
#       Contains the Assembly core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.15
#
#   Date:
#       16.01.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use IO::Compress::Gzip qw(gzip);

use Axolotl::ATAPI::Constants;


package Assembly;
{
    my $MODULE = 'Assembly';
    my $VERSION = '1.0.17';
    my $DATE = '2014-29-05';
    
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
      	$self->{_rootdir} = $ps->getSetting('ASSEMBLY', 'root');
      	$self->{_zipdir} = $ps->getSetting('ASSEMBLY', 'downloads');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the details about the assembly such as assemblies list, contigs count, creation date and the datasets included.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'getList',
                           _description => 'Returns the list of assemblies and the types of available plots',
			   _args => [{_name => 'values',
                                      _description => 'Comma-separated list of values to retrieve. Must be combination of "description", "contigs", "date", "datasets", and "statistics" or empty',
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getList&values=description,contigs,date,datasets"},
			  
			  {_name => 'getLatest',
                           _description => 'Returns the name, version and the types of available plots of the latest assembly',
			   _args => [{_name => 'values',
                                      _description => 'Comma-separated list of values to retrieve. Must be combination of "description", "contigs", "date", "datasets", and "statistics" or empty',
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getLatest&values=description,contigs,date,datasets"},
			  
			  {_name => 'getDetails',
                           _description => 'Returns the name, version, datasets used and the types of available plots for the specified assembly',
			   _args => [{_name => 'assemblies',
                                      _description => 'Comma-separated list of assembly versions to retrieve details for. ' .
							"If no version is specified, the behavior is identical to that of $MODULE.getList",
                                      _type => 'optional',
                                      _default => ''},
				     {_name => 'values',
                                      _description => 'Comma-separated list of additional values to retrieve. Must be combination of "description", "contigs", "date", "datasets", and "statistics" or empty',
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid value is specified in "values" argument or no valid assembly version is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getDetails&assemblies=10&values=description,contigs,date,datasets",
			   _remarks => "The resulting XML only contains entries for valid assembly versions."},
			  
			  {_name => 'getStatisticData',
                           _description => 'Returns the data for the specified statistic',
			   _args => [{_name => 'assembly',
                                      _description => 'Assembly version to retrieve statistic data for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'type',
                                      _description => "Statistic type. Must be a value returned by $MODULE.getDetails for this assembly version",
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'maxlen',
                                      _description => "For ORF and sequence length distribution only. Specifies the maximal length value, after which the counts are summed up",
                                      _type => 'optional',
                                      _default => '5000'},
				     {_name => 'binsize',
                                      _description => "For ORF and sequence length distribution only. Specifies the bin size. Default is 20",
                                      _type => 'optional',
                                      _default => '20'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If either assembly version or statistic type is not specified'},
					   {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid statistic type is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid assembly version is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getStatisticData&assembly=10&type=cg"},
			  
			  {_name => 'getSequences',
                           _description => 'Returns the compressed (ZIP) file containing the requested sequence and annotation data.',
			   _args => [{_name => 'assembly',
                                      _description => 'The assembly version to retrieve details for.',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'type',
                                      _description => 'Type of the data to be fetched. Must be either "dna" or "protein"',
                                      _type => 'required',
                                      _default => 'dna'},
				     {_name => 'fasta',
                                      _description => 'Format of the output FASTA file. Can only be "ncbi" in the current version. '.
				                      'Causes the file to be formatted properly according to NCBI specifications.',
                                      _type => 'optional'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid value is specified in "type" argument'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If the assembly version is not specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid assembly version is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getSequences&assembly=10&type=dna"});
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
        elsif($strMethod eq 'getLatest')
        {
            return $self->getLatest($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getDetails')
        {
            return $self->getDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getStatisticData')
        {
            return $self->getStatisticData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getSequences')
        {
            return $self->getSequences($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    # Private module methods.
    sub getList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        return $self->getDetails($refParams, $xmldoc, $xmldata, $xmlerr, 1);
    }
    
    sub getLatest
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my $strQuery = "SELECT MAX(version) AS version FROM Assembly;";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        return $self->getDetails({assemblies => $refResult->{'version'}, values => $refParams->{values}}, $xmldoc, $xmldata, $xmlerr);
    }
    
    sub getDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr, $bListAll) = @_;
        my @arrAssemblies = (defined $refParams->{assemblies}) ? split(/,/, $refParams->{assemblies}) : ();
	# Escape hyphens in the dataset names.
	$_=~ s/'/\\'/g foreach @arrAssemblies;
        $bListAll = 1 if((scalar @arrAssemblies)==0);
        my @arrValues = ($refParams->{values} && length($refParams->{values})>0) ? split(/,/, $refParams->{values}) : ();
        # Get the a_id of the latest assembly.
	my $strQuery = "SELECT a_id FROM Assembly WHERE version=(SELECT MAX(version) FROM Assembly);";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        my $a_id_last = $refResult->{'a_id'};
        # Select version, name, description and date from the Assembly table.
        my %hmFields = ('version' => {_column => 'version', _type => Constants::NT_ATTRIBUTE},
                        'name' => {_column => 'name', _type => Constants::NT_ATTRIBUTE},
			'author' => {_column => 'author', _type => Constants::NT_ATTRIBUTE},
			'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE},
                        'latest' => {_column => 'latest', _type => Constants::NT_ATTRIBUTE, _replace => {'0' => 'false', '1' => 'true'}});
        my $bGetDatasets = 0;
	my $bGetStatistics = 0;
        foreach (@arrValues)
        {
            if(lc($_) eq 'description')
            {
                $hmFields{'description'} = {_column => 'description', _type => Constants::NT_TEXT};
            }
            elsif(lc($_) eq 'contigs')
            {
                $hmFields{'contigs'} = {_column => 'contigs', _type => Constants::NT_ATTRIBUTE};
		$hmFields{'annotated'} = {_column => 'annotated', _type => Constants::NT_ATTRIBUTE};
		$hmFields{'ORFs'} = {_column => 'orfs', _type => Constants::NT_ATTRIBUTE};
		$hmFields{'domains'} = {_column => 'domains', _type => Constants::NT_ATTRIBUTE};
            }
            elsif(lc($_) eq 'date')
            {
                $hmFields{'date'} = {_column => 'date', _type => Constants::NT_ATTRIBUTE};
            }
            elsif(lc($_) eq 'datasets')
            {
                $bGetDatasets = 1;
            }
	    elsif(lc($_) eq 'statistics')
            {
                $bGetStatistics = 1;
            }
            else
            {
                $xmlerr->addChild($xmldoc->createTextNode("Invalid parameter: '$_'"));
                return Constants::ERR_INVALID_PARAMETER;
            }
        }
        $strQuery = ($bListAll) ? "SELECT a_id, ".
					 "Assembly.name AS name, ".
					 "version, ".
					 "description, ".
					 "contigs, ".
					 "annotated, ".
					 "orfs, ".
					 "domains, ".
					 "date, ".
					 "Author.name AS author, ".
					 "email ".
				  "FROM Assembly ".
				       "INNER JOIN Author ON Assembly.au_id=Author.au_id;"
				: "SELECT a_id, ".
				         "Assembly.name AS name, ".
					 "version, ".
					 "description, ".
					 "contigs, ".
					 "annotated, ".
					 "orfs, ".
					 "domains, ".
					 "date, ".
					 "Author.name AS author, ".
					 "email ".
				  "FROM Assembly ".
				       "INNER JOIN Author ON Assembly.au_id=Author.au_id ".
				  "WHERE version IN (" . join(',', @arrAssemblies) .");";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
	if($statement->rows>0)
	{
	    while(my $refResult = $statement->fetchrow_hashref())
	    {
		# Create new XML entry.
		my $assembly = $xmldoc->createElement('assembly');
		my $iVersion = $refResult->{version};
		$refResult->{'latest'} = 1 if($refResult->{a_id}==$a_id_last);
		$self->{_fnAddNodes}->($xmldoc, $assembly, \%hmFields, $refResult);
		if($bGetDatasets)
		{
		    my $strDSQuery = "SELECT Dataset.name AS dsname, ".
					    "Dataset.description AS dsdesc, ".
					    "Dataset.reads AS dsreads ".
				     "FROM Assembly ".
					  "INNER JOIN AssemblyComposition ON Assembly.a_id=AssemblyComposition.a_id ".
					  "INNER JOIN Dataset ON Dataset.ds_id=AssemblyComposition.ds_id ".
				     "WHERE Assembly.a_id=$refResult->{'a_id'};";
		    my $ds_statement = $self->{_db}->prepare($strDSQuery);
		    $ds_statement->execute();
		    while(my $refDSResult = $ds_statement->fetchrow_hashref())
		    {
			my $dataset = $xmldoc->createElement('dataset');
			my %hmDSFields = ('name' => {_column => 'dsname', _type => Constants::NT_ATTRIBUTE},
					  'description' => {_column => 'dsdesc', _type => Constants::NT_TEXT},
					  'reads' => {_column => 'dsreads', _type => Constants::NT_ATTRIBUTE});
			$self->{_fnAddNodes}->($xmldoc, $dataset, \%hmDSFields, $refDSResult);
			$assembly->addChild($dataset);
		    }
		}
		if($bGetStatistics)
		{
		    # Available statistics.
		    my $statistics = $xmldoc->createElement('statistics');
		    addStatisticEntry($xmldoc, $statistics, 'gc', 'GC content', 'GC content distribution', 'General') if(-e "$self->{_rootdir}/Am_$iVersion/$iVersion"."_GC.stats");
		    addStatisticEntry($xmldoc, $statistics, 'codons', 'Codon usage', 'Codon usage table', 'General') if(($self->{_db}->selectrow_hashref("SELECT COUNT(*) AS count FROM CodonUsage WHERE a_id=$refResult->{'a_id'};"))->{count});
		    addStatisticEntry($xmldoc, $statistics, 'orf', 'ORF types', 'Distribution of ORF types', 'Annotation');
		    addStatisticEntry($xmldoc, $statistics, 'refseqcov', 'RefSeq coverage', 'Coverage of reference transcriptomes (RefSeq)', 'Annotation');
		    addStatisticEntry($xmldoc, $statistics, 'moltype', 'Molecule types', 'Distribution of molecule types', 'Annotation');
		    addStatisticEntry($xmldoc, $statistics, 'seqlen', 'Sequence length', 'Sequence length distribution', 'Distribution');
		    addStatisticEntry($xmldoc, $statistics, 'orflen', 'ORF length', 'ORF length distribution', 'Distribution');
		    $assembly->addChild($statistics);
		}
		$xmldata->addChild($assembly);
	    }
	    return Constants::ERR_OK;
	}
	else
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No valid assembly version specified"));
            return Constants::ERR_INVALID_PARAMETER;
	}
    }
    
    sub addStatisticEntry
    {
	my ($xmldoc, $statistics, $strType, $strName, $strDescription, $strCategory) = @_;
	my $statistic = $xmldoc->createElement('statistic');
	$statistic->addChild($xmldoc->createAttribute('category' => $strCategory));
	$statistic->addChild($xmldoc->createAttribute('type' => $strType));
        $statistic->addChild($xmldoc->createAttribute('name' => $strName));
	$statistic->addChild($xmldoc->createAttribute('description' => $strDescription));
	$statistics->addChild($statistic);
    }
    
    sub getStatisticData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{assembly})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No assembly specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!$refParams->{type})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No statistic type specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT a_id FROM Assembly WHERE version=$refParams->{assembly};";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified assembly does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
	my $a_id = $refResult->{a_id};
	my $statistic = $xmldoc->createElement('statistic');
        $statistic->addChild($xmldoc->createAttribute('assembly' => $refParams->{assembly}));
        $statistic->addChild($xmldoc->createAttribute('type' => $refParams->{type}));
	if($refParams->{type} eq 'orf')
	{
	    getORFTypeData($xmldoc, $statistic, $self->{_db}, $a_id);
	}
	elsif($refParams->{type} eq 'gc')
	{
	    my $strFilename = "$self->{_rootdir}/Am_$refParams->{assembly}/$refParams->{assembly}_GC.stats";
            if(! -e $strFilename)
	    {
		$xmlerr->addChild($xmldoc->createTextNode("No GC statistics available for the specified assembly"));
		return Constants::ERR_DATA_NOT_FOUND;
	    }
	    getGCContentData($xmldoc, $statistic, $strFilename);
	}
	elsif($refParams->{type} eq 'codons')
	{
	    getCodonUsageData($xmldoc, $statistic, $self->{_db}, $a_id);
	}
	elsif(($refParams->{type} eq 'seqlen') || ($refParams->{type} eq 'orflen'))
	{
	    getLengthDistrData($xmldoc, $statistic, $self->{_db}, $a_id, $refParams);
	}
	elsif($refParams->{type} eq 'refseqcov')
	{
	    getRefSeqCoverageData($xmldoc, $statistic, $self->{_db}, $a_id);
	}
	elsif($refParams->{type} eq 'moltype')
	{
	    getMoleculeTypesDistributionData($xmldoc, $statistic, $self->{_db}, $a_id);
	}
	else
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid statistic type specified"));
            return Constants::ERR_INVALID_PARAMETER;
        }
	$xmldata->addChild($statistic);
        return Constants::ERR_OK;
    }
    
    sub getORFTypeData
    {
	my ($xmldoc, $statistic, $hDB, $a_id) = @_;
	# Total number of ORFs.
	my $strQuery = "SELECT COUNT(*) AS count ".
		       "FROM Contig ".
			    "INNER JOIN ORF ON Contig.c_id=ORF.c_id ".
		       "WHERE Contig.a_id=$a_id;";
	my $refResult = $hDB->selectrow_hashref($strQuery);
	my $nTotal = $refResult->{count};
	# Predicted.
	$strQuery = "SELECT ORFType.name AS name, ".
			   "COUNT(*) AS count ".
		    "FROM Contig ".
			 "INNER JOIN ORF ON Contig.c_id=ORF.c_id ".
			 "INNER JOIN ORFType ON ORF.orft_id=ORFType.orft_id ".
		    "WHERE Contig.a_id=$a_id GROUP BY ORFType.orft_id;";
	my $statement = $hDB->prepare($strQuery);
	$statement->execute();
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $orf = $xmldoc->createElement('orf');
	    $orf->addChild($xmldoc->createAttribute('type' => $refResult->{name}));
	    $orf->addChild($xmldoc->createAttribute('count' => $refResult->{count}));
	    $orf->addChild($xmldoc->createAttribute('fraction' => $refResult->{count}/$nTotal));
	    $statistic->addChild($orf);
	}
    }
    
    sub getGCContentData
    {
	my ($xmldoc, $statistic, $strFilename) = @_;
	open(IN, $strFilename);
	my @arrResult = (0)x101;
	while(<IN>)
	{
	    last if(substr($_,0,1) eq '=');
	    chomp();
	    my ($nContent, $nCount) = split(/\t/, $_);
	    $arrResult[$nContent] = $nCount;
	}
	for(my $nContent=0;$nContent<101;$nContent++)
	{
	    my $content = $xmldoc->createElement('content');
	    $content->addChild($xmldoc->createAttribute('percent' => $nContent));
	    $content->addChild($xmldoc->createAttribute('count' => $arrResult[$nContent]));
	    $statistic->addChild($content);
	}
	close(IN);
    }
    
    sub getCodonUsageData
    {
	my ($xmldoc, $statistic, $hDB, $a_id) = @_;
	my $strQuery = "SELECT freq, class, TLC, OLC, name, sequence, " .
			    "IF (name IS NULL,'Terminator',name) AS name " .
		       "FROM Codon ".
			    "LEFT JOIN CodonUsage ON CodonUsage.cd_id=Codon.cd_id " .
			    "LEFT JOIN AminoAcid ON AminoAcid.aa_id=Codon.aa_id " .
		       "WHERE a_id=$a_id ORDER BY name, sequence;";
	my $statement = $hDB->prepare($strQuery);
	$statement->execute();
	my $strAA = undef;
	my $aa = undef;
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    if($refResult->{name} ne $strAA)
	    {
		$statistic->addChild($aa) if $aa;
		$aa = $xmldoc->createElement('aminoacid');
		$aa->addChild($xmldoc->createAttribute('name' => $refResult->{name}));
		$aa->addChild($xmldoc->createAttribute('TLC' => $refResult->{TLC}));
		$aa->addChild($xmldoc->createAttribute('OLC' => $refResult->{OLC}));
		$aa->addChild($xmldoc->createAttribute('class' => $refResult->{class}));
		$statistic->addChild($aa);
		$strAA = $refResult->{name};
	    }
	    my $codon = $xmldoc->createElement('codon');
	    $codon->addChild($xmldoc->createAttribute('sequence' => $refResult->{sequence}));
	    $codon->addChild($xmldoc->createAttribute('frequency' => $refResult->{freq}));
	    $aa->addChild($codon);
	}
    }
    
    sub getLengthDistrData
    {
	my ($xmldoc, $statistic, $hDB, $a_id, $refParams) = @_;
	my $nMaxLen = (int($refParams->{maxlen})) ? int($refParams->{maxlen}) : 5000;
	my $nBinSize = (int($refParams->{binsize})) ? int($refParams->{binsize}) : 20;
	my %hmQueries = (seqlen => "SELECT (FLOOR(IF(LENGTH(sequence)<=$nMaxLen, LENGTH(sequence), $nMaxLen+1) DIV $nBinSize)*$nBinSize+($nBinSize DIV 2)) AS len, ".
					   "COUNT(*) AS `count` ".
				   "FROM Contig WHERE a_id=$a_id ".
				   "GROUP BY len",
			 orflen => "SELECT (FLOOR(IF(LENGTH(ORF.sequence)<=$nMaxLen, LENGTH(ORF.sequence), $nMaxLen+1) DIV $nBinSize)*$nBinSize+($nBinSize DIV 2)) AS len, ".
					   "COUNT(*) AS `count` ".
				   "FROM Contig ".
					"INNER JOIN ORF ON ORF.c_id=Contig.c_id ".
					"INNER JOIN ORFType ON ORF.orft_id=ORFType.orft_id ".
				   "WHERE a_id=$a_id AND ORFType.name='Putative' ".
				   "GROUP BY len");
	my $statement = $hDB->prepare($hmQueries{$refParams->{type}});
	$statement->execute();
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $bin = $xmldoc->createElement('bin');
	    $bin->addChild($xmldoc->createAttribute('value' => $refResult->{len}));
	    $bin->addChild($xmldoc->createAttribute('label' => ($refResult->{len}<=$nMaxLen) ? $refResult->{len} : ">$nMaxLen"));
	    $bin->addChild($xmldoc->createAttribute('count' => $refResult->{count}));
	    $statistic->addChild($bin);
	}
    }
    
    sub getRefSeqCoverageData
    {
	my ($xmldoc, $statistic, $hDB, $a_id) = @_;
	my $strQuery = "SELECT COUNT(DISTINCT RefSeq.seq_id) AS count, ".
			      "RefSeqOrganism.sequences AS seqcount, ".
			      "RefSeqOrganism.name, ".
			      "CASE ".
				"WHEN Homology.evalue>1e-20 THEN 'Weak' ".
				"WHEN Homology.evalue<=1e-20 AND Homology.evalue>1e-50 THEN 'Similar' ".
				"WHEN Homology.evalue<=1e-50 AND Homology.evalue>1e-90 THEN 'Putative' ".
				"ELSE 'Strong' END ".
			      "AS type ".
		       "FROM Homology ".
			    "INNER JOIN Contig ON Contig.c_id=Homology.seq_id ".
			    "INNER JOIN RefSeq ON RefSeq.rs_id=Homology.rs_id ".
			    "INNER JOIN RefSeqOrganism ON RefSeqOrganism.rso_id=RefSeq.rso_id ".
			    "INNER JOIN SequenceType ON Homology.st_id=SequenceType.st_id ".
		       "WHERE Contig.a_id=$a_id AND SequenceType.name='transcript'".
		       "GROUP BY RefSeqOrganism.rso_id, type;";
	my $statement = $hDB->prepare($strQuery);
	$statement->execute();
	my $strOrganism = undef;
	my $organism = undef;
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    if($refResult->{name} ne $strOrganism)
	    {
		$statistic->addChild($organism) if $organism;
		$organism = $xmldoc->createElement('organism');
		$organism->addChild($xmldoc->createAttribute('name' => $refResult->{name}));
		$organism->addChild($xmldoc->createAttribute('sequences' => $refResult->{seqcount}));
		$statistic->addChild($organism);
		$strOrganism = $refResult->{name};
	    }
	    my $class = $xmldoc->createElement('class');
	    $class->addChild($xmldoc->createAttribute('type' => $refResult->{type}));
	    $class->addChild($xmldoc->createAttribute('count' => $refResult->{count}));
	    $organism->addChild($class);
	}
    }
    
    sub getMoleculeTypesDistributionData
    {
	my ($xmldoc, $statistic, $hDB, $a_id) = @_;
	my $strQuery = "SELECT Molecule.name AS type, ".
	                      "COUNT(*) AS count ".
		       "FROM Annotation ".
		           "INNER JOIN Contig ON Annotation.an_id=Contig.an_id ".
			   "INNER JOIN Molecule ON Annotation.m_id=Molecule.m_id ".
		       "WHERE Contig.a_id=$a_id ".
		       "GROUP BY Molecule.name";
	my $statement = $hDB->prepare($strQuery);
	$statement->execute();
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $molecule = $xmldoc->createElement('molecule');
	    $molecule->addChild($xmldoc->createAttribute('type' => $refResult->{type}));
	    $molecule->addChild($xmldoc->createAttribute('count' => $refResult->{count}));
	    $statistic->addChild($molecule)
	}
    }

    sub getSequences
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{assembly})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No assembly specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        	my $strType = (lc($refParams->{type}) eq 'protein') ? 'protein' : 'dna';
        	my $strSuffix = 'fa';
        	my $bNCBIFasta = 0;
        	if(lc($refParams->{fasta}) eq 'ncbi')
        	{
        	    $strSuffix = 'nfa';
        	    $bNCBIFasta = 1;
        	}
	
        	# Check if the assembly exists.
        	my $strQuery = "SELECT a_id, name FROM Assembly WHERE version=$refParams->{assembly}";
        	my ($a_id, $strName) = $self->{_db}->selectrow_array($strQuery);
        	if(!$a_id)
        	{
        	    $xmlerr->addChild($xmldoc->createTextNode("The specified assembly does not exist"));
              return Constants::ERR_DATA_NOT_FOUND;
        	}
        	# If the ZIP file exists.
        	my $strZIPfile = "$self->{_zipdir}/Am_$refParams->{assembly}/Am_$refParams->{assembly}.$strType.$strSuffix.zip";
        	unless(-e $strZIPfile)
        	{
        	    `mkdir -p $self->{_zipdir}/Am_$refParams->{assembly}`;
        	    # Fetch the data.
        	    my %hmQueries = ('dna' => "SELECT Contig.name AS c_name, ".
        					                             "Contig.sequence AS seq, ".
        					                             "Annotation.symbol AS symbol, ".
        					                             "Annotation.definition AS definition, ".
        					                             "Molecule.name AS type ".
        				                        "FROM Contig ".
        					                           "LEFT JOIN Annotation ON Contig.an_id=Annotation.an_id ".
        					                           "LEFT JOIN Molecule ON Annotation.m_id=Molecule.m_id ".
        				                        "WHERE a_id=$a_id",
        			                 'protein' => "SELECT Contig.name AS c_name, ".
        						                               "ORF.sequence AS seq, ".
        						                               "Annotation.symbol AS symbol, ".
        						                               "Annotation.definition AS definition, ".
        						                               "ORFType.name AS type ".
        					                          "FROM Contig ".
        					                               "INNER JOIN ORF ON Contig.c_id=ORF.c_id ".
        					                               "INNER JOIN ORFType ON ORF.orft_id=ORFType.orft_id ".
        					                               "LEFT JOIN Annotation ON Contig.an_id=Annotation.an_id ".
        				                            "WHERE a_id=$a_id");
        	    my $statement = $self->{_db}->prepare($hmQueries{$strType});
        	    $statement->execute();
        	    my $content = new IO::Compress::Gzip $strZIPfile;
        	    while(my $refResult = $statement->fetchrow_hashref()) {
        		    print $content ">$refResult->{c_name}";
        		    if($bNCBIFasta) {
        		      if($refResult->{type}) {
              			print $content " $refResult->{type}";
              			print $content "|$refResult->{definition}" if($refResult->{definition});
              			print $content "|$refResult->{symbol}" if($refResult->{symbol} && ($refResult->{symbol} ne 'N/A'));
        		      } else {
        			      print $content " N/A|N/A|N/A";
        		      }
        		    } else {
        		      if($refResult->{type}) {
              			print $content "|$refResult->{type}";
              			print $content "|$refResult->{definition}" if($refResult->{definition});
              			print $content "|$refResult->{symbol}" if($refResult->{symbol} && ($refResult->{symbol} ne 'N/A'));
        		      }
        		    }
        		    print $content "\n$refResult->{seq}\n";
        	    }
        	    $content->close();
        	  }
          	my $nFileSize = -s $strZIPfile;
          	print "Content-type:archive/zip\n";
          	print "Content-length:$nFileSize\n";
          	print "Content-disposition:attachment;filename=$strName"."_$strType.$strSuffix.zip;\n\n";
          	open(FILE, $strZIPfile);
          	print $_ while(<FILE>);
          	close(FILE);
          	return Constants::ERR_OK_BINARY;
          }
    }

1;
