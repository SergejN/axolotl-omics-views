#!/usr/bin/env perl

#   File:
#       RawSequence.pm
#
#   Description:
#       Manages the raw reads.
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


package Contig;
{
    my $MODULE = 'RawRead';
    my $VERSION = '3.0.1';
    my $DATE = '2016-04-28';
    
    
    sub getName
    {
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Incapsulates the raw reads management";
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
        if($strMethod eq 'find')
        {
            
        }
        else
        {
            return {result => Constants::AORESULT_METHOD_NOT_FOUND,
                    msg => "The method '$MODULE.$refParams->{_method}' was not found"};
        }
    }
}

1;
