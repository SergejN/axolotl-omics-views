#!/usr/bin/env perl

#   File:
#       News.pm
#
#   Description:
#       Contains the News core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.7
#
#   Date:
#       20.05.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;
use POSIX;
use LWP::Simple;
use XML::Simple;


package News;
{
    my $MODULE = 'News';
    
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
        $self->{_timezone} = $ps->getSetting('NEWS', 'timezone');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Encapsulates methods for getting the news";
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
        if($strMethod eq 'getNewsCount')
        {
            return $self->getNewsCount($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getNews')
        {
            return $self->getNews($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getNewsEntry')
        {
            return $self->getNewsEntry($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getLatestNews')
        {
            return $self->getLatestNews($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getNewsRSS')
        {
            return $self->getNewsRSS($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getNewsCount
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $news = $xmldoc->createElement('news');
        my $strFrom = $refParams->{'from'};
        my $strTo = $refParams->{'to'};
        my $strQueryPrefix = "SELECT COUNT(*) AS count, DATE(MIN(timestamp)) AS earliest, DATE(MAX(timestamp)) AS latest FROM News";
        my $strQuery = $strQueryPrefix ." ORDER BY timestamp DESC;";
        if($strFrom && $strTo)
        {
            $strQuery = $strQueryPrefix ." WHERE timestamp BETWEEN TIMESTAMP('$strFrom') AND TIMESTAMP('$strTo') ORDER BY timestamp DESC;";
            $news->addChild($xmldoc->createAttribute('from' => $strFrom));
            $news->addChild($xmldoc->createAttribute('to' => $strTo));
        }
        elsif($strFrom && !$strTo)
        {
            $strQuery = $strQueryPrefix ." WHERE timestamp>=TIMESTAMP('$strFrom') ORDER BY timestamp DESC;";
            $news->addChild($xmldoc->createAttribute('from' => $strFrom));
        }
        elsif(!$strFrom && $strTo)
        {
            $strQuery = $strQueryPrefix ." WHERE timestamp<=TIMESTAMP('$strTo') ORDER BY timestamp DESC;";
            $news->addChild($xmldoc->createAttribute('to' => $strTo));
        }
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        $news->addChild($xmldoc->createAttribute('count' => $refResult->{count}));
        if($refResult->{count})
        {
            $news->addChild($xmldoc->createAttribute('earliest' => $refResult->{earliest}));
            $news->addChild($xmldoc->createAttribute('latest' => $refResult->{latest}));
        }
        $xmldata->addChild($news);
        return Constants::ERR_OK;
    }
    
    sub getNews
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $news = $xmldoc->createElement('news');
        my $strFrom = $refParams->{'from'};
        my $strTo = $refParams->{'to'};
        my $nMaxLen = $refParams->{maxlen};
        my $strQuery = "SELECT n_id, title, text, timestamp, firstname, lastname FROM News INNER JOIN User ON News.u_id=User.u_id ORDER BY timestamp DESC;";
        if($strFrom && $strTo)
        {
            $strFrom=~ s/'/\\'/g;
            $strQuery = "SELECT n_id, title, text, timestamp, firstname, lastname FROM News INNER JOIN User ON News.u_id=User.u_id " .
                            "WHERE timestamp BETWEEN TIMESTAMP('$strFrom') AND TIMESTAMP('$strTo') ORDER BY timestamp DESC;";
            $news->addChild($xmldoc->createAttribute('from' => $strFrom));
            $news->addChild($xmldoc->createAttribute('to' => $strTo));
        }
        elsif($strFrom && !$strTo)
        {
            $strQuery = "SELECT n_id, title, text, timestamp, firstname, lastname FROM News INNER JOIN User ON News.u_id=User.u_id " .
                            "WHERE timestamp>=TIMESTAMP('$strFrom') ORDER BY timestamp DESC;";
            $news->addChild($xmldoc->createAttribute('from' => $strFrom));
        }
        elsif(!$strFrom && $strTo)
        {
            $strQuery = "SELECT n_id, title, text, timestamp, firstname, lastname FROM News INNER JOIN User ON News.u_id=User.u_id " .
                            "WHERE timestamp<=TIMESTAMP('$strTo') ORDER BY timestamp DESC;";
            $news->addChild($xmldoc->createAttribute('to' => $strTo));
        }
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $entry = $xmldoc->createElement('entry');
            $entry->addChild($xmldoc->createAttribute('title' => $refResult->{title}));
            $entry->addChild($xmldoc->createAttribute('date' => $refResult->{timestamp}));
            $entry->addChild($xmldoc->createAttribute('author' => "$refResult->{firstname} $refResult->{lastname}"));
            $entry->addChild($xmldoc->createAttribute('id' => $refResult->{n_id}));
            if(!$nMaxLen)
            {
                $refResult->{text} =~ s/\\\'/'/g;
                $entry->addChild($xmldoc->createTextNode($refResult->{text}));
            }
            else
            {
                my $strText = substr($refResult->{text}, 0, $nMaxLen);
                $strText .= '...' if(length($refResult->{text})>$nMaxLen);
                $entry->addChild($xmldoc->createTextNode($strText));
            }
            $news->addChild($entry);
        }
        $xmldata->addChild($news);
        return Constants::ERR_OK;
    }
    
    sub getNewsEntry
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{id})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Entry ID not specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{id} =~ s/'/\\'/g;
        my $strQuery = "SELECT n_id, title, text, timestamp, firstname, lastname FROM News INNER JOIN User ON News.u_id=User.u_id WHERE n_id=$refParams->{id};";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified entry could not be found"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $news = $xmldoc->createElement('news');
        my $entry = $xmldoc->createElement('entry');
        $entry->addChild($xmldoc->createAttribute('title' => $refResult->{title}));
        $entry->addChild($xmldoc->createAttribute('date' => $refResult->{timestamp}));
        $entry->addChild($xmldoc->createAttribute('author' => "$refResult->{firstname} $refResult->{lastname}"));
        $entry->addChild($xmldoc->createTextNode($refResult->{text}));
        $news->addChild($entry);
        $xmldata->addChild($news);
        return Constants::ERR_OK;
    }
    
    sub getLatestNews
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        $refParams->{limit} = 5 unless ($refParams->{limit} && $refParams->{limit}>0);
        my $nMaxLen = ($refParams->{maxlen}>0) ? $refParams->{maxlen} : undef;
        my $news = $xmldoc->createElement('news');
        my $strQuery = "SELECT n_id, title, text, timestamp, firstname, lastname FROM News INNER JOIN User ON News.u_id=User.u_id ORDER BY timestamp DESC LIMIT $refParams->{limit};";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $entry = $xmldoc->createElement('entry');
            $entry->addChild($xmldoc->createAttribute('title' => $refResult->{title}));
            $entry->addChild($xmldoc->createAttribute('date' => $refResult->{timestamp}));
            $entry->addChild($xmldoc->createAttribute('author' => "$refResult->{firstname} $refResult->{lastname}"));
            $entry->addChild($xmldoc->createAttribute('id' => $refResult->{n_id}));
            if(!$nMaxLen)
            {
                $entry->addChild($xmldoc->createTextNode($refResult->{text}));
            }
            else
            {
                my $strText = substr($refResult->{text}, 0, $nMaxLen);
                $strText .= '...' if(length($refResult->{text})>$nMaxLen);
                $entry->addChild($xmldoc->createTextNode($strText));
            }
            $news->addChild($entry);
        }
        $xmldata->addChild($news);
        return Constants::ERR_OK;
    }
    
    sub getNewsRSS
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $doc = XML::LibXML::Document->createDocument( '1.0', 'utf-8');
        my $rss = $doc->createElement('rss');
        $rss->addChild($doc->createAttribute(version => '2.0'));
        $rss->addChild($doc->createAttribute('xmlns:atom' => 'http://www.w3.org/2005/Atom'));  
        my $channel = $doc->createElement('channel');
        # Link.
        my $field = $doc->createElement('atom:link');
        $field->addChild($doc->createAttribute(href => "$refParams->{_base}/rss"));
        $field->addChild($doc->createAttribute(rel => 'self'));
        $field->addChild($doc->createAttribute(type => 'application/rss+xml'));
        $channel->appendChild($field);
        # Title.
        $field = $doc->createElement('title');
        $field->addChild($doc->createTextNode('Axolotl-omics'));
        $channel->appendChild($field);
        # Homepage link.
        $field = $doc->createElement('link');
        $field->addChild($doc->createTextNode($refParams->{_base}));
        $channel->appendChild($field);
        # Description.
        $field = $doc->createElement('description');
        $field->addChild($doc->createTextNode('Axolotl-omics.org - Website news and updates'));
        $channel->appendChild($field);
        # Language.
        $field = $doc->createElement('language');
        $field->addChild($doc->createTextNode('en-us'));
        $channel->appendChild($field);
        # Category.
        $field = $doc->createElement('category');
        $field->addChild($doc->createTextNode('Science'));
        $channel->appendChild($field);
        # Copyright.
        $field = $doc->createElement('copyright');
        $field->addChild($doc->createTextNode('Sergej Nowoshilow, CRT Dresden'));
        $channel->appendChild($field);
        
        # Select the entries from the news list.
        my $nCount = 15 unless ($refParams->{count} && ($refParams->{count}>0));
        my $strQuery = "SELECT n_id, title, text, CONCAT(firstname, ' ',lastname) AS name, DATE_FORMAT(timestamp, '%a, %e %b %Y %H:%i:%s') AS time " .
                            "FROM News INNER JOIN User ON News.u_id=User.u_id ORDER BY timestamp DESC LIMIT $nCount;";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        if($statement->rows)
        {
            my $refResult = $statement->fetchrow_hashref();
            my $lbd = $doc->createElement('lastBuildDate');
            $lbd->addChild($doc->createTextNode("$refResult->{time} $self->{_timezone}"));
            $channel->appendChild($lbd);
            while($refResult)
            {
                my $item = $doc->createElement('item');
                # Title.
                my $title = $doc->createElement('title');
                $title->addChild($doc->createTextNode($refResult->{title}));
                $item->addChild($title);
                # Link.
                my $link = $doc->createElement('link');
                $link->addChild($doc->createTextNode("$refParams->{_base}/news?id=$refResult->{n_id}"));
                $item->addChild($link);
                # Description.
                my $desc = $doc->createElement('description');
                $desc->addChild($doc->createTextNode($refResult->{text}));
                $item->addChild($desc);
                # Publication date.
                my $pubDate = $doc->createElement('pubDate');
                $pubDate->addChild($doc->createTextNode("$refResult->{time} $self->{_timezone}"));
                $item->addChild($pubDate);
                # Author.
                my $author = $doc->createElement('author');
                $author->addChild($doc->createTextNode($refResult->{name}));
                $item->addChild($author);
                # GUID.
                my $guid = $doc->createElement('guid');
                $guid->addChild($doc->createTextNode("$refParams->{_base}/news?id=$refResult->{n_id}"));
                $item->addChild($guid);
                $channel->appendChild($item);
                $refResult = $statement->fetchrow_hashref();
            }
        }
        $rss->addChild($channel);
        $doc->addChild($rss);
        print "Content-type:application/rss+xml\n\n";
        print $doc->toString();
        return Constants::ERR_OK_BINARY;
    }
}

1;
