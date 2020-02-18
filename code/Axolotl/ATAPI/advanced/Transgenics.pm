#!/usr/bin/env perl

#   File:
#       Transgenics.pm
#
#   Description:
#       Contains the Transgenics advanced module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       30.09.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Transgenics;
{
    my $MODULE = 'Transgenics';
    
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
        $self->{_imgroot} = $ps->getSetting('TRANSGENICS', 'Images');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Encapsulates methods for accessing the transgenic lines details";
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
        # Execute the method.
        if($strMethod eq 'listTransgenicLines')
        {
            return $self->listTransgenicLines($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getTransgenicLineImage')
        {
            return $self->getTransgenicLineImage($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getTransgenicLineFile')
        {
            return $self->getTransgenicLineFile($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub listTransgenicLines
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $lines = $xmldoc->createElement('lines');
        my $strQuery = "SELECT TransgenicLine.name AS tlname, ".
                              "TransgenicLine.construct AS construct, ".
                              "TransgenicLine.promoter AS promoter, ".
                              "TransgenicLine.cassette AS cassette, ".
                              "TransgenicLine.tissue AS tissue, ".
                              "TransgenicLine.reference AS ref, ".
                              "TransgenicLine.remarks AS remarks, ".
                              "Author.name AS aname, ".
                              "Author.email AS email ".
                       "FROM TransgenicLine ".
                            "INNER JOIN Author ON TransgenicLine.au_id=Author.au_id;";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $line = $xmldoc->createElement('line');
            $line->addChild($xmldoc->createAttribute('name' => $refResult->{tlname}));
            $line->addChild($xmldoc->createAttribute('construct' => $refResult->{construct}));
            $line->addChild($xmldoc->createAttribute('promoter' => $refResult->{promoter}));
            $line->addChild($xmldoc->createAttribute('cassette' => $refResult->{cassette}));
            $line->addChild($xmldoc->createAttribute('tissue' => $refResult->{tissue}));
            $line->addChild($xmldoc->createAttribute('author' => $refResult->{aname}));
            $line->addChild($xmldoc->createAttribute('reference' => $refResult->{ref}));
            $line->addChild($xmldoc->createAttribute('email' => $refResult->{email}));
            $line->addChild($xmldoc->createTextNode($refResult->{remarks}));
            $lines->addChild($line);
        }
        $xmldata->addChild($lines);
        return Constants::ERR_OK;
    }
    
    sub getTransgenicLineImage
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{line})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No line name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strFilename = (exists $refParams->{preview}) ? "$self->{_imgroot}/$refParams->{line}/".$refParams->{line}."_preview.jpg"
                                                         : "$self->{_imgroot}/$refParams->{line}/".$refParams->{line}."_full.jpg";
        if(! -e $strFilename)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified line '$refParams->{line}' does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        print "Content-type: image/jpeg\n\n";
        open(IMAGE, $strFilename);
        my $buff;
        while(read IMAGE, $buff, 1024)
        {
            print $buff;
        }
        close IMAGE;
        return Constants::ERR_OK_BINARY;
    }
    
    sub getTransgenicLineFile
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        # First, check the privilege.
        my $privilege = $refParams->{_user}->{privilege};
        if(!($privilege & Constants::UP_INTERNAL))
        {
            $xmlerr->addChild($xmldoc->createTextNode("Access denied! You cannot download this file"));
            return Constants::ERR_ACCESS_DENIED;
        }
        if(!$refParams->{line})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No line name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strFilename = "$self->{_imgroot}/$refParams->{line}/" . $refParams->{line} . ".gcc";
        if(! -e $strFilename)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified line '$refParams->{line}' does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        print "Content-disposition:attachment;filename=$refParams->{line}.gcc;";
        print "Content-type:application/octet-stream\n\n";
        open(FILE, $strFilename);
        my $buff;
        while(read FILE, $buff, 1024)
        {
            print $buff;
        }
        close FILE;
        return Constants::ERR_OK_BINARY;
    }
}

1;