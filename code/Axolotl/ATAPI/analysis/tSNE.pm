#!/usr/bin/env perl

#   File:
#       tSNE.pm
#
#   Description:
#       Contains the tSNE analysis module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.1
#
#   Date:
#       13.08.2019
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;


package tSNE;
{
    my $MODULE = 'TSNE';
    my $VERSION = '1.0.1';
    my $DATE = '2019-08-13';
    
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
       return "Overlays tSNE plots with the expression of the transcript within individual cells";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my $strExampleContig = 'NT_01000010432.2';
        my @arrMethods = ({_name => 'getCellData',
                           _description => 'Returns the data for each cell in the experiment including the coordinates of the cells in a tSNE plot',
                           _args => [{_name => 'contig',
                                      _description => 'Contig ID to retrieve information for',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'experiment',
                                      _description => 'Experiment ID to retrieve the data for',
                                      _type => 'required',
                                      _default => ''},
                                     {_name => 'counts',
                                      _description => 'Counts mode: raw counts or normalized values (default)',
                                      _type => 'optional',
                                      _default => 'normalized'}],
                           _resultCode => [{_value => 'Constants::ERR_OK_BINARY',
                                            _numval => Constants::ERR_OK_BINARY,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig ID or no experiment ID is specified'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If a non-existent contig ID or experiment ID was specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.generatePlot&contig=$strExampleContig&experiment=exp1",
			               _remarks => ""},

                           {_name => 'getExperimentList',
                           _description => 'Returns the list of experiments, for which tSNE plot data are available',
                           _args => [{_name => 'contig',
                                        _description => 'Contig ID to retrieve the list of experiments for',
                                        _type => 'required',
                                        _default => ''}],
                           _resultCode => [{_value => 'Constants::ERR_OK',
                                            _numval => Constants::ERR_OK,
                                            _description => 'If succeeds'},
                                           {_value => 'Constants::ERR_NOT_ENOUGH_PARAMETERS',
                                            _numval => Constants::ERR_NOT_ENOUGH_PARAMETERS,
                                            _description => 'If no contig ID is specified'},
                                           {_value => 'Constants::ERR_DATA_NOT_FOUND',
                                            _numval => Constants::ERR_DATA_NOT_FOUND,
                                            _description => 'If a non-existent contig ID was specified'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.getExperimentList&contig=$strExampleContig",
                           _remarks => ""});
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
        if($strMethod eq 'getCellData')
        {
            return $self->getCellData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getExperimentList')
        {
            return $self->getExperimentList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    # Private module methods.
    sub getCellData {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strContigID = $refParams->{contig};
        if(!$strContigID) {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $iExpID = int($refParams->{experiment});
        if($iExpID < 1) {
            $xmlerr->addChild($xmldoc->createTextNode("No or invalid single-cell experiment ID"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strContigID =~ s/'/\\'/g;
        my $strQuery = "SELECT c_id FROM Contig WHERE name='$strContigID'";
        my ($c_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$c_id) {
            $xmlerr->addChild($xmldoc->createTextNode("The specified contig ID does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        $strQuery = "SELECT COUNT(*) FROM SingleCellExperiment WHERE sse_id=$iExpID";
        my ($n) = $self->{_db}->selectrow_array($strQuery);
        if($n == 0) {
            $xmlerr->addChild($xmldoc->createTextNode("The specified single-cell experiment ID does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }

        my $clusters = $xmldoc->createElement('clusters');
        $strQuery = "SELECT idx, name ".
                    "FROM TSNEclusters ".
                    "WHERE sse_id=?";
        my $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute($iExpID);
        while(my $refResult = $stmt->fetchrow_hashref()) {
            my $cluster = $xmldoc->createElement('cluster');
            $cluster->addChild($xmldoc->createAttribute(index => $refResult->{idx}));
            $cluster->addChild($xmldoc->createTextNode($refResult->{name}));
            $clusters->addChild($cluster);
        }
        $xmldata->addChild($clusters);

        my $strColName = 'exprval';
        if($refParams->{counts} ne 'raw') {
            $strColName = 'exprvalnorm';
        }
        my ($st_id) = $self->{_db}->selectrow_array("SELECT st_id FROM SequenceType WHERE name='transcript'");
        $strQuery = "SELECT cell_name, cluster, ident, tsne_1, tsne_2, $strColName AS exprval ".
                    "FROM TSNEcell ".
                         "INNER JOIN TSNEplot ON TSNEcell.cell_id=TSNEplot.cell_id ".
                    "WHERE TSNEcell.sse_id=? AND TSNEplot.gene_name=(SELECT gene_name FROM TSNElookup WHERE c_id=?)";
        $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute($iExpID, $c_id);
        my $cells = $xmldoc->createElement('cells');
        $cells->addChild($xmldoc->createAttribute(experiment => $iExpID));
        while(my $refResult = $stmt->fetchrow_hashref()) {
            my $cell = $xmldoc->createElement('cell');
            $refResult->{cell_name} =~ s/"//g;
            $refResult->{ident} =~ s/"//g;
            $cell->addChild($xmldoc->createAttribute(name => $refResult->{cell_name}));
            $cell->addChild($xmldoc->createAttribute(cluster => $refResult->{cluster}));
            $cell->addChild($xmldoc->createAttribute(identity => $refResult->{ident}));
            $cell->addChild($xmldoc->createAttribute(tsne1 => $refResult->{tsne_1}));
            $cell->addChild($xmldoc->createAttribute(tsne2 => $refResult->{tsne_2}));
            $cell->addChild($xmldoc->createAttribute(value => $refResult->{exprval}));
            $cells->addChild($cell);
        }
        $xmldata->addChild($cells);
        $stmt->finish();
        return Constants::ERR_OK;
    }

    sub getExperimentList {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strContigID = $refParams->{contig};
        if(!$strContigID) {
            $xmlerr->addChild($xmldoc->createTextNode("No contig name specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strContigID =~ s/'/\\'/g;
        my $strQuery = "SELECT c_id FROM Contig WHERE name='$strContigID'";
        my ($c_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$c_id) {
            $xmlerr->addChild($xmldoc->createTextNode("The specified contig ID does not exist"));
            return Constants::ERR_DATA_NOT_FOUND;
        }

        $strQuery = "SELECT sse_id AS id, ".
                           "Experiment.name AS name, ".
                           "Experiment.description AS description, ".
                           "details, ".
                           "privilege, ".
                           "date, ".
                           "ref, ".
                           "platform, ".
                           "Author.name AS author, ".
                           "email  ".
                    "FROM Experiment ".
                         "INNER JOIN SingleCellExperiment ON Experiment.exp_id=SingleCellExperiment.exp_id ".
                         "INNER JOIN Author ON Author.au_id=SingleCellExperiment.au_id ".
                    "WHERE sse_id IN (SELECT DISTINCT(sse_id) ".
                                     "FROM TSNEcell ".
                                          "INNER JOIN TSNEplot ON TSNEcell.cell_id=TSNEplot.cell_id ".
                                     "WHERE gene_name=(SELECT gene_name FROM TSNElookup WHERE c_id=?))";
        my $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute($c_id);
        my $privilege = $refParams->{_user}->{privilege};
        while(my $refResult = $stmt->fetchrow_hashref()) {
            if(($refResult->{privilege} == 0) || (($refResult->{privilege} & $privilege) == $refResult->{privilege})) {
                my $experiment = $xmldoc->createElement('experiment');
                $experiment->addChild($xmldoc->createAttribute(name => $refResult->{name}));
                $experiment->addChild($xmldoc->createAttribute(id => $refResult->{id}));
                $experiment->addChild($xmldoc->createAttribute(platform => $refResult->{platform}));
                $experiment->addChild($xmldoc->createAttribute(date => $refResult->{date}));
                $experiment->addChild($xmldoc->createAttribute(reference => $refResult->{ref}));
                $experiment->addChild($xmldoc->createAttribute(author => $refResult->{author}));
                $experiment->addChild($xmldoc->createAttribute(email => $refResult->{email}));
                $experiment->addChild($xmldoc->createTextNode($refResult->{description}));
                $xmldata->addChild($experiment);
            }
        }
        $stmt->finish();
        return Constants::ERR_OK;
    }

}

1;
