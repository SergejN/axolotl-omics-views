#!/usr/bin/env perl

#   File:
#       Insitu.pm
#
#   Description:
#       Contains the In-situ analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.10
#
#   Date:
#       30.05.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Insitu;
{
    my $MODULE = 'Insitu';
    my $VERSION = '1.0.10';
    my $DATE = '2013-08-05';
    
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
	$self->{_rootdir} = $ps->getSetting('INSITU', 'root');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the data related to in-situ analyses.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
	my $strExampleContig = 'NT_010001269873.2';
        my @arrMethods = ({_name => 'getExperimentsList',
                           _description => 'Returns the list of available experiments',
			   _args => [{_name => 'contigs',
                                      _description => 'Comma-separated list of contig IDs to retrieve experiments list for',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig ID specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getExperimentsList&contigs=$strExampleContig"},
			  
			  {_name => 'getImage',
                           _description => 'Returns the specified image encoded as base64 string',
			   _args => [{_name => 'contig',
                                      _description => 'Name of the contig to retrieve image for',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'experiment',
                                      _description => "Experiment date. Must be one of the values returned by $MODULE.getExperimentsList for this contig",
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'index',
                                      _description => '1-based image index',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If contig, experiment or index is not specified'},
					   {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no in-situ images are available for the specified contig, experiment or index'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getImage&contig=$strExampleContig&experiment=1&index=1"});
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
        if($strMethod eq 'getExperimentsList')
        {
            return $self->getExperimentsList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getImage')
        {
            return $self->getImage($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getExperimentsList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrContigs = (defined $refParams->{contigs}) ? split(/,/, $refParams->{contigs}) : ();
        if((scalar @arrContigs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$_=~ s/'/\\'/g foreach @arrContigs;
        foreach my $strContig (@arrContigs)
        {
            # Determine the name of the gene root directory.
            my $strQuery = "SELECT rootdir FROM Insitu WHERE c_id=(SELECT c_id FROM Contig WHERE name='$strContig');";
            my $refResult = $self->{_db}->selectrow_hashref($strQuery);
            next unless $refResult;
            # Create the contig entry and list the experiments.
            my $contig = $xmldoc->createElement('contig');
            $contig->addChild($xmldoc->createAttribute(name => $strContig));
            my $directory = "$self->{_rootdir}/$refResult->{rootdir}";
            my $nExperiments = 0;
            opendir(DIR, $directory);
            while (my $file = readdir(DIR))
            {
                if($file =~ m/([0-9]{4})([0-9]{2})([0-9]{2})/)
                {
                    $nExperiments++;
                    my $experiment = $xmldoc->createElement('experiment');
                    $experiment->addChild($xmldoc->createAttribute(date => "$1-$2-$3"));
                    $experiment->addChild($xmldoc->createTextNode("Experiment $nExperiments"));
                    # Count the number of images in the experiment.
                    my $subdir = "$directory/$file";
                    my $nImages = 0;
                    opendir(SUBDIR, $subdir);
                    while (my $img = readdir(SUBDIR))
                    {
                        $nImages++ if($img =~ m/^[^\.].+\.jpg$/);
                    }
                    closedir(SUBDIR);
                    $experiment->addChild($xmldoc->createAttribute(images => $nImages));
                    $contig->addChild($experiment);
                }
            }
            closedir(DIR);
            $xmldata->addChild($contig);
        }
        return Constants::ERR_OK;
    }
    
    sub getImage
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{contig})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$refParams->{contig} =~ s/'/\\'/g;
        if(!$refParams->{experiment})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No experiment date specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	$refParams->{experiment} =~ s/'/\\'/g;
        if((!$refParams->{index}) || !(int($refParams->{index})>0))
        {
            $xmlerr->addChild($xmldoc->createTextNode("No image index specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        # Determine the name of the gene root directory.
        my $strQuery = "SELECT rootdir FROM Insitu WHERE c_id=(SELECT c_id FROM Contig WHERE name='$refParams->{contig}');";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No in-situ images are available for the specified contig"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strExpDate = $refParams->{experiment};
        $strExpDate =~ s/-//g;
        my $directory = $self->{_rootdir} . '/' . $refResult->{rootdir} . '/' . $strExpDate;
        if(! -e $directory)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified experiment does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strFilename = undef;
        my $nImages = 0;
        my $strImgFile = undef;
        opendir(DIR, $directory);
        while (my $file = readdir(DIR))
        {
            $nImages++ if($file =~ m/^[^\.].+\.jpg$/);
            if($nImages == $refParams->{index})
            {
                $strFilename = "$directory/$file";
                $strImgFile = $file;
                last;
            }
        }
        closedir(DIR);
        if(!$strFilename)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified image does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        use MIME::Base64;
        my $strContent = "";
        # If the dimensions are specified, resize the image.
        if($refParams->{width} && $refParams->{height})
        {
            my $strCmd = "convert $strFilename -resize $refParams->{width}x$refParams->{height} -";
            open(OUT, "$strCmd |");
            $strContent .= $_ while(<OUT>);
            close(OUT);
        }
        else
        {
            open(IMAGE, $strFilename);
            $strContent = do{ local $/ = undef; <IMAGE>; };
            close(IMAGE);
        }
        # Try to deduce the image description.
        my $strDescription = $strImgFile;
        my @arrChunks = split(/_/, $strImgFile);
        my $strTime = $arrChunks[2];
        if( ($strTime =~ m/^([0-9]+)d$/) ||
            ($strTime =~ m/^([0-9]+)d([a-zA-Z]+)$/))
        {
            my $strChunk = ($2) ? $2 : $arrChunks[3];
            my $strType = undef;
            if($strChunk eq 'amp')
            {
                $strType = 'amputation';
            }
            elsif($strChunk eq 'dnv')
            {
                $strType = 'denervated limb';
            }
            elsif($strChunk eq 'bl')
            {
                $strType = 'blastema';
            }
            elsif($strChunk eq 'lw')
            {
                $strType = 'lateral wound';
            }
            elsif($strChunk eq 'mature')
            {
                $strType = 'mature';
            }
            if($strType)
            {
                $strDescription = "Type: $strType, timepoint: $1d";
            }
        }
        my $strEncoded = encode_base64($strContent);
        my $contig = $xmldoc->createElement('contig');
        $contig->addChild($xmldoc->createAttribute(name => $refParams->{contig}));
        $contig->addChild($xmldoc->createAttribute(experiment => $refParams->{experiment}));
        $contig->addChild($xmldoc->createAttribute(index => $refParams->{index}));
        $contig->addChild($xmldoc->createAttribute(MIME => 'image/jpg'));
        $contig->addChild($xmldoc->createAttribute(encoding => 'base64'));
        $contig->addChild($xmldoc->createAttribute(description => $strDescription));
        $contig->addChild($xmldoc->createTextNode($strEncoded));
        $xmldata->addChild($contig);
        return Constants::ERR_OK;
    }
}

1;
