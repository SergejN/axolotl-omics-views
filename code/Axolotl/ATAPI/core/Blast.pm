#!/usr/bin/env perl

#   File:
#       Blast.pm
#
#   Description:
#       Contains the BLAST core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       2.0.2
#
#   Date:
#       22.02.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use IO::Uncompress::Gunzip qw(gunzip);

use Axolotl::ATAPI::Constants;


package Blast;
{
    use constant DB_SRC_ASSEMBLY => Constants::DB_SRC_ASSEMBLY;
    use constant DB_SRC_LIBRARY => Constants::DB_SRC_LIBRARY;
    use constant DB_SRC_COLLECTION => Constants::DB_SRC_COLLECTION;
    use constant DB_SRC_GENES => Constants::DB_SRC_GENES;
    use constant DB_SRC_GENOME => Constants::DB_SRC_GENOME;
    
    my $BS_SUBMITTED = Constants::BS_SUBMITTED;
    my $BS_PROCESSING = Constants::BS_PROCESSING;
    my $BS_FINISHED = Constants::BS_FINISHED;
    my $BS_ERROR = Constants::BS_ERROR;
    
    my %hmStatus = ($BS_SUBMITTED => 'queued',
		    $BS_PROCESSING => 'processing',
		    $BS_FINISHED => 'finished',
		    $BS_ERROR => 'failed');
    my $MODULE = 'Blast';
    my $VERSION = '2.0.2';
    my $DATE = '2015-07-31';
    
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
       return "Submits the query for a BLAST search and retrieves the results.";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'submitQuery',
                           _description => 'Submits the BLAST query',
                           _args => [{_name => 'query',
                                      _description => 'BLAST query in FASTA format',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'algorithm',
                                      _description => 'Algorithm to use. Must be one of the following: "blastn", "tblastn", "tblastx"',
                                      _type => 'optional',
                                      _default => 'blastn'},
                                     {_name => 'db',
                                      _description => 'Database to use',
                                      _type => 'optional',
                                      _default => 'Latest assembly'},
                                     {_name => 'maxexp',
                                      _description => 'Maximal e-value to output',
                                      _type => 'optional',
                                      _default => 'BLAST default (10)'},
                                     {_name => 'matrix',
                                      _description => 'Name of the matrix to use. Must be one of the following: "PAM30", "PAM70", "PAM250", ' .
                                                        '"BLOSSUM45", "BLOSSUM50", "BLOSSUM62", "BLOSSUM80", and "BLOSSUM90"',
                                      _type => 'optional',
                                      _default => 'BLAST default'},
                                     {_name => 'maxhits',
                                      _description => 'Maximal number of hits to output',
                                      _type => 'optional',
                                      _default => '100'},
                                     {_name => 'minidentity',
                                      _description => 'Minimal required identity in per cent (1 - 100)',
                                      _type => 'optional',
                                      _default => '0'},
                                     {_name => 'lcreg',
                                      _description => 'Whether or not to mask low complexity regions (not implemented - do not use!)',
                                      _type => 'optional',
                                      _default => '1'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no query was specified'},
                                           {_value => 'Constants::ERR_RUNTIME_ERROR',
                                            _numval => Constants::ERR_RUNTIME_ERROR,
                                            _description => 'If the query fails to be submitted'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.submitQuery&query=MMMGTCVANNCAAA&algorithm=tblastn",
                           _remarks => 'If succeeds, this method returns the job status and the job ID, which can be used to track the execution and retrieve the results'},
                          
                          {_name => 'getQueryStatus',
                           _description => 'Retrieves the query status',
                           _args => [{_name => 'queryID',
                                      _description => "Query ID returned by $MODULE.submitQuery",
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no query ID was specified'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no query with the specified ID was found'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getQueryStatus&queryID=1"},
                          
                          {_name => 'retrieveResults',
                           _description => 'Retrieves the query results',
                           _args => [{_name => 'queryID',
                                      _description => "Query ID returned by $MODULE.submitQuery",
                                      _type => 'required',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no query ID was specified'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no query with the specified ID was found'},
					   {_value => 'Constants::ERR_RUNTIME_ERROR',
                                            _numval => Constants::ERR_RUNTIME_ERROR,
                                            _description => 'If the specified query failed'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.retrieveResults&queryID=1"},
                          
                          {_name => 'retrieveHits',
                           _description => 'Retrieves the hits',
                           _args => [{_name => 'queryID',
                                      _description => "Query ID returned by $MODULE.submitQuery",
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'sequence',
                                      _description => '1-based sequence index in case multiple sequences were submitted in one query',
                                      _type => 'optional',
                                      _default => '1'},
                                     {_name => 'indices',
                                      _description => '1-based indices of the hits to retrieve',
                                      _type => 'optional',
                                      _default => '1'}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no query ID was specified'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If no query with the specified ID was found or there are no hits for the query sequence'},
					   {_value => 'Constants::ERR_RUNTIME_ERROR',
                                            _numval => Constants::ERR_RUNTIME_ERROR,
                                            _description => 'If the specified query failed'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.retrieveHits&queryID=1&sequence=1&indices=1,5,7"});
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
        if($strMethod eq 'submitQuery')
        {
            return $self->submitQuery($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getQueryStatus')
        {
            return $self->getQueryStatus($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'retrieveResults')
        {
            return $self->retrieveResults($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'retrieveHits')
        {
            return $self->retrieveHits($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub submitQuery
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = $refParams->{query};
        if(!$strQuery)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No query specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strQuery =~ s/'/\\'/g;
        $strQuery =~ s/^[\s\n]+//g;
        # If the DB name is an integer, assume that it is an assembly version. Otherwise, it should be library/collection/genes ID. If no database is specified,
        # or the assembly/library cannot be found, use the latest assembly.
        my $strDB = undef;
        my $iSrc = DB_SRC_ASSEMBLY;
        if($refParams->{db})
        {
            # First, check if the DB name represents an assembly version. 
            if($refParams->{db} =~ m/^[0-9]+$/)
            {
                my $strDBQuery = "SELECT a_id FROM Assembly WHERE version=$refParams->{db};";
                my $refResult = $self->{_db}->selectrow_hashref($strDBQuery);
                if($refResult)
                {
                    $strDB = $refResult->{a_id};
                    $iSrc = DB_SRC_ASSEMBLY;
                }
            }
            # If it does not or the specified assembly does not exist, check if the DB name is a library, a collection name, 'AMex_genes' or 'amex_genome'
            else
            {
                if(lc($refParams->{db}) eq 'amex_genes')
                {
                    $strDB = 'genes';
                    $iSrc = DB_SRC_GENES;
                }
                elsif(lc($refParams->{db}) =~ m/amex_genome/)
                {
                    $strDB = lc($refParams->{db});
                    $iSrc = DB_SRC_GENOME;
                }
                else
                {
                    my $strDBQuery = "SELECT id FROM Library WHERE id='$refParams->{db}';";
                    my $refResult = $self->{_db}->selectrow_hashref($strDBQuery);
                    if($refResult)
                    {
                        $strDB = $refResult->{id};
                        $iSrc = DB_SRC_LIBRARY;
                    }
                    else
                    {
                        $strDBQuery = "SELECT id FROM ReadsCollection WHERE id='$refParams->{db}';";
                        $refResult = $self->{_db}->selectrow_hashref($strDBQuery);
                        if($refResult)
                        {
                            $strDB = $refResult->{id};
                            $iSrc = DB_SRC_COLLECTION;
                        }
                    }
                }
            }
        }
        if(!$strDB)
        {
            my $strDBQuery = "SELECT a_id FROM Assembly WHERE version=(SELECT MAX(version) FROM Assembly);";
            my $refResult = $self->{_db}->selectrow_hashref($strDBQuery);
            $strDB = $refResult->{a_id};
            $iSrc = DB_SRC_ASSEMBLY;
        }
        # Check the algorithm.
        my $strAlg = ($refParams->{algorithm}) ? lc($refParams->{algorithm}) : 'blastn';
        my %hmTasks = ('blastn'       => {algorithm => 'blastn', params => '-task blastn'},
                       'megablast'    => {algorithm => 'blastn', params => '-task megablast'},
                       'dc-megablast' => {algorithm => 'blastn', params => '-task dc-megablast'},
                       'tblastn'      => {algorithm => 'tblastn'},
                       'tblastx'      => {algorithm => 'tblastx'});
        my $refTask = $hmTasks{$strAlg};
        $refTask = $hmTasks{'blastn'} if(!$refTask);
        
        my $al_id = $self->{_db}->selectrow_hashref("SELECT al_id FROM Algorithm WHERE name='$refTask->{algorithm}';")->{al_id};
        ############################
        # Additional parameters: maxexp, matrix, and max hits.
        ############################
        my $strParams = $refTask->{params};
        if($refParams->{maxexp} && ($refParams->{maxexp}*1.0>0))
        {
            $strParams .= " -evalue $refParams->{maxexp}";
        }
        my $fMinIdentity = $refParams->{minidentity};
        if($fMinIdentity && ($fMinIdentity*1.0>0))
        {
            $fMinIdentity = 100 if($fMinIdentity>100);
            $fMinIdentity*=100 if($fMinIdentity<1);
            $strParams .= " -perc_identity $fMinIdentity";
        }
        if($refParams->{matrix})
        {
            my %hmMatrices = ('PAM30' => 1, 'PAM70' => 1, 'PAM250' => 1,
                              'BLOSSUM45' => 1, 'BLOSSUM50' => 1, 'BLOSSUM62' => 1, 'BLOSSUM80' => 1, 'BLOSSUM90' => 1);
            if($hmMatrices{uc($refParams->{matrix})})
            {
                $strParams .= " -matrix " . uc($refParams->{matrix});
            }
        }
        if($refParams->{maxhits} && int($refParams->{maxhits})>0)
        {
            $strParams .= " -max_target_seqs $refParams->{maxhits}";
        }
        else
        {
            $strParams .= " -max_target_seqs 100";
        }
        my $iFlags = 0;
        $iFlags = 1 if($refParams->{isoforms});
        $iFlags &= 2 if($refParams->{lcreg});
	      # Check the e-mail.
	      my $strEmail = $refParams->{email};
	      $strEmail =~ s/'/\\'/g if($strEmail);
	      $strEmail = '' unless $strEmail;
        # Put the query into the database: the jobs will be automatically picked up by the workers
        my $strDBQuery = "INSERT INTO BlastJob (query, al_id, db, flags, submitted, params, bs_id, src, email) " .
                            "VALUES ('$strQuery', $al_id, '$strDB', $iFlags, NULL, ".
					                           "'$strParams', (SELECT bs_id FROM BlastStatus WHERE name='$BS_SUBMITTED'), $iSrc, '$strEmail');";
        my $statement = $self->{_db}->prepare($strDBQuery);
        if(!$statement->execute())
        {
            $xmlerr->addChild($xmldoc->createTextNode($statement->errstr));
            return Constants::ERR_RUNTIME_ERROR;
        }
        $strDBQuery = "SELECT MAX(bj_id) AS id FROM BlastJob;";
        my $refResult = $self->{_db}->selectrow_hashref($strDBQuery);
        my $query = $xmldoc->createElement('query');
        $query->addChild($xmldoc->createAttribute('id' => $refResult->{id}));
        $query->addChild($xmldoc->createAttribute('status' => $hmStatus{$BS_SUBMITTED}));
        $xmldata->addChild($query);
        return Constants::ERR_OK;
    }
    
    sub getQueryStatus
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $queryID = $refParams->{queryID};
        if(!$queryID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No query ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        # Get the query from the database.
        $queryID =~ s/'/\\'/g;
        my $strQuery = "SELECT BlastStatus.name AS status, ".
			      "BlastJob.submitted ".
		       "FROM BlastJob ".
		            "INNER JOIN BlastStatus ON BlastJob.bs_id=BlastStatus.bs_id ".
		       "WHERE bj_id=$queryID;";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            # If the ID was not found, check the BlastResult table, as the job might be finished.
            $strQuery = "SELECT BlastStatus.name AS status ".
			"FROM BlastResult ".
			     "INNER JOIN BlastStatus ON BlastResult.bs_id=BlastStatus.bs_id ".
			"WHERE bj_id=$queryID;";
            $refResult = $self->{_db}->selectrow_hashref($strQuery);
            if(!$refResult->{status})
            {
                $xmlerr->addChild($xmldoc->createTextNode("There is no query with the specified ID"));
                return Constants::ERR_DATA_NOT_FOUND;
            }
        }
        my $query = $xmldoc->createElement('query');
        $query->addChild($xmldoc->createAttribute('id' => $queryID));
        $query->addChild($xmldoc->createAttribute('status' => $hmStatus{$refResult->{status}}));
        my $nUpdate = (($refResult->{status}) eq $BS_SUBMITTED) ? 10 : 30;
        if(($refResult->{status} ne $BS_FINISHED) && ($refResult->{status} ne $BS_ERROR))
        {
            # Retry time.
            $strQuery = "SELECT TIMESTAMPDIFF(SECOND, '$refResult->{submitted}', CURRENT_TIMESTAMP()) AS elapsed;";
            $refResult = $self->{_db}->selectrow_hashref($strQuery);
            $query->addChild($xmldoc->createAttribute('elapsed' => $refResult->{elapsed}));
            $query->addChild($xmldoc->createAttribute('update' => $nUpdate));
        }
        $xmldata->addChild($query);
        return Constants::ERR_OK;
    }

    sub retrieveResults
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $queryID = $refParams->{queryID};
        if(!$queryID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No query ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $queryID =~ s/'/\\'/g;
        # First, check if the query ID is valid and exists.
        my $strQuery = "SELECT BlastResult.*, ".
			      "BlastStatus.name AS status ".
		       "FROM BlastResult ".
			    "INNER JOIN BlastStatus ON BlastResult.bs_id=BlastStatus.bs_id ".
		       "WHERE bj_id=$queryID;";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No results found for the query with the specified ID."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
	if($refResult->{status} eq $BS_ERROR)
	{
	    $xmlerr->addChild($xmldoc->createTextNode("Blast failed due to invalid parameter combination or input data"));
            return Constants::ERR_RUNTIME_ERROR;
	}
	# Step 1: add general information about the job, algorithm, database, and parameters.
	my $blast = $xmldoc->createElement('blast');
	$blast->addChild($xmldoc->createAttribute(queryID => $queryID));
        $blast->addChild($xmldoc->createAttribute(submitted => $refResult->{submitted}));
        $blast->addChild($xmldoc->createAttribute(finished => $refResult->{finished}));
	$blast->addChild($xmldoc->createTextNode($refResult->{query}));
	my $algorithm = $xmldoc->createElement('algorithm');
	$algorithm->addChild($xmldoc->createAttribute(name => $refResult->{alg_name}));
	$algorithm->addChild($xmldoc->createAttribute(version => $refResult->{alg_version}));
	$algorithm->addChild($xmldoc->createTextNode($refResult->{citation}));
	$blast->addChild($algorithm);
	my $database = $xmldoc->createElement('database');
	$database->addChild($xmldoc->createAttribute(type => $refResult->{dbtype}));
	$database->addChild($xmldoc->createAttribute(name => $refResult->{dbname}));
	$database->addChild($xmldoc->createAttribute(id => $refResult->{dbid}));
	$database->addChild($xmldoc->createAttribute(size => $refResult->{dbsize}));
	$database->addChild($xmldoc->createTextNode($refResult->{dbdesc}));
	$blast->addChild($database);
	my $parameters = $xmldoc->createElement('parameters');
	$parameters->addChild($xmldoc->createAttribute(matrix => $refResult->{matrix}));
	$parameters->addChild($xmldoc->createAttribute(evalue => $refResult->{evalue}));
	$parameters->addChild($xmldoc->createAttribute(gapOpen => $refResult->{go}));
	$parameters->addChild($xmldoc->createAttribute(gapExtend => $refResult->{ge}));
	$blast->addChild($parameters);
        $xmldata->addChild($blast);
	
        # Step 2: find the queries and insert a separate block for each query.
        my $queries = $xmldoc->createElement('queries');
        $strQuery = "SELECT bq_index, name, length FROM BlastQuery WHERE bj_id=$queryID;";
        my $stmtSelectQuery = $self->{_db}->prepare($strQuery);
        my $strHitQuery = "SELECT BlastHit.h_index, name, description, length, score, evalue, identities, gaps, positive ".
	                  "FROM BlastHit ".
			       "INNER JOIN BlastHSP ON BlastHit.bj_id=BlastHSP.bj_id ".
			                          "AND BlastHit.bq_index=BlastHSP.bq_index ".
						  "AND BlastHit.h_index=BlastHSP.h_index ".
			  "WHERE BlastHit.bj_id=$queryID AND BlastHit.bq_index=? AND BlastHSP.best=1";			  
        my $stmtSelectHit = $self->{_db}->prepare($strHitQuery);
	$strQuery = "SELECT * ".
	            "FROM BlastHSP ".
		    "WHERE bj_id=$queryID AND bq_index=? AND h_index=?";
	my $stmtSelectHSP = $self->{_db}->prepare($strQuery);
        $stmtSelectQuery->execute();
        while($refResult = $stmtSelectQuery->fetchrow_hashref())
        {
            my $query = $xmldoc->createElement('query');
            $query->addChild($xmldoc->createAttribute('name' => $refResult->{name}));
            $query->addChild($xmldoc->createAttribute('length' => $refResult->{length}));
            $query->addChild($xmldoc->createAttribute('index' => $refResult->{bq_index}));
            # Iterate through the hits.
            $stmtSelectHit->execute($refResult->{bq_index});
	    my $bq_index = $refResult->{bq_index};
            while($refResult = $stmtSelectHit->fetchrow_hashref())
            {
		my $hit = $xmldoc->createElement('hit');
		$hit->addChild($xmldoc->createAttribute('index' => $refResult->{h_index}));
		$hit->addChild($xmldoc->createAttribute('length' => $refResult->{length}));
		$hit->addChild($xmldoc->createAttribute('bitscore' => $refResult->{score}));
		$hit->addChild($xmldoc->createAttribute('evalue' => sprintf("%.5g", $refResult->{evalue})));
		$hit->addChild($xmldoc->createAttribute('identities' => $refResult->{identities}));
		$hit->addChild($xmldoc->createAttribute('gaps' => $refResult->{gaps}));
		$hit->addChild($xmldoc->createAttribute('positive' => $refResult->{positive}));
		$hit->addChild($xmldoc->createAttribute('name' => $refResult->{name}));
		$hit->addChild($xmldoc->createTextNode($refResult->{description})) if($refResult->{description});
		$stmtSelectHSP->execute($bq_index, $refResult->{h_index});
		while($refResult = $stmtSelectHSP->fetchrow_hashref())
		{
		    my $hsp = $xmldoc->createElement('hsp');
		    $hsp->addChild($xmldoc->createAttribute(bitscore => $refResult->{score}));
		    $hsp->addChild($xmldoc->createAttribute(evalue => $refResult->{evalue}));
		    $hsp->addChild($xmldoc->createAttribute(best => 'true')) if($refResult->{best});
		    my $hsp_query = $xmldoc->createElement('query');
		    $hsp_query->addChild($xmldoc->createAttribute(from => $refResult->{q_from}));
		    $hsp_query->addChild($xmldoc->createAttribute(to => $refResult->{q_to}));
		    $hsp_query->addChild($xmldoc->createAttribute(frame => $refResult->{q_frame}));
		    $hsp->addChild($hsp_query);
		    my $hsp_hit = $xmldoc->createElement('hit');
		    $hsp_hit->addChild($xmldoc->createAttribute(from => $refResult->{h_from}));
		    $hsp_hit->addChild($xmldoc->createAttribute(to => $refResult->{h_to}));
		    $hsp_hit->addChild($xmldoc->createAttribute(frame => $refResult->{h_frame}));
		    $hsp->addChild($hsp_hit);
		    $hit->addChild($hsp);
		}
                $query->addChild($hit);
            }
            $queries->addChild($query);
        }
        $xmldata->addChild($queries);
        return Constants::ERR_OK;
    }
    
    sub retrieveHits
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $queryID = $refParams->{queryID};
        if(!$queryID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No query ID specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $queryID =~ s/'/\\'/g;
        # First, check if the query ID is valid and exists.
        my $strQuery = "SELECT BlastStatus.name AS status ".
		       "FROM BlastResult ".
		            "INNER JOIN BlastStatus ON BlastResult.bs_id=BlastStatus.bs_id ".
		       "WHERE bj_id=$queryID;";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult->{status})
        {
            $xmlerr->addChild($xmldoc->createTextNode("No results found for the query with the specified ID."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
	if($refResult->{status} eq $BS_ERROR)
	{
	    $xmlerr->addChild($xmldoc->createTextNode("Blast failed due to invalid parameter combination or input data"));
            return Constants::ERR_RUNTIME_ERROR;
	}
        my $seqID = ($refParams->{sequence} && int($refParams->{sequence})>0) ? $refParams->{sequence} : 1;
        $strQuery = "SELECT COUNT(*) AS count FROM BlastHit WHERE bj_id=$queryID AND bq_index=$seqID;";
        $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if($refResult->{count}==0)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No results found for the specified sequence index."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $hits = $xmldoc->createElement('hits');
        $hits->addChild($xmldoc->createAttribute('queryID' => $queryID));
        $hits->addChild($xmldoc->createAttribute('sequence' => $seqID));
        my @arrIndices = ($refParams->{indices}) ? split(/,/, $refParams->{indices}) : (1);
        foreach(@arrIndices)
        {
            $_ = 0 if!(int($_)>0);
        }
        my $strIndices = join(',', @arrIndices);
        $strQuery = "SELECT h_index, name, description, length ".
                    "FROM BlastHit ".
		    "WHERE bj_id=$queryID AND bq_index=$seqID AND h_index in ($strIndices) ".
                    "ORDER BY FIELD(h_index, $strIndices);";
        my $stmtSelectHit = $self->{_db}->prepare($strQuery);
	$strQuery = "SELECT * ".
	            "FROM BlastHSP ".
		    "WHERE bj_id=$queryID AND bq_index=$seqID AND h_index=?";
	my $stmtSelectHSP = $self->{_db}->prepare($strQuery);
        $stmtSelectHit->execute();
        while(my $refResult = $stmtSelectHit->fetchrow_hashref())
        {
            my $hit = $xmldoc->createElement('hit');
            $hit->addChild($xmldoc->createAttribute('index' => $refResult->{h_index}));
            $hit->addChild($xmldoc->createAttribute('name' => $refResult->{name}));
            $hit->addChild($xmldoc->createAttribute('length' => $refResult->{length}));
            $hit->addChild($xmldoc->createAttribute('description' => $refResult->{description})) if($refResult->{description});
	    my $iIndex = 1;
	    $stmtSelectHSP->execute($refResult->{h_index});
	    while(my $refResult = $stmtSelectHSP->fetchrow_hashref())
	    {
		my $hsp = $xmldoc->createElement('hsp');
		#$hsp->addChild($xmldoc->createAttribute(index => $iIndex));
		$hsp->addChild($xmldoc->createAttribute(evalue => $refResult->{evalue}));
		$hsp->addChild($xmldoc->createAttribute(bitscore => $refResult->{score}));
		#$hsp->addChild($xmldoc->createAttribute(identities => $refResult->{identities}));
		#$hsp->addChild($xmldoc->createAttribute(positive => $refResult->{positive}));
		#$hsp->addChild($xmldoc->createAttribute(gaps => $refResult->{gaps}));
		#$hsp->addChild($xmldoc->createAttribute(best => 'true')) if($refResult->{best});
		my $hsp_query = $xmldoc->createElement('query');
		$hsp_query->addChild($xmldoc->createAttribute(start => $refResult->{q_from}));
		#$hsp_query->addChild($xmldoc->createAttribute(to => $refResult->{q_to}));
		$hsp_query->addChild($xmldoc->createAttribute(frame => $refResult->{q_frame}));
		$hsp_query->addChild($xmldoc->createTextNode($refResult->{query}));
		$hsp->addChild($hsp_query);
		my $hsp_hit = $xmldoc->createElement('hit');
		$hsp_hit->addChild($xmldoc->createAttribute(start => $refResult->{h_from}));
		#$hsp_hit->addChild($xmldoc->createAttribute(to => $refResult->{h_to}));
		$hsp_hit->addChild($xmldoc->createAttribute(frame => $refResult->{h_frame}));
		$hsp_hit->addChild($xmldoc->createTextNode($refResult->{hit}));
		$hsp->addChild($hsp_hit);
		my $midline = $xmldoc->createElement('midline');
		$midline->addChild($xmldoc->createTextNode($refResult->{midline}));
		$hsp->addChild($midline);
		$hit->addChild($hsp);
		$iIndex++;
	    }
            $hits->addChild($hit);
        }
        $xmldata->addChild($hits);
        return Constants::ERR_OK;
    }
}

1;
