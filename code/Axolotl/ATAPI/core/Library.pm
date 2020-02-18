#!/usr/bin/env perl

#   File:
#       Library.pm
#
#   Description:
#       Contains the Library core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.2.1
#
#   Date:
#       10.08.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Library;
{
    my $MODULE = 'Library';
    my $VERSION = '1.0.7';
    my $DATE = '2014-07-05';
    
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
	$self->{_stats} = $ps->getSetting('LIBRARY', 'statistics');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the details about the sequences present in the additional libraries.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'getList',
                           _description => 'Retrieves the list of available libraries',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getList"},
			  
			  {_name => 'getLibraryDetails',
                           _description => 'Retrieves the details about the specified libraries',
                           _args => [{_name => 'libIDs',
                                      _description => 'Comma-separated list of library IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid library IDs were specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getLibraryDetails&libIDs=EST",
			   _remarks => "If no library IDs are specified the behaviour of the method is identical with that of '$MODULE.getList'."},
			  
			  {_name => 'getStatisticData',
                           _description => 'Returns the data for the specified statistic',
			   _args => [{_name => 'libID',
                                      _description => 'ID of the library to retrieve statistic data for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'type',
                                      _description => "Statistic type. Must be a value returned by $MODULE.getList for this library",
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
                                            _description => 'If either library ID or statistic type is not specified'},
					   {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid statistic type is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid library ID is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getStatisticData&libID=EST&type=gc"},
	
			  {_name => 'getDetails',
                           _description => 'Retrieves the details of the sequence: sequence, sequence length, author, location, library name, and annotation if any',
                           _args => [{_name => 'seqIDs',
                                      _description => 'Comma-separated list of sequence IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no EST IDs were specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no valid EST IDs were specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getDetails&seqIDs=EST_00000001",
			   _remarks => "For ESTs the method additionally returns the position on the plate if applicable."},
			  
			  {_name => 'getLocation',
                           _description => 'Returns the details about the EST sequence location',
                           _args => [{_name => 'seqIDs',
                                      _description => 'Comma-separated list of sequence IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence IDs were specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getLocation&seqIDs=EST_00004132"},

			  {_name => 'convertLocationToPlatePosition',
                           _description => 'Extracts the plate and well names from the EST sequence location',
                           _args => [{_name => 'locations',
                                      _description => 'Comma-separated list of EST locations',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no EST names were specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.convertLocationToPlatePosition&locations=BL282A_E08"});
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
	if($strMethod eq 'getLibraryDetails')
        {
            return $self->getLibraryDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	if($strMethod eq 'getStatisticData')
        {
            return $self->getStatisticData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getDetails')
        {
            return $self->getDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getLocation')
        {
            return $self->getLocation($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'convertLocationToPlatePosition')
        {
            return $self->convertLocationToPlatePosition($refMethodParams, $xmldoc, $xmldata, $xmlerr);
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
	my $libraries = $xmldoc->createElement('libraries');
	my %hmFields = ('name' => {_column => 'name', _type => Constants::NT_ATTRIBUTE},
			'id' => {_column => 'id', _type => Constants::NT_ATTRIBUTE},
                        'description' => {_column => 'description', _type => Constants::NT_TEXT},
			'sequences' => {_column => 'count', _type => Constants::NT_ATTRIBUTE},
			'type' => {_column => 'type', _type => Constants::NT_ATTRIBUTE},
			'maxlen' => {_column => 'maxlen', _type => Constants::NT_ATTRIBUTE},
			'minlen' => {_column => 'minlen', _type => Constants::NT_ATTRIBUTE},
			'avglen' => {_column => 'avglen', _type => Constants::NT_ATTRIBUTE},
			'gc' => {_column => 'gc', _type => Constants::NT_ATTRIBUTE},
			'author' => {_column => 'aname', _type => Constants::NT_ATTRIBUTE, _replace => {'System' => 'Multiple authors'}},
			'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE});
	my $strQuery = "SELECT Library.name AS name, ".
			      "Library.id AS id, ".
			      "Library.description AS description, ".
			      "COUNT(*) AS count, ".
			      "type, ".
			      "maxlen, ".
			      "minlen, ".
			      "avglen, ".
			      "gc, ".
			      "Author.name AS aname, ".
			      "Author.email ".
		       "FROM Library ".
			    "INNER JOIN LibrarySequence ON LibrarySequence.lib_id=Library.lib_id ".
			    "INNER JOIN Author ON Library.au_id=Author.au_id ".
		       "GROUP BY Library.name ".
		       "ORDER BY Library.name";
	my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $library = $xmldoc->createElement('library');
	    $self->{_fnAddNodes}->($xmldoc, $library, \%hmFields, $refResult);
	    my $statistics = $xmldoc->createElement('statistics');
	    addStatisticEntry($xmldoc, $statistics, 'gc', 'GC content', 'GC content distribution', 'General') if(-e "$self->{_stats}/$refResult->{id}/$refResult->{id}"."_GC.stats");
	    addStatisticEntry($xmldoc, $statistics, 'seqlen', 'Sequence length', 'Sequence length distribution', 'General') if(-e "$self->{_stats}/$refResult->{id}/$refResult->{id}"."_len.stats");
	    $library->addChild($statistics);
	    $libraries->addChild($library);
	}
	$xmldata->addChild($libraries);
	return Constants::ERR_OK;
    }
    
    sub getLibraryDetails
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	if(!$refParams->{libIDs})
	{
	    return $self->getList($refParams, $xmldoc, $xmldata, $xmlerr);
	}
	my @arrLibIDs = split(/,/, $refParams->{libIDs});
	$_=~ s/'/\\'/g foreach @arrLibIDs;
	$_ = "'$_'" foreach @arrLibIDs;
	my $nAdded = 0;
	my $libraries = $xmldoc->createElement('libraries');
	my %hmFields = ('name' => {_column => 'name', _type => Constants::NT_ATTRIBUTE},
			'id' => {_column => 'id', _type => Constants::NT_ATTRIBUTE},
                        'description' => {_column => 'description', _type => Constants::NT_TEXT},
			'sequences' => {_column => 'count', _type => Constants::NT_ATTRIBUTE},
			'type' => {_column => 'type', _type => Constants::NT_ATTRIBUTE},
			'maxlen' => {_column => 'maxlen', _type => Constants::NT_ATTRIBUTE},
			'minlen' => {_column => 'minlen', _type => Constants::NT_ATTRIBUTE},
			'avglen' => {_column => 'avglen', _type => Constants::NT_ATTRIBUTE},
			'gc' => {_column => 'gc', _type => Constants::NT_ATTRIBUTE},
			'author' => {_column => 'aname', _type => Constants::NT_ATTRIBUTE, _replace => {'System' => 'Multiple authors'}},
			'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE});
	my $strQuery = "SELECT Library.name AS name, ".
	                      "Library.id AS id, ".
			      "Library.description AS description, ".
			      "COUNT(*) AS count, ".
			      "type, ".
			      "maxlen, ".
			      "minlen, ".
			      "avglen, ".
			      "gc, ".
			      "Author.name AS aname, ".
			      "Author.email ".
		       "FROM Library INNER JOIN LibrarySequence ON LibrarySequence.lib_id=Library.lib_id INNER JOIN Author ON Library.au_id=Author.au_id ".
		       "WHERE Library.id IN (". join(',', @arrLibIDs) .") GROUP BY Library.name;";
	my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $library = $xmldoc->createElement('library');
	    $self->{_fnAddNodes}->($xmldoc, $library, \%hmFields, $refResult);
	    my $statistics = $xmldoc->createElement('statistics');
	    addStatisticEntry($xmldoc, $statistics, 'gc', 'GC content', 'GC content distribution', 'General') if(-e "$self->{_stats}/$refResult->{id}/$refResult->{id}"."_GC.stats");
	    addStatisticEntry($xmldoc, $statistics, 'seqlen', 'Sequence length', 'Sequence length distribution', 'General') if(-e "$self->{_stats}/$refResult->{id}/$refResult->{id}"."_len.stats");
	    $library->addChild($statistics);
	    $libraries->addChild($library);
	    $nAdded++;
	}
	if($nAdded)
	{
	    $xmldata->addChild($libraries);
	    return Constants::ERR_OK;
	}
	else
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No valid library IDs specified"));
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
        if(!$refParams->{libID})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No library specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!$refParams->{type})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No statistic type specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$refParams->{libID} =~ s/'/\\'/g;
	my $strQuery = "SELECT COUNT(*) FROM Library WHERE id='$refParams->{libID}'";
        my ($nCount) = $self->{_db}->selectrow_array($strQuery);
        if(!$nCount)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified library does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
	my $statistic = $xmldoc->createElement('statistic');
        $statistic->addChild($xmldoc->createAttribute('library' => $refParams->{libID}));
        $statistic->addChild($xmldoc->createAttribute('type' => $refParams->{type}));
	if($refParams->{type} eq 'gc')
	{
	    my $strFilename = "$self->{_stats}/$refParams->{libID}/$refParams->{libID}"."_GC.stats";
	    if(! -e $strFilename)
	    {
		$xmlerr->addChild($xmldoc->createTextNode("No GC statistics available for the specified library"));
		return Constants::ERR_DATA_NOT_FOUND;
	    }
	    getGCContentData($xmldoc, $statistic, $strFilename);
	}
	elsif($refParams->{type} eq 'seqlen')
	{
	    my $strFilename = "$self->{_stats}/$refParams->{libID}/$refParams->{libID}"."_len.stats";
	    if(! -e $strFilename)
	    {
		$xmlerr->addChild($xmldoc->createTextNode("No length distribution data available for the specified library"));
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
    
    sub getDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	if(!$refParams->{seqIDs})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence IDs specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my @arrIDs = split(/,/, $refParams->{seqIDs});
	# Escape hyphens in the sequence IDs.
	$_=~ s/'/\\'/g foreach @arrIDs;
	$_ = "'$_'" foreach @arrIDs;
	my %hmFields = ('id' => {_column => 'id', _type => Constants::NT_ATTRIBUTE},
			'accession' => {_column => 'accession', _type => Constants::NT_ATTRIBUTE},
                        'length' => {_column => 'len', _type => Constants::NT_ATTRIBUTE},
			'author' => {_column => 'aname', _type => Constants::NT_ATTRIBUTE, _replace => {'System' => ''}},
			'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE},
			'library' => {_column => 'lname', _type => Constants::NT_ATTRIBUTE},
			'type' => {_column => 'type', _type => Constants::NT_ATTRIBUTE},
			'libraryID' => {_column => 'libraryID', _type => Constants::NT_ATTRIBUTE},
			'sequence' => {_column => 'sequence', _type => Constants::NT_TEXT});
	my %hmFields_annot = ('symbol' => {_column => 'symbol', _type => Constants::NT_ATTRIBUTE},
			      'accession' => {_column => 'accession', _type => Constants::NT_ATTRIBUTE},
			      'description' => {_column => 'description', _type => Constants::NT_TEXT},
			      'remarks' => {_column => 'remarks', _type => Constants::NT_ATTRIBUTE});
	my $strQuery = "SELECT LibrarySequence.ls_id AS ls_id, ".
			      "LibrarySequence.name AS id, ".
			      "LibrarySequence.sequence AS sequence, ".
			      "LENGTH(LibrarySequence.sequence) AS len, " .
			      "Author.name AS aname, ".
			      "Author.email, ".
			      "LibrarySequence.accession AS accession, ".
			      "Library.type AS type, ".
			      "Library.name AS lname, ".
			      "Library.id AS libraryID, ".
			      "LibraryAnnotation.symbol AS symbol, ".
			      "LibraryAnnotation.description AS description, ".
			      "LibraryAnnotation.remarks AS remarks ".
		       "FROM LibrarySequence ".
		            "INNER JOIN Library ON LibrarySequence.lib_id=Library.lib_id ".
			    "INNER JOIN Author ON LibrarySequence.au_id=Author.au_id ".
			    "LEFT JOIN LibraryAnnotation ON LibrarySequence.ls_id=LibraryAnnotation.ls_id ".
		       "WHERE LibrarySequence.name IN (" . join(',', @arrIDs) . ");";
	my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
	if($statement->rows>0)
	{
	    while(my $refResult = $statement->fetchrow_hashref())
	    {
		my $sequence = $xmldoc->createElement('sequence');
		$self->{_fnAddNodes}->($xmldoc, $sequence, \%hmFields, $refResult);
		# Sequence annotation.
		if($refResult->{description} || $refResult->{symbol})
		{
		    my $annotation = $xmldoc->createElement('annotation');
		    $self->{_fnAddNodes}->($xmldoc, $annotation, \%hmFields_annot, $refResult);
		    $sequence->addChild($annotation);
		}
		$xmldata->addChild($sequence);
	    }
	    return Constants::ERR_OK;
	}
	else
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No valid sequence IDs specified"));
            return Constants::ERR_DATA_NOT_FOUND;
	}
    }

    sub getLocation
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	if(!$refParams->{seqIDs})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence IDs specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my @arrIDs = split(/,/, $refParams->{seqIDs});
	foreach my $strSeqID (@arrIDs)
	{
	    $strSeqID =~ s/'//g;
	    my ($strLocation) = $self->{_db}->selectrow_array("SELECT location FROM LibrarySequence WHERE name='$strSeqID'");
	    next if(!$strLocation);
	    my $sequence = $xmldoc->createElement('sequence');
	    $sequence->addChild($xmldoc->createAttribute(name => $strSeqID));
	    my $refLoc = $self->convertLocationToPlatePosition(undef, undef, undef, undef, $strLocation);
	    my $location = $xmldoc->createElement('location');
	    $location->addChild($xmldoc->createAttribute(name => $strLocation));
	    $location->addChild($xmldoc->createAttribute(plate => $refLoc->{plate}));
	    $location->addChild($xmldoc->createAttribute(well => $refLoc->{well}));
	    $sequence->addChild($location);
	    $xmldata->addChild($sequence);
	}
	return Constants::ERR_OK;
    }
    
    sub convertLocationToPlatePosition
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr, $strLoc) = @_;
	if(!$strLoc && !$refParams->{locations})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No locations specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	my @arrLocations = (!$strLoc) ? split(/,/, $refParams->{locations}) : ($strLoc);
	foreach my $strLocation (@arrLocations)
	{
	    $strLocation = uc($strLocation);
	    my $strPlate = 'N/A';
	    my $strWell = 'N/A';
	    if($strLocation =~ m/^(NT|BL)([0-9]+)([A-D])_([A-H])([0-9]+)$/)
	    {
		$strPlate = "$1$2";
		$strWell = "$4$5";
		my $strRows = 'ABCDEFGHIJKLMNOP';
		my $iRow = int(ord($4)-ord('A'))+1;
		my $iCol = undef;
		if($3 eq 'A')
		{
		    $iCol = int($5)*2-1;
		    $iRow = $iRow*2-1;
		}
		elsif($3 eq 'B')
		{
		    $iCol = int($5)*2;
		    $iRow = $iRow*2-1;
		}
		elsif($3 eq 'C')
		{
		    $iCol = int($5)*2-1;
		    $iRow = $iRow*2;
		}
		elsif($3 eq 'D')
		{
		    $iCol = int($5)*2;
		    $iRow = $iRow*2;
		}
		if($iCol)
		{
		    $strWell = substr($strRows,$iRow-1,1) . sprintf("%02d", $iCol);
		}
		else
		{
		    $strPlate = $strLocation;
		    $strWell = 'N/A';
		}
	    }
	    elsif($strLocation =~ m/^[0-9]+(NT|BL)([0-9]+)_([0-9]+).+_([A-H][0-9]+)$/)
	    {
		$strPlate = "$1$2_$3";
		$strWell = $4;
	    }
	    elsif($strLocation =~ m/^(NT|BL)([0-9]+)_([A-H][0-9]+)$/)
	    {
		$strPlate = "$1$2";
		$strWell = $3;
	    }
	    return {plate => $strPlate, well => $strWell} if($strLoc);
	    my $location = $xmldoc->createElement('location');
	    $location->addChild($xmldoc->createAttribute('name' => $strLocation));
	    $location->addChild($xmldoc->createAttribute('plate' => "$strPlate"));
	    $location->addChild($xmldoc->createAttribute('well' => $strWell));
	    $xmldata->addChild($location);
	}
	return Constants::ERR_OK; 
    }
}

1;