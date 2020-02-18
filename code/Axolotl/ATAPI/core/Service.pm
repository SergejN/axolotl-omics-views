#!/usr/bin/env perl

#   File:
#       Service.pm
#
#   Description:
#       Contains the Service core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.7
#
#   Date:
#       19.06.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Service;
{
    my $MODULE = 'Service';
    
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
        my ($self, $hDB, $fnAddNodes) = @_;
        $self->{_db} = $hDB;
        $self->{_fnAddNodes} = $fnAddNodes;
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Facilitates service tasks";
    }
    
    sub skipDocumentation
    {
        return 1;
    }
    
    sub execute
    {
        my ($self, %hmParams) = @_;
        my $strMethod = $hmParams{_method};
        my $refMethodParams = $hmParams{_parameters};
        my $xmldoc = $hmParams{_xmldoc};
        my $xmldata = $hmParams{_xmldata};
        my $xmlerr = $hmParams{_xmlerr};
        # First, check if the DB is available.
        if(!defined $self->{_db})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Error connecting to the database. Please retry"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        # Execute the method.
        if($strMethod eq 'listAuthors')
        {
            return $self->listAuthors($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    # Private module methods.
    sub listAuthors
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my %hmFields = ('id' => {_column => 'au_id', _type => Constants::NT_ATTRIBUTE},
                        'name' => {_column => 'name', _type => Constants::NT_ATTRIBUTE},
                        'title' => {_column => 'title', _type => Constants::NT_ATTRIBUTE},
                        'email' => {_column => 'email', _type => Constants::NT_ATTRIBUTE},
                        'affiliation' => {_column => 'affiliation', _type => Constants::NT_ATTRIBUTE},
                        'street' => {_column => 'street', _type => Constants::NT_ATTRIBUTE},
                        'zip' => {_column => 'zip', _type => Constants::NT_ATTRIBUTE},
                        'city' => {_column => 'city', _type => Constants::NT_ATTRIBUTE},
                        'country' => {_column => 'country', _type => Constants::NT_ATTRIBUTE});
        my $strQuery = "SELECT * FROM Author;";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        my $refResult = undef;
        while($refResult = $statement->fetchrow_hashref())
        {
            my $author = $xmldoc->createElement('author');
            $self->{_fnAddNodes}->($xmldoc, $author, \%hmFields, $refResult);
            $xmldata->addChild($author);
        }
        return Constants::ERR_OK;
    }
 
}
    
1;
