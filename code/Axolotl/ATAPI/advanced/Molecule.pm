#!/usr/bin/env perl

#   File:
#       Molecule.pm
#
#   Description:
#       Contains the Molecule advanced module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       07.11.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;
use File::Temp;


package Molecule;
{
    my $MODULE = 'Molecule';
    my $VERSION = '1.0.1';
    my $DATE = '2014-11-07';
    
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
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Encapsulates several methods related to the details about the molecule";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'predictSecondaryStructure',
                           _description => 'Calculates the secondary structure of the RNA molecule',
			   _args => [{_name => 'seqID',
                                      _description => 'ID of the sequence to calculate secondary structure for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK_BINARY',
                                            _numval => Constants::ERR_OK_BINARY,
                                            _description => 'If succeeds. The returned data represent the SVG image'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no sequence ID is specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If the sequence with the specified ID does no exist'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.predictSecondaryStructure&seqID=AC_02200035550.2"});
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
        if($strMethod eq 'predictSecondaryStructure')
        {
            return $self->predictSecondaryStructure($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub predictSecondaryStructure
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{seqID})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No sequence ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
	}
        $refParams->{seqID} =~ s/'//g;
	my ($strSeq) = $self->{_db}->selectrow_array("SELECT sequence FROM Contig WHERE name='$refParams->{seqID}'");
	if(!$strSeq)
	{
	    ($strSeq) = $self->{_db}->selectrow_array("SELECT sequence FROM LibrarySequence WHERE name='$refParams->{seqID}'");
	}
	if(!$strSeq)
	{
	    $xmlerr->addChild($xmldoc->createTextNode("The sequence with the specified ID could not be found"));
            return Constants::ERR_DATA_NOT_FOUND;
	}
	my $hFile = File::Temp->new(UNLINK => 1, SUFFIX => '.fa');
	print $hFile ">$refParams->{seqID}\n$strSeq\n";
	my $strFilename = $hFile->filename;
	my $strCMD = "cd /tmp; RNAfold < $strFilename | RNAplot -o svg";
	`$strCMD`;
	print "Content-type:image/svg+xml\n\n";
	$strFilename = "/tmp/$refParams->{seqID}_ss.svg";
	open(SVG, $strFilename);
	while(<SVG>)
	{
	    print "$_";
	}
	close(SVG);
	unlink($strFilename);
        return Constants::ERR_OK_BINARY;
    }
}

1;