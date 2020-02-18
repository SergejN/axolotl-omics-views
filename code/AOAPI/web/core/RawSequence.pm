#!/usr/bin/env perl

#   File:
#       RawSequence.pm
#
#   Description:
#       Manages the raw sequences.
#
#   Version:
#       3.0.1
#
#   Date:
#       2016-04-28
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use DBI;
use JSON;
use AOAPI::core::Constants;


package SeqEntry;
{
    sub new
    {
	my ($class, $refSeqData) = @_;
        my $refData = {name => $refSeqData->{name},
		       sequence => $refSeqData->{sequence},
		       quality => $refSeqData->{quality},
		       dataset => $refSeqData->{dataset}};
        my $self = {data => $refData};
        bless $self, $class;
        return $self;
    }
    
    sub asBinary
    {
        my $self = shift;
        return $self->{data};
    }
    
    sub asJSON
    {
        my ($self) = shift;
        return ::encode_json($self->{data});
    }
    
    sub asText
    {
        my ($self) = shift;
        return sprintf("%s\t%d\t%s\t%s\n",
                        $self->{data}->{name},
                        $self->{data}->{dataset},
                        $self->{data}->{sequence},
                        $self->{data}->{quality});
    }

    sub asXML
    {
        my ($self) = shift;
	if($self->{data}->{quality})
	{
	    my $strPattern = '<rawsequence name="%s" dataset="%d">'.
	                        '<sequence>%s</sequence>'.
				'<quality>%s</quality>'.
			    '</rawsequence>';
	    return sprintf($strPattern,
			   $self->{data}->{name},
			   $self->{data}->{dataset},
			   $self->{data}->{sequence},
			   $self->{data}->{quality});
	}
	else
	{
	    my $strPattern = '<rawsequence name="%s" dataset="%d">'.
	                        '<sequence>%s</sequence>'.
			    '</rawsequence>';
	    return sprintf($strPattern,
			   $self->{data}->{name},
			   $self->{data}->{dataset},
			   $self->{data}->{sequence});
	}
    }
}


