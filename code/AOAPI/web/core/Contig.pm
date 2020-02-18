#!/usr/bin/env perl

#   File:
#       Contig.pm
#
#   Description:
#       Manages the contigs.
#
#   Version:
#       3.0.1
#
#   Date:
#       2016-04-26
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use DBI;
use JSON;
use AOAPI::core::Constants;


package Contig;
{
    my $MODULE = 'Contig';
    my $VERSION = '3.0.1';
    my $DATE = '2016-04-26';
    
    
    sub getName
    {
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Incapsulates the contigs management";
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
        return undef;
    }
}

1;
