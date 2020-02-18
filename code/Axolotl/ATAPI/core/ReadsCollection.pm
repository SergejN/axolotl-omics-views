#!/usr/bin/env perl

#   File:
#       ReadsCollection.pm
#
#   Description:
#       Contains the ReadsCollection core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.5
#
#   Date:
#       26.03.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Storable;

use Axolotl::ATAPI::Constants;


package ReadsCollection;
{
    my $MODULE = 'ReadsCollection';
    my $VERSION = '1.0.5';
    my $DATE = '2014-05-27';
    
    my $BLASTDBCMD = 'blastdbcmd';
    
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
	$self->{_root} = $ps->getSetting('READSCOLLECTION', 'root');
	$self->{_stats} = $ps->getSetting('READSCOLLECTION', 'statistics');
	$self->{_mapping} = $ps->getSetting('READSCOLLECTION', 'mapping');
	$self->{_pb_blast_db} = $ps->getSetting('READSCOLLECTION', 'PB_BLAST_DB');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the details about the sequences present in unsorted reads collections.";
    }
      
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'getList',
                           _description => 'Retrieves the list of available collections',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getList"},
                           
                           {_name => 'getCollectionDetails',
                           _description => 'Retrieves the details about the specified reads collections',
                           _args => [{_name => 'collectionIDs',
                                      _description => 'Comma-separated list of collection IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid collection IDs were specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getCollectionDetails&collectionIDs=PacBio",
			   _remarks => "If no collection IDs are specified the behaviour of the method is identical with that of '$MODULE.getList'."},
			   
			   {_name => 'getStatisticData',
                           _description => 'Returns the data for the specified statistic',
			   _args => [{_name => 'collectionID',
                                      _description => 'ID of the collection to retrieve statistic data for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'type',
                                      _description => "Statistic type. Must be a value returned by $MODULE.getCollectionDetails for this collection",
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'maxlen',
                                      _description => "For read length distribution only. Specifies the maximal length value, after which the counts are summed up",
                                      _type => 'optional',
                                      _default => '25000'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If either collection ID or statistic type is not specified'},
					   {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid statistic type is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid collection ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getStatisticData&collectionID=PacBio&type=gc"},
	
			  {_name => 'getReadDetails',
                           _description => 'Retrieves the details of a single read: sequence, sequence length, quality scores, and collection name',
                           _args => [{_name => 'readID',
                                      _description => 'Read ID',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no read ID was specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If the read with the specified ID was not found'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getReadDetails&readID=PB_4341.9277_107565.0-18795"});
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
	elsif($strMethod eq 'getCollectionDetails')
        {
            return $self->getCollectionDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getStatisticData')
        {
            return $self->getStatisticData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getReadDetails')
        {
            return $self->getReadDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
	return $self->getCollectionDetails($refParams, $xmldoc, $xmldata, $xmlerr, 1);
    }
    
    sub getCollectionDetails
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr, $bListAll) = @_;
	my @arrCollectionIDs = ($refParams->{collectionIDs}) ? split(/,/, $refParams->{collectionIDs}) : ();
	$_=~ s/'/\\'/g foreach @arrCollectionIDs;
	$_ = "'$_'" foreach @arrCollectionIDs;
	$bListAll = 1 if((scalar @arrCollectionIDs)==0);
	my $nAdded = 0;
	my $collections = $xmldoc->createElement('collections');
	my %hmFields = ('name' => {_column => 'name', _type => Constants::NT_ATTRIBUTE},
			'id' => {_column => 'id', _type => Constants::NT_ATTRIBUTE},
                        'description' => {_column => 'description', _type => Constants::NT_TEXT},
			'platform' => {_column => 'platform', _type => Constants::NT_ATTRIBUTE},
			'type' => {_column => 'type', _type => Constants::NT_ATTRIBUTE},
			'author' => {_column => 'aname', _type => Constants::NT_ATTRIBUTE, _replace => {'System' => 'Multiple authors'}},
			'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE});
	my $strQuery = ($bListAll) ? "SELECT ReadsCollection.name AS name, ".
					    "ReadsCollection.id AS id, ".
					    "ReadsCollection.description AS description, ".
					    "ReadsCollection.platform AS platform, ".
					    "ReadsCollection.type AS type, ".
					    "Author.name AS aname, ".
					    "Author.email ".
				     "FROM ReadsCollection ".
					  "INNER JOIN Author ON ReadsCollection.au_id=Author.au_id;"
				   : "SELECT ReadsCollection.name AS name, ".
					    "ReadsCollection.id AS id, ".
					    "ReadsCollection.description AS description, ".
					    "ReadsCollection.platform AS platform, ".
					    "ReadsCollection.type AS type, ".
					    "Author.name AS aname, ".
					    "Author.email ".
				     "FROM ReadsCollection ".
					  "INNER JOIN Author ON ReadsCollection.au_id=Author.au_id ".
					  "WHERE ReadsCollection.id in (" . join(',', @arrCollectionIDs) . ")";
	my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $collection = $xmldoc->createElement('collection');
	    $self->{_fnAddNodes}->($xmldoc, $collection, \%hmFields, $refResult);
	    my $statistics = $xmldoc->createElement('statistics');
	    addStatisticEntry($xmldoc, $statistics, 'gc', 'GC content', 'GC content distribution', 'General') if(-e "$self->{_stats}/$refResult->{id}/$refResult->{id}"."_GC.stats");
	    addStatisticEntry($xmldoc, $statistics, 'readlen', 'Reads length', 'Read length distribution', 'General') if(-e "$self->{_stats}/$refResult->{id}/$refResult->{id}"."_len.stats");
	    $collection->addChild($statistics);
	    $collections->addChild($collection);
	    $nAdded++;
	}
	if($nAdded)
	{
	    $xmldata->addChild($collections);
	    return Constants::ERR_OK;
	}
	else
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No valid collection IDs specified"));
            return Constants::ERR_DATA_NOT_FOUND;
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
        if(!$refParams->{collectionID})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No collection specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!$refParams->{type})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No statistic type specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$refParams->{collectionID} =~ s/'/\\'/g;
	my $strQuery = "SELECT COUNT(*) FROM ReadsCollection WHERE id='$refParams->{collectionID}'";
        my ($nCount) = $self->{_db}->selectrow_array($strQuery);
        if(!$nCount)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified collection does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
	my $statistic = $xmldoc->createElement('statistic');
        $statistic->addChild($xmldoc->createAttribute('collection' => $refParams->{collectionID}));
        $statistic->addChild($xmldoc->createAttribute('type' => $refParams->{type}));
	if($refParams->{type} eq 'gc')
	{
	    my $strFilename = "$self->{_stats}/$refParams->{collectionID}/$refParams->{collectionID}"."_GC.stats";
	    if(! -e $strFilename)
	    {
		$xmlerr->addChild($xmldoc->createTextNode("No GC statistics available for the specified collection"));
		return Constants::ERR_DATA_NOT_FOUND;
	    }
	    getGCContentData($xmldoc, $statistic, $strFilename);
	}
	elsif($refParams->{type} eq 'readlen')
	{
	    my $strFilename = "$self->{_stats}/$refParams->{collectionID}/$refParams->{collectionID}"."_len.stats";
	    if(! -e $strFilename)
	    {
		$xmlerr->addChild($xmldoc->createTextNode("No read length distribution data available for the specified collection"));
		return Constants::ERR_DATA_NOT_FOUND;
	    }
	    getLengthDistrData($xmldoc, int($refParams->{maxlen}), $statistic, $strFilename);
	}
	else
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid statistic type specified"));
            return Constants::ERR_INVALID_PARAMETER;
        }
	$xmldata->addChild($statistic);
        return Constants::ERR_OK;
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
    
    sub getLengthDistrData
    {
	my ($xmldoc, $nMaxLen, $statistic, $strFilename) = @_;
	$nMaxLen = 25000 unless $nMaxLen;
	open(IN, $strFilename);
	my $nMax = 0;
	my $iDataMax = 0;
	while(<IN>)
	{
	    last if(substr($_,0,1) eq '=');
	    chomp();
	    my ($nBin, $nCount) = split(/\t/, $_);
	    if($nBin>=$nMaxLen)
	    {
		$nMax += $nCount;
		next;
	    }
	    $iDataMax = $nBin if($nBin>=$iDataMax);
	    my $bin = $xmldoc->createElement('bin');
	    $bin->addChild($xmldoc->createAttribute(value => $nBin));
	    $bin->addChild($xmldoc->createAttribute(label => $nBin));
	    $bin->addChild($xmldoc->createAttribute(count => $nCount));
	    $statistic->addChild($bin);
	}
	close(IN);
	my $bin = $xmldoc->createElement('bin');
	if($nMax)
	{
	    $bin->addChild($xmldoc->createAttribute(value => $nMaxLen));
	    $bin->addChild($xmldoc->createAttribute(label => ">=$nMaxLen"));
	    $bin->addChild($xmldoc->createAttribute(count => $nMax));
	    $statistic->addChild($bin);
	}
    }
    
    sub getReadDetails
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	if(!$refParams->{readID})
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No read ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
	}
	if($refParams->{readID} =~ m/^(PB_[0-9]+)/)
	{
	    my $strCMD = "$BLASTDBCMD -db $self->{_pb_blast_db} -entry $refParams->{readID}";
	    open(CMD, "$strCMD |");
	    my $strLine = <CMD>;
	    my $strSeq = '';
	    while($strLine = <CMD>)
	    {
		chomp($strLine);
		$strSeq .= uc($strLine);
	    }
	    close(CMD);
	    if($strSeq)
	    {
		my $read = $xmldoc->createElement('read');
		$read->addChild($xmldoc->createAttribute(name => $refParams->{readID}));
		$read->addChild($xmldoc->createAttribute(length => length($strSeq)));
		$read->addChild($xmldoc->createAttribute(collection => "PacBio"));
		$read->addChild($xmldoc->createAttribute(platform => "PacBio"));
		$read->addChild($xmldoc->createTextNode($strSeq));
		$xmldata->addChild($read);
		return Constants::ERR_OK;
	    }
	}
	$xmlerr->addChild($xmldoc->createTextNode("The specified read ID could not be found"));
	return Constants::ERR_DATA_NOT_FOUND;
    }
}

1;