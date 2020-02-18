#!/usr/bin/env perl

#   File:
#       Contig.pm
#
#   Description:
#       Contains the Contig core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.20
#
#   Date:
#       16.01.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Contig;
{
    my $MODULE = 'Contig';
    my $VERSION = '1.0.20';
    my $DATE = '2014-06-15';
    
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
       return "Retrieves the basic details about the contig, such as name, length, sequence, ORF, homologs and annotation.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my $strExampleContig = 'NT_01000010432.2';
        my @arrMethods = ({_name => 'getSummary',
                           _description => 'Returns the contig sequence, ORF details, annotation, and general details about the assembly this contig belongs to',
                           _args => [{_name => 'contigs',
                                        _description => 'Comma-separated list of contig IDs to retrieve information for',
                                        _type => 'required',
                                        _default => ''},
                                       {_name => 'values',
                                        _description => 'Comma-separated list of values to retrieve. Must be combination of "sequence", "assembly", "orf", and "annotation"',
                                        _type => 'optional',
                                        _default => 'sequence,assembly,annotation,orf'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig IDs are specified'},
                                           {_value => 'Constants::ERR_INVALID_PARAMETER',
                                            _numval => Constants::ERR_INVALID_PARAMETER,
                                            _description => 'If an invalid value is specified in "values" argument'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getSummary&contigs=$strExampleContig&values=sequence,assembly,annotation,orf",
			   _remarks => "The resulting XML only contains entries for valid contig IDs."},
                          
                          {_name => 'getAnnotation',
                           _description => 'Returns the annotation of the contig(s)',
                           _args => [{_name => 'contigs',
                                        _description => 'Comma-separated list of contig IDs to retrieve annotation for',
                                        _type => 'required',
                                        _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig IDs are specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getAnnotation&contigs=$strExampleContig",
			   _remarks => "No entry is created in the resulting XML if the contig ID is invalid or if the contig has no annotation."},
			  
			  {_name => 'getGene',
                           _description => 'Returns the name of the genes the specified transcripts are annotated to',
                           _args => [{_name => 'contigs',
                                        _description => 'Comma-separated list of contig IDs to retrieve genes for',
                                        _type => 'required',
                                        _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig IDs are specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getGene&contigs=$strExampleContig"});
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
        if($strMethod eq 'getSummary')
        {
            return $self->getSummary($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getAnnotation')
        {
            return $self->getAnnotation($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'getGene')
        {
            return $self->getGene($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    # Private module methods.
    sub getSummary
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrContigs = (defined $refParams->{contigs}) ? split(/,/, $refParams->{contigs}) : ();
        my @arrValues = ($refParams->{values} && length($refParams->{values})>0) ? split(/,/, $refParams->{values}) : ('sequence', 'assembly', 'annotation', 'orf');
        # Escape quotes in the contig and field names.
	$_=~ s/'/\\'/g foreach @arrContigs;
        $_=~ s/'/\\'/g foreach @arrValues;
        # Contig IDs.
        if((scalar @arrContigs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        # Check if the specified values are valid.
        my %hmValues = ('LENGTH(sequence) AS length' => 1,
                        'alias' => 1,
			'features' => 1,
			'datamask' => 1,
			'verified' => 1);
        my $bGetAssembly = 0;
        my $bGetORF = 0;
        my $bGetAnnotation = 0;
        foreach my $strValue (@arrValues)
        {
            my $strValue_lc = lc($strValue);
            if($strValue_lc eq 'sequence')
            {
                $hmValues{'sequence'}++;
            }
            elsif($strValue_lc eq 'assembly')
            {
                $hmValues{'a_id'}++;
                $bGetAssembly=1;
            }
            elsif($strValue_lc eq 'annotation')
            {
                $hmValues{'an_id'}++;
                $bGetAnnotation=1;
            }
            elsif($strValue_lc eq 'orf')
            {
                $hmValues{'c_id'}++;
                $bGetORF=1;
            }
            else
            {
                $xmlerr->addChild($xmldoc->createTextNode("Invalid parameter: '$strValue'"));
                return Constants::ERR_INVALID_PARAMETER;
            }
        }
        # Iterate through the contig names.
        my %hmFields_general = ('name' => {_column => 'name', _type => Constants::NT_ELEMENT},
                                'alias' => {_column => 'alias', _type => Constants::NT_ATTRIBUTE},
                                'length' => {_column => 'length', _type => Constants::NT_ATTRIBUTE},
				'features' => {_column => 'features', _type => Constants::NT_ATTRIBUTE},
				'verified' => {_column => 'verified', _type => Constants::NT_ATTRIBUTE, _replace => {0 => 'false', 1 => 'true'}},
                                'sequence' => {_column => 'sequence', _type => Constants::NT_ELEMENT});
        my %hmFields_assembly = ('name' => {_column => 'name', _type => Constants::NT_ELEMENT},
                                 'version' => {_column => 'version', _type => Constants::NT_ATTRIBUTE});
        my %hmFields_orf = ('sequence' => {_column => 'sequence'},
                            'start' => {_column => 'start', _type => Constants::NT_ATTRIBUTE},
                            'class' => {_column => 'class', _type => Constants::NT_ATTRIBUTE},
                            'description' => {_column => 'description', _type => Constants::NT_ATTRIBUTE});
        my %hmFields_annotation = ('symbol' => {_column => 'symbol', _type => Constants::NT_ELEMENT},
                                   'definition' => {_column => 'definition', _type => Constants::NT_ELEMENT},
				   'remarks' => {_column => 'remarks', _type => Constants::NT_ELEMENT});
        my $strColumns = join(',', keys %hmValues);
	my %hmPrefixes = ('AC' => {name => 'Assembled contig', description => 'The sequence orientation is supported by the read data'},
                          'PA' => {name => 'Potential artifact', description => 'The orientation of the reads is ambiguous'},
                          'UC' => {name => 'Uncertain contig', description => 'There is not enough data to determine the proper sequence orientation'},
                          'VB' => {name => 'Vector backbone', description => 'The contig contains the vector backbone sequence and is likely to represent a contamination'},
                          'BC' => {name => 'Bacterial contamination', description => 'The contig is likely to represent a transcript of bacterial origin'});
        foreach my $strContig (@arrContigs)
        {
            # Prepare the SQL statement and retrieve the contig entries.
            my $strQuery = "SELECT $strColumns FROM Contig WHERE name='$strContig';";
            my $statement = $self->{_db}->prepare($strQuery);
            $statement->execute();
            my $refResult = $statement->fetchrow_hashref();
            next if(!$refResult);
            my $contig = $xmldoc->createElement('contig');
            $contig->addChild($xmldoc->createAttribute(name => $strContig));
	    # Contig naming.
	    my $strPrefix = substr($strContig,0,2);
	    my $refPrefix = $hmPrefixes{$strPrefix};
	    if($refPrefix)
	    {
		my $naming = $xmldoc->createElement('naming');
		$naming->addChild($xmldoc->createAttribute(abbreviation => $strPrefix));
		$naming->addChild($xmldoc->createAttribute(name => $refPrefix->{name}));
		$naming->addChild($xmldoc->createTextNode($refPrefix->{description}));
		$contig->addChild($naming);
	    }
            # General contig details.
            $self->{_fnAddNodes}->($xmldoc, $contig, \%hmFields_general, $refResult);
            # Assembly.
            if($bGetAssembly)
            {
                $strQuery = "SELECT name, version FROM Assembly WHERE a_id=$refResult->{'a_id'};";
                my $contig_assembly = $xmldoc->createElement('assembly');
                $self->{_fnAddNodes}->($xmldoc, $contig_assembly, \%hmFields_assembly, $self->{_db}->selectrow_hashref($strQuery));
                $contig->addChild($contig_assembly);
            }
            # ORF.
            if($bGetORF)
            {
                $strQuery = "SELECT ORF.sequence AS sequence, ".
				   "ORF.start AS start, ".
				   "ORFType.name AS class, ".
				   "ORFType.description AS description ".
			    "FROM ORF ".
				 "INNER JOIN ORFType ON ORF.orft_id=ORFType.orft_id ".
			    "WHERE c_id=$refResult->{c_id};",
                my $contig_orf = $xmldoc->createElement('orf');
                if($self->{_fnAddNodes}->($xmldoc, $contig_orf, \%hmFields_orf, $self->{_db}->selectrow_hashref($strQuery)))
                {
                    $contig->addChild($contig_orf);
                }
            }
            # Annotation.
            if($bGetAnnotation)
            {
                $strQuery = "SELECT Annotation.symbol,".
		                   "Annotation.definition, ".
				   "remarks, " .
				   "Molecule.name AS molecule, ".
				   "Molecule.description AS mdesc ".
			    "FROM Annotation ".
			         "INNER JOIN Molecule ON Annotation.m_id=Molecule.m_id ".
			    "WHERE an_id=$refResult->{'an_id'}";    
                my $contig_annotation = $xmldoc->createElement('annotation');
		my $refAnnot = $self->{_db}->selectrow_hashref($strQuery);
                if($self->{_fnAddNodes}->($xmldoc, $contig_annotation, \%hmFields_annotation, $refAnnot))
                {
		    my $molecule = $xmldoc->createElement('molecule');
		    $molecule->addChild($xmldoc->createAttribute(type => $refAnnot->{molecule}));
		    $molecule->addChild($xmldoc->createTextNode($refAnnot->{mdesc}));
		    $contig_annotation->addChild($molecule);
                    $contig->addChild($contig_annotation);
                }
            }
            $xmldata->addChild($contig);
        }
        return Constants::ERR_OK;
    }

    sub getAnnotation
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrContigs = (defined $refParams->{contigs}) ? split(/,/, $refParams->{contigs}) : ();
        # Contig names.
        if((scalar @arrContigs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $_=~ s/'/\\'/g foreach @arrContigs;
        my %hmFields = ('symbol' => {_column => 'symbol', _type => Constants::NT_ELEMENT},
                        'definition' => {_column => 'definition', _type => Constants::NT_ELEMENT},
                        'date' => {_column => 'date', _type => Constants::NT_ATTRIBUTE},
                        'remarks' => {_column => 'remarks', _type => Constants::NT_ELEMENT},
                        'author' => {_column => 'author', _type => Constants::NT_ATTRIBUTE},
                        'molecule' => {_column => 'molecule', _type => Constants::NT_ATTRIBUTE},
                        'basis' => {_column => 'basis', _type => Constants::NT_ATTRIBUTE},
                        'index' => {_column => 'index', _type => Constants::NT_ATTRIBUTE});
        # Iterate through the contig IDs.
        foreach my $strContig (@arrContigs)
        {
            # First, retrieve an_id. If it is NULL, then the contig does not have any annotation.
            my $strQuery = "SELECT an_id FROM Contig WHERE name='$strContig'";
            my $refResult = $self->{_db}->selectrow_hashref($strQuery);
            next if !$refResult;
            my $contig = $xmldoc->createElement('contig');
            $contig->addChild($xmldoc->createAttribute(name => $strContig));
            if(!$refResult->{an_id})
            {
                $contig->addChild($xmldoc->createTextNode('No annotation available'));
            }
            else
            {
                $strQuery = "SELECT Annotation.symbol AS symbol, ".
		                   "Annotation.definition AS definition, ".
				   "Annotation.date AS date, ".
				   "Annotation.remarks AS remarks, ".
				   "Annotation.previous AS prev, " .
                                   "Author.name AS author, " .
                                   "Molecule.name AS molecule " .
                            "FROM Annotation INNER JOIN Author ON Annotation.au_id=Author.au_id " .
                                            "INNER JOIN Molecule ON Annotation.m_id=Molecule.m_id " .
                            "WHERE an_id=$refResult->{an_id};";
                $refResult = $self->{_db}->selectrow_hashref($strQuery);
                my $iIndex = 1;
                while($refResult)
                {
                    my $annotation = $xmldoc->createElement('annotation');
                    $refResult->{index} = $iIndex;
                    $refResult->{basis} = 'homology';
                    $self->{_fnAddNodes}->($xmldoc, $annotation, \%hmFields, $refResult);
                    $contig->addChild($annotation);
                    
                    if($refResult->{prev})
                    {
                        $strQuery = "SELECT Annotation.symbol AS symbol, ".
			                   "Annotation.definition AS definition, ".
					   "Annotation.date AS date, ".
					   "Annotation.remarks AS remarks, ".
					   "Annotation.previous AS prev, " .
                                           "Author.name AS author, " .
                                           "Molecule.name AS molecule " .
                                    "FROM Annotation INNER JOIN Author ON Annotation.au_id=Author.au_id " .
                                           "INNER JOIN Molecule ON Annotation.m_id=Molecule.m_id " .
                                    "WHERE an_id=$refResult->{prev};";
                        $refResult = $self->{_db}->selectrow_hashref($strQuery);
                    }
                    else
                    {
                        $refResult = undef;
                    }
                    $iIndex++;
                }
            }
            $xmldata->addChild($contig);
        }
        return Constants::ERR_OK;
    }

    sub getGene
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrContigs = (defined $refParams->{contigs}) ? split(/,/, $refParams->{contigs}) : ();
        # Escape hyphens in the contig and field names.
	$_=~ s/'/\\'/g foreach @arrContigs;
	# Contig IDs.
        if((scalar @arrContigs)==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
	foreach my $strContig (@arrContigs)
	{
	    my $contig = $xmldoc->createElement('contig');
            $contig->addChild($xmldoc->createAttribute(name => $strContig));
	    my $strQuery = "SELECT Gene.name AS gname, ".
				  "GeneRegion.type AS type, ".
				  "GeneRegion.sequence AS seq, ".
				  "LENGTH(Gene.sequence) AS len, ".
				  "start, ".
				  "end ".
			   "FROM GeneRegion ".
			        "INNER JOIN Gene ON GeneRegion.g_id=Gene.g_id ".
			   "WHERE GeneRegion.name='$strContig' ".
			   "ORDER BY GeneRegion.type, GeneRegion.start";
	    my $statement = $self->{_db}->prepare($strQuery);
	    $statement->execute();
	    my $refResult = $statement->fetchrow_hashref();
	    next unless $refResult;
	    $contig->addChild($xmldoc->createAttribute(gene => $refResult->{gname}));
	    $contig->addChild($xmldoc->createAttribute(length => $refResult->{len}));
	    while($refResult)
	    {
		my $fragment = $xmldoc->createElement('fragment');
		$fragment->addChild($xmldoc->createAttribute(type => $refResult->{type}));
		$fragment->addChild($xmldoc->createAttribute(start => $refResult->{start}));
		$fragment->addChild($xmldoc->createAttribute(end => $refResult->{end}));
		$fragment->addChild($xmldoc->createTextNode($refResult->{seq}));
		$contig->addChild($fragment);
		$refResult = $statement->fetchrow_hashref();
	    }
	    $xmldata->addChild($contig);
	}
	return Constants::ERR_OK;
    }
}

1;
