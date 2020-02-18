#!/usr/bin/env perl

#   File:
#       Pathway.pm
#
#   Description:
#       Contains the Pathway analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       20.05.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use Storable;

use Axolotl::ATAPI::Constants;


package Pathway;
{
    my $MODULE = 'Pathway';
    my $VERSION = '1.0.1';
    my $DATE = '2014-05-20';
    
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
	$self->{_root} = $ps->getSetting('PATHWAY', 'root');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Retrieves the details about the well-characterized pathways.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }

    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'getOrganismsList',
                           _description => 'Retrieves the list of organisms the pathway information is available for',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getOrganismsList"},
			  
			  {_name => 'getList',
                           _description => 'Retrieves the list of available pathways',
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getList"},

			  {_name => 'getPathwayDetails',
                           _description => 'Retrieves the details about the specified pathways: name, description and participating genes',
                           _args => [{_name => 'pathways',
                                      _description => 'Comma-separated list of pathway IDs',
                                      _type => 'required',
                                      _default => ''},
				     {_name => 'organisms',
                                      _description => 'Comma-separated list of organisms to fetch details for',
                                      _type => 'optional',
                                      _default => 'all available organisms'},
				     {_name => 'assembly',
                                      _description => 'Version of the assembly to use when retrieving the Axolotl homologs',
                                      _type => 'optional',
                                      _default => 'current assembly'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no pathway IDs were specified'},],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getPathwayDetails&pathways=P04398",
			   _remarks => "If no pathway IDs are specified the behaviour of the method is identical with that of '$MODULE.getList'."},
			  
			  {_name => 'findPathways',
                           _description => 'Retrieves the list of pathways for each specified contig',
                           _args => [{_name => 'contigs',
                                      _description => 'Comma-separated list of contig IDs',
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
					   {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig IDs were specified'},],
                           _sample => "$refParams->{_base}/api?method=$MODULE.findPathways&contigs=NT_02200014625.1"});
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
	if($strMethod eq 'getOrganismsList')
        {
            return $self->getOrganismsList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getList')
        {
            return $self->getList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getPathwayDetails')
        {
            return $self->getPathwayDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'findPathways')
        {
            return $self->findPathways($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getOrganismsList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my $strCMD = "find $self->{_root} -maxdepth 1 -mindepth 1 -type d | rev | cut -d\"/\" -f1 | rev";
	open(IN, "$strCMD |");
	while(<IN>)
	{
	    chomp();
	    my $organism = $xmldoc->createElement('organism');
	    $organism->addChild($xmldoc->createAttribute(name => $_));
	    $strCMD = "find $self->{_root}/$_ -type f | wc -l";
	    open(LIST, "$strCMD |");
	    my $nCount = int(<LIST>);
	    close(LIST);
	    $organism->addChild($xmldoc->createAttribute(pathways => $nCount));
	    $xmldata->addChild($organism);
	}
	close(IN);
	return Constants::ERR_OK;
    }
    
    sub getList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my $strQuery = "SELECT name, description FROM Pathway";
	my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $pathway = $xmldoc->createElement('pathway');
	    $pathway->addChild($xmldoc->createAttribute(name => $refResult->{name}));
	    $pathway->addChild($xmldoc->createTextNode($refResult->{description}));
	    $xmldata->addChild($pathway);
	}
	return Constants::ERR_OK;
    }
    
    sub getPathwayDetails
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my @arrPathways = split(/,/, $refParams->{pathways});
	if((scalar @arrPathways)==0)
	{
	    return $self->getList($refParams, $xmldoc, $xmldata, $xmlerr);
	}
	# First, get the list of organisms.
	my $strCMD = "find $self->{_root} -maxdepth 1 -mindepth 1 -type d | rev | cut -d\"/\" -f1 | rev";
	my %hmAllOrganisms = ();
	open(IN, "$strCMD |");
	while(<IN>)
	{
	    chomp();
	    $hmAllOrganisms{$_} = 1;
	}
	close(IN);
	my @arrOrganisms = split(/,/, $refParams->{organisms});
	@arrOrganisms = keys(%hmAllOrganisms) if(!@arrOrganisms);
	# Iterate through the list of pathways and retrieve details for each organism.
	foreach my $strPW (@arrPathways)
	{
	    my $pathway = $xmldoc->createElement('pathway');
	    $pathway->addChild($xmldoc->createAttribute(name => $strPW));
	    my $nAdded = 0;
	    foreach my $strOrganism (@arrOrganisms)
	    {
		next if(!$hmAllOrganisms{$strOrganism});
		my $strFile = "$self->{_root}/$strOrganism/$strPW.$strOrganism.dat";
		next if(!-e $strFile);
		my $organism = $xmldoc->createElement('organism');
		$organism->addChild($xmldoc->createAttribute(name => $strOrganism));
		my $refData = Storable::retrieve($strFile);
		foreach my $item (@{$refData->{members}})
		{
		    my $member = $xmldoc->createElement('member');
		    $member->addChild($xmldoc->createAttribute(symbol => $item->{symbol}));
		    $member->addChild($xmldoc->createAttribute(id => $item->{id}));
		    $member->addChild($xmldoc->createTextNode($item->{desc}));
		    foreach my $acc (@{$item->{ids}})
		    {
			$member->addChild($xmldoc->createAttribute($acc->{source} => $acc->{value}));
		    }
		    $organism->addChild($member);
		}
		$pathway->addChild($organism);
		$nAdded++;
	    }
	    $xmldata->addChild($pathway) if($nAdded>0);
	}
	return Constants::ERR_OK;
    }
    
    sub findPathways
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my @arrContigs = (defined $refParams->{contigs}) ? split(/,/, $refParams->{contigs}) : ();
	if((scalar @arrContigs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contigs specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	foreach(@arrContigs)
	{
	    $_=~ s/'//g;
	    my $contig = $xmldoc->createElement('contig');
	    $contig->addChild($xmldoc->createAttribute(id => $_));
	    my $nAdded = 0;
	    # Find the homologous RefSeq sequences.
	    my $strQuery = "SELECT Pathway.name AS pwname, ".
				  "Pathway.description AS pwdesc ".
	                   "FROM Contig ".
			        "INNER JOIN Alignment ON Contig.c_id=Alignment.c_id ".
				"INNER JOIN RefSeq ON Alignment.rs_id=RefSeq.rs_id ".
				"INNER JOIN PathwayMember ON RefSeq.rs_id=PathwayMember.rs_id ".
				"INNER JOIN Pathway ON PathwayMember.pw_id=Pathway.pw_id ".
			   "WHERE Contig.name='$_' GROUP BY Pathway.name";	   
	    my $statement = $self->{_db}->prepare($strQuery);
	    $statement->execute();
	    while(my $refResult = $statement->fetchrow_hashref())
	    {
		my $pathway = $xmldoc->createElement('pathway');
		$pathway->addChild($xmldoc->createAttribute(id => $refResult->{pwname}));
		$pathway->addChild($xmldoc->createTextNode($refResult->{pwdesc}));
		$contig->addChild($pathway);
		$nAdded++;
	    }
	    $xmldata->addChild($contig) if($nAdded>0);
	}
	return Constants::ERR_OK;
    }
    
}

1;