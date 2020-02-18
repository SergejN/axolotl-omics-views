#!/usr/bin/env perl

#   File:
#       Database.pm
#
#   Description:
#       Contains the Database core module of the Axolotl-Omics API (AOAPI).
#
#   Version:
#       3.0.1
#
#   Date:
#       2016-04-22
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use AOAPI::utils::ArgParser;


package Database;
{
    my $MODULE = 'Database';
    my $VERSION = '3.0.1';
    my $DATE = '2016-22-04';
    
    sub new
    {
        my $class = shift;
        my $self = {_db => undef};
        bless $self, $class;
        return $self;
    }
    
    # Common plug-in methods.
    sub init
    {
        my ($self, $hDB) = @_;
        $self->{_db} = $hDB;
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the details about the database";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
}

1;