#!/usr/bin/env perl

#   File:
#       Search.pm
#
#   Description:
#       Contains the Search core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       08.06.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package Search;
{
    my $MODULE = 'Search';
    my $VERSION = '1.0.1';
    my $DATE = '2014-08-25';
    
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
       return "Performs search for the contigs satisfying the specified criteria";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'find',
                           _description => 'Returns the list of hits that match the query.',
                           _args => [{_name => 'query',
                                      _description => 'Transcript name, library sequence name, RefSeq ID or microarray probe name',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'category',
                                      _description => 'Category to search in: transcript, libseq, microarray or homology',
                                      _type => 'optional',
                                      _default => 'transcript'},
				     {_name => 'limit',
                                      _description => 'Number of results to return.',
                                      _type => 'optional',
                                      _default => '25'},
                                     {_name => 'from',
                                      _description => '0-based hit index to begin the output with.',
                                      _type => 'optional',
                                      _default => '0'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no query is specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.find&query=NT_0100001"});
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
	if($strMethod eq 'find')
        {
            return $self->find($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub find
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	if(!$refParams->{query})
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No query specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
	}
	my %hmCategories = ('transcript' => {tables => "'Contig','Annotation'", st_id => "(SELECT st_id FROM SequenceType WHERE name='transcript')"},
			    'gene'       => {tables => "'Gene','Annotation'", st_id => "(SELECT st_id FROM SequenceType WHERE name='gene')"},
			    'libseq'     => {tables => "'LibrarySequence','LibraryAnnotation'", st_id => "(SELECT st_id FROM SequenceType WHERE name='transcript')"},
			    'microarray' => {tables => "'MicroarrayProbe'", st_id => "(SELECT st_id FROM SequenceType WHERE name='transcript')"},
			    'homology'   => {tables => "'RefSeq'", st_id => "(SELECT st_id FROM SequenceType WHERE name='transcript')"});
	my $strTables = $hmCategories{lc($refParams->{category})}->{tables};
	if(!$strTables)
	{
	    $strTables = $hmCategories{'transcript'};
	    $refParams->{category} = 'transcript';
	}
	my $st_id = $hmCategories{lc($refParams->{category})}->{st_id};
	my @arrWords = split(/ /, $refParams->{query});
	foreach(@arrWords)
	{
	    $_ =~ s/'/\\'/g;
	    $_ = "*$_*";
	}
	$refParams->{query} = join(' ', @arrWords);
	my $nLimit = ($refParams->{limit} && int($refParams->{limit})) ? int($refParams->{limit}) : 25;
        my $iFrom = ($refParams->{start} && int($refParams->{start})) ? int($refParams->{start}) : 0;
	my $strQuery = "SELECT SQL_CALC_FOUND_ROWS value, `table`, `column`, id, name ".
		       "FROM SearchIndex ".
		            "INNER JOIN SequenceType ON SearchIndex.st_id=SequenceType.st_id ".
		       "WHERE MATCH(`value`) AGAINST ('$refParams->{query}' IN BOOLEAN MODE) ".
		             "AND `table` IN ($strTables) ".
			     "AND SearchIndex.st_id=$st_id ".
		       "ORDER BY id DESC ".
		       "LIMIT $iFrom, $nLimit";      
	my $statement = $self->{_db}->prepare($strQuery);
	$statement->execute();
	my ($nTotal) = $self->{_db}->selectrow_array("SELECT FOUND_ROWS()");
	my $nCount = $statement->rows;
	my $query = $xmldoc->createElement('query');
	$query->addChild($xmldoc->createAttribute(category => $refParams->{category}));
	while(my $refResult = $statement->fetchrow_hashref())
	{
	    my $hit = $xmldoc->createElement('hit');
	    if(($refResult->{table} eq 'LibrarySequence') || ($refResult->{table} eq 'LibraryAnnotation'))
	    {
		$strQuery = "SELECT LibrarySequence.name AS name, ".
			           "LENGTH(LibrarySequence.sequence) AS length, ".
			           "Library.name AS library, ".
				   "Library.id AS lib_id, ".
			           "LibraryAnnotation.symbol AS symbol, ".
			           "LibraryAnnotation.definition AS definition, ".
			           "LibraryAnnotation.remarks AS remarks ".
			    "FROM LibrarySequence ".
			         "INNER JOIN Library ON LibrarySequence.lib_id=Library.lib_id ".
			         "LEFT  JOIN LibraryAnnotation ON LibrarySequence.ls_id=LibraryAnnotation.ls_id ".
			    "WHERE LibrarySequence.ls_id=$refResult->{id}";
		$refResult = $self->{_db}->selectrow_hashref($strQuery);
		$hit->addChild($xmldoc->createAttribute(name => $refResult->{name}));
		$hit->addChild($xmldoc->createAttribute(length => $refResult->{length}));
		my $library = $xmldoc->createElement('library');
		$library->addChild($xmldoc->createAttribute(name => $refResult->{library}));
		$library->addChild($xmldoc->createAttribute(id => $refResult->{lib_id}));
		$hit->addChild($library);
		if($refResult->{description} || $refResult->{remarks})
		{
		    my $annotation = $xmldoc->createElement('annotation');
		    if($refResult->{symbol} && ($refResult->{symbol} ne 'N/A'))
		    {
			$annotation->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
		    }
		    if($refResult->{definition})
		    {
			my $description = $xmldoc->createElement('definition');
			$description->addChild($xmldoc->createTextNode($refResult->{definition}));
			$annotation->addChild($description);
		    }
		    if($refResult->{remarks})
		    {
			my $remarks = $xmldoc->createElement('remarks');
			$remarks->addChild($xmldoc->createTextNode($refResult->{remarks}));
			$annotation->addChild($remarks);
		    }
		    $hit->addChild($annotation);
		}
	    }
	    elsif($refResult->{table} eq 'MicroarrayProbe')
	    {
		$strQuery = "SELECT MicroarrayProbe.name AS name, ".
			       "LENGTH(MicroarrayProbe.sequence) AS length, ".
			       "Microarray.name AS microarray, ".
			       "Microarray.description AS description ".
			"FROM MicroarrayProbe ".
			     "INNER JOIN Microarray ON MicroarrayProbe.ma_id=Microarray.ma_id ".
			"WHERE MicroarrayProbe.map_id=$refResult->{id}";
		my ($strName, $nLength, $strMicroarray, $strDescription) = $self->{_db}->selectrow_array($strQuery);
		$hit->addChild($xmldoc->createAttribute(name => $strName));
		$hit->addChild($xmldoc->createAttribute(length => $nLength));
		my $microarray = $xmldoc->createElement('microarray');
		$microarray->addChild($xmldoc->createAttribute(name => $strMicroarray));
		$microarray->addChild($xmldoc->createTextNode($strDescription));
		$hit->addChild($microarray);
	    }
	    elsif(($refResult->{name} eq 'transcript') && (($refResult->{table} eq 'Contig') ||
		                                           ($refResult->{table} eq 'Annotation')))
	    {
		$strQuery = "SELECT Contig.name AS name, ".
		                   "LENGTH(Contig.sequence) AS length, ".
				   "Assembly.name AS assembly, ".
				   "Assembly.version AS version, ".
				   "Annotation.symbol AS symbol, ".
				   "Annotation.definition AS definition ".
			     "FROM Contig ".
			          "INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
				  "LEFT  JOIN Annotation ON Contig.an_id=Annotation.an_id ".
			     "WHERE $refResult->{table}.$refResult->{column}=$refResult->{id}";
		$refResult = $self->{_db}->selectrow_hashref($strQuery);
		$hit->addChild($xmldoc->createAttribute(name => $refResult->{name}));
		$hit->addChild($xmldoc->createAttribute(length => $refResult->{length}));
		my $assembly = $xmldoc->createElement('assembly');
		$assembly->addChild($xmldoc->createAttribute(name => $refResult->{assembly}));
		$assembly->addChild($xmldoc->createAttribute(version => $refResult->{version}));
		$hit->addChild($assembly);
		if($refResult->{definition})
		{
		    my $annotation = $xmldoc->createElement('annotation');
		    if($refResult->{symbol})
		    {
			$annotation->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
		    }
		    $annotation->addChild($xmldoc->createTextNode($refResult->{definition}));
		    $hit->addChild($annotation);
		}
	    }
	    elsif(($refResult->{name} eq 'gene') && (($refResult->{table} eq 'Gene') ||
		                                     ($refResult->{table} eq 'Annotation')))
	    {
		$strQuery = "SELECT Gene.name AS name, ".
		                   "LENGTH(Gene.sequence) AS length, ".
				   "Annotation.symbol AS symbol, ".
				   "Annotation.definition AS definition ".
			     "FROM Gene ".
				  "LEFT JOIN Annotation ON Gene.an_id=Annotation.an_id ".
			     "WHERE $refResult->{table}.$refResult->{column}=$refResult->{id}";
		$refResult = $self->{_db}->selectrow_hashref($strQuery);
		$hit->addChild($xmldoc->createAttribute(name => $refResult->{name}));
		$hit->addChild($xmldoc->createAttribute(length => $refResult->{length}));
		if($refResult->{description})
		{
		    my $annotation = $xmldoc->createElement('annotation');
		    if($refResult->{symbol})
		    {
			$annotation->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
		    }
		    $annotation->addChild($xmldoc->createTextNode($refResult->{definition}));
		    $hit->addChild($annotation);
		}
	    }
	    elsif($refResult->{table} eq 'RefSeq')
	    {
		$strQuery = "SELECT RefSeq.seq_id AS id, ".
		                   "RefSeq.symbol AS symbol, ".
		                   "RefSeq.definition AS definition, ".
		                   "RefSeqOrganism.name AS organism, ".
		                   "Contig.name AS name, ".
		                   "LENGTH(Contig.sequence) AS length, ".
				   "Assembly.name AS assembly, ".
				   "Assembly.version AS version ".
			     "FROM RefSeq ".
			          "INNER JOIN RefSeqOrganism ON RefSeq.rso_id=RefSeqOrganism.rso_id ".
				  "INNER JOIN Homology ON RefSeq.rs_id=Homology.hit_id ".
				  "INNER JOIN Contig ON Homology.query_id=Contig.c_id ".
				  "INNER JOIN Assembly ON Contig.a_id=Assembly.a_id ".
				  "INNER JOIN SequenceType ON Homology.qst_id=SequenceType.st_id ".
				  "INNER JOIN HomologType ON Homology.ht_id=HomologType.ht_id ".
			     "WHERE RefSeq.rs_id=$refResult->{id} AND SequenceType.name='transcript' AND HomologType.name='RefSeq' ".
			     "ORDER BY Assembly.version DESC, length DESC";    
		my $stmt = $self->{_db}->prepare($strQuery);
		$stmt->execute();
		$refResult = $stmt->fetchrow_hashref();
		$hit->addChild($xmldoc->createAttribute(id => $refResult->{id}));
		if($refResult->{definition})
		{
		    my $refseq = $xmldoc->createElement('RefSeq');
		    $refseq->addChild($xmldoc->createAttribute(organism => $refResult->{organism}));
		    if($refseq->{symbol} && ($refseq->{symbol} ne 'N/A'))
		    {
			$refseq->addChild($xmldoc->createAttribute(symbol => $refResult->{symbol}));
		    }
		    $refseq->addChild($xmldoc->createTextNode($refResult->{definition}));
		    $hit->addChild($refseq);
		}
		while($refResult)
		{
		    my $homolog = $xmldoc->createElement('homolog');
		    $homolog->addChild($xmldoc->createAttribute(name => $refResult->{name}));
		    $homolog->addChild($xmldoc->createAttribute(length => $refResult->{length}));
		    $homolog->addChild($xmldoc->createAttribute(assembly => $refResult->{assembly}));
		    $homolog->addChild($xmldoc->createAttribute(version => $refResult->{version}));
		    $hit->addChild($homolog);
		    $refResult = $stmt->fetchrow_hashref();
		}
	    }
	    else
	    {
		next;
	    }
	    $query->addChild($hit);
	}
	$query->addChild($xmldoc->createAttribute(count => $nTotal));
	$query->addChild($xmldoc->createAttribute(from => $iFrom+1));
	$query->addChild($xmldoc->createAttribute(to => ($nCount<$nLimit) ? $iFrom+$nCount : $iFrom+$nLimit));
	$xmldata->addChild($query);
	return Constants::ERR_OK; 
    }
}

1;