#!/usr/bin/env perl

#   File:
#       EntriesList.pm
#
#   Description:
#       Incapsulates the array that can keep multiple return objects.
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
use JSON;


package EntriesList;
{
    sub new
    {
        my ($class, $strListTag) = @_;
        my $self = {entries => [],
                    tag => $strListTag || 'list'};
        bless $self, $class;
        return $self;
    }
    
    sub addEntry
    {
        my ($self, $entry) = @_;
        my @tmp = @{$self->{entries}};
        push(@tmp, $entry);
        $self->{entries} = \@tmp;
    }
    
    sub asBinary
    {
        my $self = shift;
        my @tmp = ();
        push(@tmp, $_->asBinary()) foreach @{$self->{entries}};
        return \@tmp;
    }
    
    sub asJSON
    {
        my $self = shift;
        my @tmp = ();
        push(@tmp, $_->asBinary()) foreach @{$self->{entries}};
        return ::encode_json(\@tmp);
    }
    
    sub asText
    {
        my $self = shift;
        my @tmp = @{$self->{entries}};
        my $strResult = '';
        $strResult .= $_->asText() foreach(@tmp);
        return $strResult;
    }
    
    sub asXML
    {
        my $self = shift;
        my @tmp = @{$self->{entries}};
        my $strResult = "<$self->{tag}>";
        $strResult .= $_->asXML() foreach(@tmp);
        $strResult .= "</$self->{tag}>";
        return $strResult;
    }
}

1;