package RawSequenceImporter;
{
    sub new
    {
	my ($class, $ds_id, $hDB) = @_;
	my $strQuery = "INSERT INTO Sequence(name, sequence, quality) ".
	                             "VALUES(?,?,?)";
	my $stmtInsert = $hDB->prepare($strQuery);
	$hDB->{AutoCommit} = 0;
        my $self = {database => $hDB,
		    statements => {insert => $stmtInsert},
		    index => 0,
		    nSeqs => 0,
		    ds_id => $ds_id,
		    longest => 0,
		    shortest => 1000000,
		    mean => 0,
		    median => 0,
		    histogram => {},
		    bases => {total => 0, 'A' => 0, 'C' => 0, 'G' => 0, 'T' => 0, 'N' => 0}};
        bless $self, $class;
        return $self;
    }
    
    sub insertSequences
    {
	my ($self, $refSeqs) = @_;
	return 0 if(!$refSeqs);
	my @arrSeqs = @{$refSeqs};
	return 0 if((scalar @arrSeqs) == 0);
	
	foreach my $refSeq (@arrSeqs)
	{
	    return 0 if(!$refSeq->{sequence});
	    return 0 if($refSeq->{quality} && (length($refSeq->{sequence}) != length($refSeq->{quality})));
	}
	
	$self->{index}++;
	my $strID = sprintf("AMRS_%05d%010d", $self->{ds_id}, $self->{index});
	
	foreach my $refSeq (@arrSeqs)
	{
	    $self->{statements}->{insert}->execute($strID, $refSeq->{sequence}, ($refSeq->{quality} || ''));
	    my $strSeq = $refSeq->{sequence};
	    my $nSeqLen = length($strSeq);
	
	    # Statistics
	    $self->{bases}->{'A'} += ($strSeq =~ tr/Aa//);
	    $self->{bases}->{'C'} += ($strSeq =~ tr/Cc//);
	    $self->{bases}->{'G'} += ($strSeq =~ tr/Gg//);
	    $self->{bases}->{'T'} += ($strSeq =~ tr/Tt//);
	    $self->{bases}->{'N'} += ($strSeq =~ tr/Nn//);
	    $self->{bases}->{total} += $nSeqLen;
	
	    # Lengths
	    $self->{longest} = $nSeqLen if($nSeqLen > $self->{longest});
	    $self->{shortest} = $nSeqLen if($nSeqLen < $self->{shortest});
	    $self->{histogram}->{$nSeqLen}++;
	    
	    $self->{nSeqs}++;
	}
    }

    sub finalize
    {
	my ($self) = @_;
	$self->{database}->commit();
	$self->{database}->{AutoCommit} = 1;
	
	# Read count
	my $strQuery = "INSERT INTO Data (name, value) VALUES ('ReadCount', '$self->{index}')";
	$self->{database}->do($strQuery);
	
	# Base counts
	my $strVal = ::encode_json($self->{bases});
	$strQuery = "INSERT INTO Data (name, value) VALUES('BaseCounts', '$strVal')";
	$self->{database}->do($strQuery);
	
	# Length statistics
	my @arrLengths = sort {$a <=> $b} keys %{$self->{histogram}};
	my @arrBins = ();
	my @arrTmp = ();
	foreach my $iLength (@arrLengths)
	{
	    my $nCount = $self->{histogram}->{$iLength};
	    push(@arrBins, {$iLength => $nCount});
	    push(@arrTmp, ($iLength) x $nCount);
	}
	$self->{mean} = $self->{bases}->{total}/$self->{nSeqs};
	$self->{histogram} = \@arrBins;
	if($self->{index} % 2 == 1)
	{
	    my $iValIndex = int($self->{index}/2+0.5)-1;
	    $self->{median} = $arrTmp[$iValIndex];
	}
	else
	{
	    my $iValIndex1 = $self->{index}/2;
	    my $iValIndex2 = $iValIndex1-1;
	    $self->{median} = ($arrTmp[$iValIndex1]+$arrTmp[$iValIndex2])/2;
	}

	$strVal = ::encode_json({longest => $self->{longest},
			         shortest => $self->{shortest},
				 mean => $self->{mean},
				 median => $self->{median}});
	$strQuery = "INSERT INTO Data (name, value) VALUES('LengthStatistics', '$strVal')";
	$self->{database}->do($strQuery);

	# Length distribution
	$strVal = ::encode_json($self->{histogram});
	$strQuery = "INSERT INTO Data (name, value) VALUES('LengthDistribution', '$strVal')";
	$self->{database}->do($strQuery);
	
	$self->{statements}->{insert}->finish();
    }
    
    sub discard
    {
	my ($self) = @_;
	$self->{statements}->{insert}->finish();
    }
}


package RawSequence;
{
    my $MODULE = 'RawSequence';
    my $VERSION = '3.0.1';
    my $DATE = '2016-04-28';
    
    my $PROP_OWNER = 'RawSequence';
    my $PROP_DATABASES = 'databases';

    
    sub getName
    {
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Incapsulates the raw sequences management";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub new
    {
        my ($class) = @_;
        my $self = {database => undef};
        bless $self, $class;
        return $self;
    }
    
    sub init
    {
        my ($self, $hDB) = @_;
        $self->{database} = $hDB;
    }
    
    sub execute
    {
        my ($self, $refParams) = @_;
        my $strMethod = lc($refParams->{_method});
        my $refMethodParams = $refParams->{_parameters};
        # Execute the method.
        if($strMethod eq lc('find'))
        {
            return $self->find($refMethodParams);
        }
	elsif($strMethod eq lc('getList'))
        {
	    $refMethodParams->{term} = undef;
            return $self->find($refMethodParams);
        }
	elsif($strMethod eq lc('getCount'))
        {
            return $self->getCount($refMethodParams);
        }
	elsif($strMethod eq lc('getDetails'))
        {
            return $self->getDetails($refMethodParams);
        }
        return undef;
    }
    
    sub find
    {
        my ($self, $refParams) = @_;
	my $strQuery = "SELECT name, sequence, quality, dataset ".
	               "FROM Sequence";
	if($refParams->{term})
	{
	    $strQuery .= " WHERE name LIKE '%$refParams->{term}%'";
	}
	my $stmt = $self->{sqlitedb}->prepare($strQuery);
        $stmt->execute();
        my $seqList = new EntriesList('sequences');
        while(my $refResult = $stmt->fetchrow_hashref())
        {
            $seqList->addEntry(new SeqEntry($refResult));
        }
        $stmt->finish();
        return {result => Constants::AORESULT_OK,
                data => $seqList};
    }
    
    sub getCount
    {
        my ($self, $refParams) = @_;
        my $strQuery = "SELECT COUNT(*) ".
                       "FROM Sequence";
	my $iIndex = int($refParams->{dataset});
        if($iIndex > 0)
        {
            $strQuery .= " WHERE dataset = $iIndex";
        }
        my ($nCount) = $self->{sqlitedb}->selectrow_array($strQuery);
        return {result => Constants::AORESULT_OK,
                data => $nCount};
    }
    
    sub getDetails
    {
        my ($self, $refParams) = @_;
        if(!$refParams->{id})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The sequence ID is not specified"};
        }
        my $strQuery = "SELECT name, sequence, quality, dataset ".
	               "FROM Sequence ".
		       "WHERE name=?";
	my $stmt = $self->{sqlitedb}->prepare($strQuery);
	$stmt->execute($refParams->{id});
	my $refResult = $self->{sqlitedb}->selectrow_hashref();
	if($refResult)
	{
	    return {result => Constants::AORESULT_OK,
                    data => new SeqEntry($refResult)};
	}
	return {result => Constants::AORESULT_DATA_NOT_FOUND,
                msg => "The specified raw sequence does not exist"};
    }
    
    sub createDatabase
    {
	my ($self, $strDatasetName, $bOverwrite) = @_;
	
	# Check if the dataset ID is valid
	my $strQuery = "SELECT ds_id FROM Dataset WHERE name='$strDatasetName'";
	my ($ds_id) = $self->{database}->selectrow_array($strQuery);
	if(!$ds_id)
	{
	    return {result => Constants::AORESULT_DATA_NOT_FOUND,
                    msg => "The specified dataset does not exist"};
	}
	
	# Open/Create the database
	my $strQuery = "SELECT value ".
	               "FROM Data ".
		       "WHERE owner='$PROP_OWNER' AND name='$PROP_DATABASES'";
	my ($strDBroot) = $self->{database}->selectrow_array($strQuery);
	if(! -e $strDBroot)
	{
	    `mkdir -p $strDBroot`;
	}
	my $strDBfile = "$strDBroot/RawReads.$ds_id.aodb";
	if(!$bOverwrite && (-e $strDBfile))
	{
	    return {result => Constants::AORESULT_DATA_EXISTS,
                    msg => "The specified dataset already exist"};
	}
	unlink($strDBfile) if(-e $strDBfile);
	my $hDB = DBI->connect("DBI:SQLite:dbname=$strDBfile", '', '');
	my $strQuery = "CREATE TABLE Sequence(name      TEXT NOT NULL, ".
					     "sequence  TEXT NOT NULL, ".
					     "quality   TEXT)";
	$hDB->do($strQuery);
	
	$strQuery = "CREATE TABLE Data(name     TEXT  NOT NULL, ".
				      "value    TEXT  NOT NULL)";
	$hDB->do($strQuery);
	
	$strQuery = "CREATE INDEX indexSequence ON Sequence(name)";
	$hDB->do($strQuery);
	return {result => Constants::AORESULT_OK,
                data => {importer => new RawSequenceImporter($ds_id, $hDB),
			 filename => $strDBfile}};
    }
}

1;
