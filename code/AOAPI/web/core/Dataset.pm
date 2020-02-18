#!/usr/bin/env perl

#   File:
#       Dataset.pm
#
#   Description:
#       Manages the datasets.
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
use AOAPI::utils::EntriesList;


package DatasetEntry;
{
    sub new
    {
        my ($class, $refDatasetData, $bSuppressHeader) = @_;
        my $refData = {id => $refDatasetData->{ds_id},
                       name => $refDatasetData->{name},
                       description => $refDatasetData->{description},
                       readtype => $refDatasetData->{readtype},
                       technology => $refDatasetData->{technology},
                       platform => $refDatasetData->{platform},
                       authors => $refDatasetData->{authors},
                       source => $refDatasetData->{source}};
        my $self = {data => $refData,
                    suppressHeader => $bSuppressHeader};
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
        my ($self) = @_;
        my $tmp = ::decode_json($self->{data}->{authors});
        my $strAuthors = join(',', @{$tmp});
        my $strContent = '';
        if(!$self->{suppressHeader})
        {
            $strContent .= sprintf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                                   "ID",
                                   "Name",
                                   "Description",
                                   "Read type",
                                   "Technology",
                                   "Plaftorm",
                                   "Authors",
                                   "Source");
        }
        $strContent .= sprintf("%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
                                $self->{data}->{id},
                                $self->{data}->{name},
                                $self->{data}->{description},
                                $self->{data}->{readtype},
                                $self->{data}->{technology},
                                $self->{data}->{platform},
                                $strAuthors,
                                $self->{data}->{source});
        return $strContent;
    }
    
    sub asXML
    {
        my ($self) = shift;
        my $strPattern = '<dataset id="%d" name="%s" readtype="%s" technology="%s" platform="%s" source="%s">'.
                            '<authors>';
        my $tmp = ::decode_json($self->{data}->{authors});
        $strPattern .= "<author id=\"$_\" />" foreach @{$tmp};
        $strPattern .= '</authors>%s</dataset>';
        return sprintf($strPattern,
                       $self->{data}->{id},
                       $self->{data}->{name},
                       $self->{data}->{readtype},
                       $self->{data}->{technology},
                       $self->{data}->{platform},
                       $self->{data}->{source},
                       $self->{data}->{description});
    }
}

