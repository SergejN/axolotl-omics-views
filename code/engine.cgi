#!/usr/bin/env perl

#   File:
#       engine.cgi
#
#   Description:
#       Contains the axolotl website engine.
#
#   Version:
#       1.0.7
#
#   Date:
#       10.01.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
#use CGI::Carp qw(set_die_handler);
use CGI::Cookie;
use HTML::Entities;
use LWP::Simple;
use XML::Simple;
use FindBin;
use lib "$FindBin::Bin/pages";

use Axolotl::webpage;
use Axolotl::ATAPI::Kernel;
use Axolotl::ATAPI::Constants;
use Axolotl::ATAPI::UserManager;
use Axolotl::ATAPI::SettingsManager;


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

# Get the settings.
my $SETTINGS = '../../../config/general.cfg';
my $sm = new SettingsManager($SETTINGS);

# Database.
my $strDBName = $sm->getSetting('DATABASE', 'name');
my $strDBHost = $sm->getSetting('DATABASE', 'host');
my $strDBUser = $sm->getSetting('API', 'DBuser');
my $strDBPass = $sm->getSetting('API', 'DBpass', 1);

# System flags.
my $bMaintenance  = ($sm->getSetting('GENERAL', 'maintenance') eq 'yes');
my $strCookieName = $sm->getSetting('GENERAL', 'cookie_name');
my $strDomain     = $sm->getSetting('GENERAL', 'domain');
my $strHost       = $sm->getSetting('GENERAL', 'host');

# Pages settings.
my $strPageOpts = $sm->getSetting('GENERAL', 'pages_settings');
my $pagesOpt = new SettingsManager($strPageOpts);

# Access settings.
my $strAccessOpts = $sm->getSetting('GENERAL', 'access_settings');
my $accessOpt = new SettingsManager($strAccessOpts);

# Identify the user if possible.
my $cgi = new CGI();
my %hmCookies = CGI::Cookie->fetch();
my $sid = ($hmCookies{$strCookieName}) ? $hmCookies{$strCookieName}->value() : undef;

my $um = new UserManager($strDBName, $strDBHost, $strDBUser, $strDBPass);
my $user = $um->getUserDetails($sid, $ENV{"REMOTE_ADDR"}, $ENV{"HTTP_USER_AGENT"});

my $strProtocol = ($ENV{HTTPS} eq 'on') ? 'https' : 'http';

# If no parameters are specified, display the main page. Otherwise, the first parameter must be 'pageid' and specify the
# page to display.
my $strPageID = 'homepage';
my $refParams = {_base => "$strProtocol://$strHost",
		 _protocol => $strProtocol,
                 _user => $user,
                 _maintenance => $bMaintenance,
                 _userAgent => $ENV{HTTP_USER_AGENT},
                 _remoteAddress => $ENV{REMOTE_ADDR},
                 _server => $ENV{SERVER_NAME},
		 _sm => $sm,
		 _pagesOpts => $pagesOpt,
		 _accessOpts => $accessOpt};

if($strParam && length($strParam))
{
    my @arrParamPairs = split(/&/, $strParam);
    my ($strName, $strValue) = split(/=/, lc($arrParamPairs[0]));
    next if(substr($strName, 0, 1) eq '_');
    if($strName eq 'pageid')
    {
        $strPageID = lc($strValue) if $strValue;
        # Simply remove the first parameter pair from the array.
        shift @arrParamPairs;
    }
    # Create parameters hash.
    foreach my $strPair (@arrParamPairs)
    {
        my ($strName, $strValue) = split(/=/, $strPair);
        $refParams->{$strName} = $strValue;
    }
}

# Display the page.
# Possible return values of the createPage method of a module:
#
#  Return value		| Description
# ----------------------|-----------------------------
# Non-empty string      | Page content, which needs to be displayed
# Empty string		| The module already returned the content to the user (e.g. binary data)
# undef			| The current user does not have access to the requested page
my $strPageContent = undef;
if($strPageID eq 'homepage' ||
   $strPageID eq 'home' ||
   $strPageID eq 'main' ||
   ($bMaintenance && (($user->{privilege} & Constants::UP_ADMINISTRATOR) != Constants::UP_ADMINISTRATOR)) )
{
    use Homepage;
    $strPageContent = Homepage::createPage($refParams);
}
elsif($strPageID eq 'viewer')
{
    use Viewer;
    $strPageContent = Viewer::createPage($refParams);
}
elsif($strPageID eq 'blast')
{
    use Blast;
    $strPageContent = Blast::createPage($refParams);
}
elsif($strPageID eq 'search')
{
    use Search;
    $strPageContent = Search::createPage($refParams);
}
elsif($strPageID eq 'contact')
{
    use Contact;
    $strPageContent = Contact::createPage($refParams);
}
elsif($strPageID eq 'news')
{
    use News;
    $strPageContent = News::createPage($refParams);
}
elsif($strPageID eq 'tools')
{
    use Tools;
    $strPageContent = Tools::createPage($refParams);
}
elsif($strPageID eq 'help')
{
    use Help;
    $strPageContent = Help::createPage($refParams);
}
elsif($strPageID eq 'user')
{
    use User;
    $strPageContent = User::createPage($refParams);
}
elsif($strPageID eq 'admin')
{
    use Admin;
    $strPageContent = Admin::createPage($refParams);
}
elsif($strPageID eq 'error')
{
    use Errorpage;
    $strPageContent = Errorpage::createPage($refParams);
}
else
{
    use Errorpage;
    $refParams->{rc} = 404;
    $strPageContent = Errorpage::createPage($refParams);
}

if(!defined $strPageContent)
{
    $refParams->{_noaccess} = 1;
    $refParams->{_querystring} = $strParam;
    $strPageContent = User::createPage($refParams);
}

if($strPageContent)
{
    my $strExpires = ($user->{sid}) ? '+7d' : '-1d';
    my $strValue = ($user->{sid}) ? $user->{sid} : '';
    my $cookie = CGI::Cookie->new(-name => $strCookieName,
				  -value => $strValue,
				  -expires => $strExpires,
				  -secure => 1,
				  -domain => $strDomain);
    print $cgi->header(-cookie => $cookie,
		       -type => 'text/html',
		       -charset => 'UTF-8');
    print $strPageContent;
}