#!/usr/bin/env perl

#   File:
#       engine.cgi
#
#   Description:
#       Contains the axolotl website engine.
#
#   Version:
#       1.2.0
#
#   Date:
#       18.02.2020
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use CGI::Cookie;
use HTML::Entities;
use LWP::Simple;
use XML::Simple;

use lib "/backend/modules";
use webpage;
use Constants;

my $strHost = "https://www.axolotl-omics.org";

# Retrieve the parameters.
my $strParam = undef;
my $strMethod = $ENV{"REQUEST_METHOD"};
if($strMethod eq "GET")
{
    $strParam = $ENV{"QUERY_STRING"};
}
elsif($strMethod eq "POST")
{
    read STDIN, $strParam, $ENV{"CONTENT_LENGTH"};
}

$strParam =~ s/\+/ /g;
$strParam =~ s/%0D//g;
$strParam =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
$ENV{"HTTP_USER_AGENT"} = HTML::Entities::encode($ENV{"HTTP_USER_AGENT"});
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

my $strProtocol = ($ENV{HTTPS} eq 'on') ? 'https' : 'http';

my $strPageID = 'homepage';
my $refParams = {_base => "$strProtocol://$strHost",
		         _protocol => $strProtocol,
                 _userAgent => $ENV{HTTP_USER_AGENT},
                 _remoteAddress => $ENV{REMOTE_ADDR},
                 _server => $ENV{SERVER_NAME}};

my $cgi = new CGI();
print $cgi->header(-type => 'text/html',
		           -charset => 'UTF-8');
print createMainPage($refParams);



sub createMainPage {
    my $refParams = shift;
    my $doc = Webpage::create('Welcome to Axolotl-omics website', "$refParams->{_base}/rss");
    $doc->addExternalResource('stylesheet', 'text/css', '$strHost/css/main.css');
	$doc->addExternalScript('text/javascript', '$strHost/js/jquery/jquery.flux.min.js');
    my $pageContent = Webpage::addCommonContent($doc, $refParams, 'Home', 1);
    my $msg = $doc->createElement('div');
    $msg->setInnerHTML("Welcome to the Axolotl-Omics.org Docker container");
    $msg->setStyle("font-size: 35px; text-align: center; margin-top: 100px;font-family: \"'Source Sans Pro',Helvetica,Georgia,sans-serif\"");
    $pageContent->appendChild($msg);
    return $doc->generateHTML();
}