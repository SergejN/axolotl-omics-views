#!/usr/bin/env perl

#   File:
#       ArgParser.pm
#
#   Description:
#       Parses the command line arguments
#
#   Version:
#       2.0.1
#
#   Date:
#       2016-04-22
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;


package ArgParser;
{   
    sub new
    {
        my ($class, $refArgs) = @_;
        $refArgs = \@ARGV if(!$refArgs);
        my $self = {options => {}};

        my $strCurrent = 'DEFAULT';
        foreach my $strOpt (@{$refArgs})
        {
            chomp($strOpt);
            if($strOpt =~ m/^--?([^\s\t]+)$|^-([A-Za-z])$/)
            {
                if($strCurrent ne $1)
                {
                    $strCurrent = $1;
                    $self->{options}->{$strCurrent} = [];
                }
            }
            else
            {
                my @arrParams = @{$self->{options}->{$strCurrent}};
                push(@arrParams, $strOpt);
                $self->{options}->{$strCurrent} = \@arrParams;
            }
        }
        bless $self, $class;
        return $self;
    }
    
    sub getOption
    {
        my ($self, $strKey) = @_;
        return $self->_getOptions($strKey, 0);
    }
    
    sub getOptions
    {
        my ($self, $strKey) = @_;
        return $self->_getOptions($strKey, 1);
    }
    
    sub getOptionsCount
    {
        my ($self) = shift;
        return scalar keys %{$self->{options}};
    }
    
    sub isSet
    {
        my ($self, $strKey) = @_;
        my @arrKeys = split(/\|/, $strKey);
        foreach(@arrKeys)
        {
            return 1 if(exists $self->{options}->{$_});
        }
        return 0;
    }
    
    
    ################## Private method ##################
    sub _getOptions
    {
        my ($self, $strKey, $bAsArrayRef) = @_;
        my @arrKeys = split(/\|/, $strKey);
        foreach(@arrKeys)
        {
            my $refVals = $self->{options}->{$_};
            if($refVals)
            {
                return ($bAsArrayRef) ? $refVals : @{$refVals}[0];
            }
        }
        return undef;
    }
}

1;