package Dataset;
{
    my $MODULE = 'Dataset';
    my $VERSION = '3.0.1';
    my $DATE = '2016-04-28';
    
    
    sub getName
    {
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Incapsulates the datasets management";
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
        elsif($strMethod eq lc('getDetails'))
        {
            return $self->getDetails($refMethodParams);
        }
        elsif($strMethod eq lc('add'))
        {
            return $self->add($refMethodParams);
        }
        return undef;
    }
    
    sub find
    {
        my ($self, $refParams) = @_;
	my $strQuery = "SELECT ds_id, ".
                              "Dataset.name AS name, ".
                              "description, ".
                              "enumReadType.name AS readtype, ".
                              "enumTechnology.name AS technology, ".
                              "platform, ".
                              "authors, ".
                              "enumDatasetSource.name AS source ".
                       "FROM Dataset ".
                            "INNER JOIN enumReadType ON enumReadType.e_val=Dataset.read_type ".
                            "INNER JOIN enumTechnology ON enumTechnology.e_val=Dataset.technology ".
                            "INNER JOIN enumDatasetSource ON enumDatasetSource.e_val=Dataset.source";
        if($refParams->{term})
        {
            $refParams->{term} =~ s/'/\\'/;
            $strQuery .= " WHERE Dataset.name LIKE '%$refParams->{term}%' OR ".
                                "platform LIKE '%$refParams->{term}%' OR " .
                                "description LIKE '%$refParams->{term}%'";
        }
        $strQuery .= " ORDER BY ds_id";
        my $stmt = $self->{database}->prepare($strQuery);
        $stmt->execute();
        my $datasetsList = new EntriesList('datasets');
        my $bSuppressHeader = 0;
        while(my $refResult = $stmt->fetchrow_hashref())
        {
            $datasetsList->addEntry(new DatasetEntry($refResult, $bSuppressHeader));
            $bSuppressHeader = 1;
        }
        $stmt->finish();
        return {result => Constants::AORESULT_OK,
                data => $datasetsList};
    }
    
    sub getDetails
    {
        my ($self, $refParams) = @_;
        my $ds_id = int($refParams->{id});
        my $strName = $refParams->{name};
        if(($ds_id < 1) && !$strName)
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "Neither the dataset ID nor the name is specified"};
        }
        my $strQuery = "SELECT ds_id, ".
                              "Dataset.name AS name, ".
                              "description, ".
                              "enumReadType.name AS readtype, ".
                              "enumTechnology.name AS technology, ".
                              "platform, ".
                              "authors, ".
                              "enumDatasetSource.name AS source ".
                       "FROM Dataset ".
                            "INNER JOIN enumReadType ON enumReadType.e_val=Dataset.read_type ".
                            "INNER JOIN enumTechnology ON enumTechnology.e_val=Dataset.technology ".
                            "INNER JOIN enumDatasetSource ON enumDatasetSource.e_val=Dataset.source";
        if($ds_id > 1)
        {
            $strQuery .= " WHERE ds_id=$ds_id";
        }
        else
        {
            $strQuery .= " WHERE Dataset.name = '$strName'";
        }
        my $refResult = $self->{database}->selectrow_hashref($strQuery);
        if($refResult)
        {
            return {result => Constants::AORESULT_OK,
                    data => new DatasetEntry($refResult)};
        }
        return {result => Constants::AORESULT_DATA_NOT_FOUND,
                msg => "The specified dataset does not exist"};
    }
    
    sub add
    {
        my ($self, $refParams) = @_;
        if(!$refParams->{name})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The dataset name is not specified"};
        }
        my ($ds_id) = $self->{database}->selectrow_array("SELECT ds_id FROM Dataset WHERE name='$refParams->{name}'");
        if($ds_id)
        {
            return {result => Constants::AORESULT_DATA_EXISTS,
                    msg => "The specified dataset already exists"};
        }
        if(!$refParams->{description})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The dataset description is not specified"};
        }
        if(!$refParams->{readtype})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The read type is not specified"};
        }
        my $strReadType = lc($refParams->{readtype});
        if(($strReadType ne 'se') && ($strReadType ne 'pe'))
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The read type is not valid"};
        }
        if(!$refParams->{technology})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The technology is not specified"};
        }
        my $strTechnology = lc($refParams->{technology});
        if(($strTechnology ne 'sanger') &&
           ($strTechnology ne 'illumina') &&
           ($strTechnology ne '454') &&
           ($strTechnology ne 'pacbio'))
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The specified technology is not supported"};
        }
        if(!$refParams->{platform})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The platform name is not specified"};
        }
        my $strSrc = lc($refParams->{source});
        if(($strSrc ne 'dna') &&
           ($strSrc ne 'rna'))
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The dataset source is not valid"};
        }
        if(!$refParams->{authors})
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The author IDs are not specified"};
        }
        use AOAPI::web::portal::User;
        my $user = new User();
        $user->init($self->{database});
        my @arrUsers = split(/,/, $refParams->{authors});
        foreach my $user_id (@arrUsers)
        {
            my $refRes = $user->getDetails({id => $user_id});
            if($refRes->{result} != Constants::AORESULT_OK)
            {
                return {result => Constants::AORESULT_INVALID_PARAMETER,
                        msg => "At least one author ID is invalid"};
            }
        }
        $strReadType = ($strReadType eq 'se') ? 'Single end' : 'Paired end';
        my $strQuery = "INSERT INTO Dataset (name, description, read_type, technology, platform, authors, source, restriction) ".
                                    "VALUES (?, ".
                                            "?, ".
                                            "(SELECT e_val FROM enumReadType WHERE name='$strReadType'), ".
                                            "(SELECT e_val FROM enumTechnology WHERE name='$refParams->{technology}'), ".
                                            "?, ".
                                            "?, ".
                                            "(SELECT e_val FROM enumDatasetSource WHERE name='$refParams->{source}'), ".
                                            "?)";
        my $stmt = $self->{database}->prepare($strQuery);
        my $bSucceeded = $stmt->execute($refParams->{name},
                                        $refParams->{description},
                                        $refParams->{platform},
                                        encode_json(\@arrUsers),
                                        int($refParams->{restriction}));
        $stmt->finish();
        if($bSucceeded)
        {
            my ($ds_id) = $self->{database}->selectrow_array("SELECT ds_id FROM Dataset WHERE name='$refParams->{name}'");
            return {result => Constants::AORESULT_OK,
                    data => $ds_id};
        }
        else
        {
            return {result => Constants::AORESULT_FAILURE,
                    msg => "Failed to add the dataset due to an internal error"};
        }
    }
}

1;