#!/usr/bin/env perl

#   File:
#       Kernel.pm
#
#   Description:
#       Contains the Axolotl API (ATAPI) page module.
#
#   Version:
#       1.5.2
#
#   Date:
#       01.02.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;
use DBI;
use XML::LibXML;
use Time::HiRes qw(time);

use Axolotl::ATAPI::Constants;


package Kernel;
{
    sub new
    {
        my ($class, $refParams, $sm, $um) = @_;
        my $strDBName = $sm->getSetting('DATABASE', 'name');
    	my $strHost = $sm->getSetting('DATABASE', 'host');
    	my $strDBUser = $sm->getSetting('API', 'DBuser');
    	my $strDBPass = $sm->getSetting('API', 'DBpass', 1);
        my @arrConfig = ("DBI:mysql:database=$strDBName;host=$strHost", $strDBUser, $strDBPass);
        my $hDB = DBI->connect(@arrConfig);
        my $self = {_db => $hDB,
                    _params => $refParams,
        		    _sm => $sm,
        		    _ps => new SettingsManager($sm->getSetting('GENERAL', 'module_settings')),
        		    _um => $um,
        		    _modules => $sm->getSetting('GENERAL', 'modules')};
        bless $self, $class;
        return $self;
    }
    
    sub DESTROY
    {
        my $self = shift;
        $self->{_db}->disconnect() if defined $self->{_db};
        return Constants::ERR_OK;
    }
    
    sub execute
    {
        my ($self, $strParamStr) = @_;
	    my $iStartTime = Time::HiRes::time();
        # First create the template of the XML response.
        my $doc = XML::LibXML::Document->createDocument('1.0', 'utf-8');
        my $root = $doc->createElement('response');
        $doc->addChild($root);
        # Then parse the parameters and create the response header.
        my $refParams = parseParamStr($strParamStr);

        # Add server parameters.
        $refParams->{_parameters}->{_userAgent} = $self->{_params}->{_userAgent};
        $refParams->{_parameters}->{_remoteAddress} = $self->{_params}->{_remoteAddress};
        $refParams->{_parameters}->{_server} = $self->{_params}->{_server};
        $refParams->{_parameters}->{_user} = $self->{_params}->{_user};
	    $refParams->{_parameters}->{_base} = $self->{_params}->{_base};
        my $code = $doc->createElement('resultCode');
	    my $time = $doc->createElement('time');
        # If the database connection could not be extablished, return error immediately.
        if(!$self->{_db})
        {
            $code->addChild($doc->createTextNode(Constants::ERR_DB_ERROR));
            $root->addChild($code);
	        $time->addChild($doc->createTextNode(Time::HiRes::time()-$iStartTime));
	        $root->addChild($time);
            my $error = $doc->createElement('errorDescription');
            $error->addChild($doc->createTextNode("The database connection could not be established"));
            $root->addChild($error);
            return formatOutput($refParams->{_format}, $doc);
        }
        # Code
        my $iCode = $refParams->{_code};
        $code->addChild($doc->createTextNode($iCode));
        $root->addChild($code);
        # Even if $iCode is not ERR_OK, check request ID and callbackParams before returning the error message,
        # since the caller might require those.
        # Request ID.
        if((defined $refParams->{_requestID}) && length($refParams->{_requestID})>0)
        {
            my $requestID = $doc->createElement('requestID');
            $requestID->addChild($doc->createTextNode($refParams->{_requestID}));
            $root->addChild($requestID);
        }
        # Callback parameters.
        if((defined $refParams->{_callbackParams}) && length($refParams->{_callbackParams})>0)
        {
	    $refParams->{_callbackParams} = HTML::Entities::encode($refParams->{_callbackParams});
            my $callbackParams = $doc->createElement('callbackParams');
            $callbackParams->addChild($doc->createTextNode($refParams->{_callbackParams}));
            $root->addChild($callbackParams);
        }
        # If the code is not ERR_OK, then the query string was malformed, in which case add the error description
        # and return.
        if($iCode!=Constants::ERR_OK)
        {
            my $error = $doc->createElement('errorDescription');
            $error->addChild($doc->createTextNode($refParams->{_errorDescription}));
            $root->addChild($error);
	        $time->addChild($doc->createTextNode(Time::HiRes::time()-$iStartTime));
	        $root->addChild($time);
            return formatOutput($refParams->{_format}, $doc);
        }
        # Otherwise parse the name of the module and the method.
        my $strMethodStr = $refParams->{_method};
        if((!defined $strMethodStr) || (length($strMethodStr)<3))
        {
            $iCode = Constants::ERR_METHOD_NOT_FOUND;
            my $error = $doc->createElement('errorDescription');
            $error->addChild($doc->createTextNode("'$strMethodStr' is not a valid method name"));
            $root->addChild($error);
            $code->removeChildNodes();
            $code->addChild($doc->createTextNode($iCode));
	    $time->addChild($doc->createTextNode(Time::HiRes::time()-$iStartTime));
	    $root->addChild($time);
            return formatOutput($refParams->{_format}, $doc);
        }
        my ($strModule, $strMethod) = split(/\./, $strMethodStr, 2);
        if((!defined $strModule) || (length($strModule)<1) ||
           (!defined $strMethod) || (length($strMethod)<1))
        {
            $iCode = Constants::ERR_METHOD_NOT_FOUND;
            my $error = $doc->createElement('errorDescription');
            $error->addChild($doc->createTextNode("'$strMethodStr' is not a valid method name"));
            $root->addChild($error);
            $code->removeChildNodes();
            $code->addChild($doc->createTextNode($iCode));
	        $time->addChild($doc->createTextNode(Time::HiRes::time()-$iStartTime));
	        $root->addChild($time);
            return formatOutput($refParams->{_format}, $doc);
        }
        # Check if the module is available.
	my $strCMD = "find $self->{_modules} -type f -name $strModule.pm";
	open(IN, "$strCMD |");
	my $strFilename = <IN>;
	close(IN);
        if(!$strFilename)
        {
            $iCode = Constants::ERR_METHOD_NOT_FOUND;
            my $error = $doc->createElement('errorDescription');
            $error->addChild($doc->createTextNode("The module '$strModule' is not available"));
            $root->addChild($error);
            $code->removeChildNodes();
            $code->addChild($doc->createTextNode($iCode));
	        $time->addChild($doc->createTextNode(Time::HiRes::time()-$iStartTime));
	        $root->addChild($time);
            return formatOutput($refParams->{_format}, $doc);
        }
	my $strPkgName = $strFilename;
	$strPkgName =~ s/$self->{_modules}/Axolotl::ATAPI/;
	$strPkgName =~ s/\//::/g;
	$strPkgName =~ s/\n//g;
	$strPkgName =~ s/.pm$//;
	eval("require $strPkgName");
	my $module = eval("new $strModule()");
	if($strModule eq 'Documentation')
	{
	    $module->init($self->{_modules});
	}
	else
	{
	    $module->init($self->{_db}, \&addNodes, $self->{_ps});
	}
	# If the request came from the server itself, then the user details are not known at this point. Update them.
	if($ENV{"REMOTE_ADDR"} eq "127.0.0.1")
	{
	    $refParams->{_parameters}->{_user} = $self->{_um}->getUserDetails($refParams->{_parameters}->{sid}, $ENV{"REMOTE_ADDR"});
	}
        # Execute the method.
        my $data = $doc->createElement('data');
        my $err = $doc->createElement('errorDescription');
        $iCode = $module->execute(_method => $strMethod,
                                  _parameters => $refParams->{_parameters},
                                  _xmldoc => $doc,
                                  _xmldata => $data,
                                  _xmlerr => $err);
        if($iCode==Constants::ERR_OK_BINARY)
        {
            return '';
        }
        else
        {
            if($refParams->{_parameters}->{debug})
            {
                use Data::Dumper;
                my $debug = $doc->createElement('debug');
                my $env = $doc->createElement('environment');
                $env->addChild($doc->createTextNode(Dumper \%ENV));
                $debug->addChild($env);
                my $params = $doc->createElement('params');
                $params->addChild($doc->createTextNode(Dumper $refParams));
                $debug->addChild($params);
                $root->addChild($debug);
            }
            $root->addChild(($iCode==Constants::ERR_OK) ? $data : $err);
            $code->removeChildNodes();
            $code->addChild($doc->createTextNode($iCode));
	        $time->addChild($doc->createTextNode(Time::HiRes::time()-$iStartTime));
	        $root->addChild($time);
	    return formatOutput($refParams->{_format}, $doc);
        }
    }

    sub parseParamStr
    {
        my $strParamStr = shift;
        my %hmParams = (_code => Constants::ERR_OK,
			_parameters => undef,
			_format => 'xml');
        if(!defined($strParamStr) || length($strParamStr)==0)
        {
            $hmParams{_code} = Constants::ERR_MALFORMED_QUERY;
            $hmParams{_errorDescription} = "The query string is empty";
            return \%hmParams;
        }
        my @arrChunks = split(/&/, $strParamStr);
        foreach my $strPair (@arrChunks)
        {
            if($strPair =~ m/^([^=]+)=(.*)$/s)
            {
                my $strParam = lc($1);
                if($strParam eq 'callbackparam')
                {
                    $hmParams{_callbackparam} = $2;
                }
                elsif($strParam eq 'requestid')
                {
                    $hmParams{_requestID} = $2;
                }
                elsif($strParam eq 'method')
                {
                    $hmParams{_method} = $2;
                }
                elsif($strParam eq 'format')
                {
                    if(lc($2) eq 'json')
		    {
			$hmParams{_format} = 'json';
		    }
                }
                elsif(substr($strParam,0,1) eq '_')
                {
                    next;
                }
                else
                {
                    my $refParams = $hmParams{_parameters};
                    $refParams = {} unless defined($refParams);
                    $refParams->{$1} = $2;
                    $hmParams{_parameters} = $refParams;
                }
            }
            else
            {
                $hmParams{_code} = Constants::ERR_MALFORMED_QUERY;
                $hmParams{_errorDescription} = "The following part of the query string is malformed: '$strPair'";
                return \%hmParams;
            }
        }
        return \%hmParams;
    }

    sub addNodes
    {
        my ($xmldoc, $parent, $refFields, $refResult) = @_;
        return 0 unless defined $refResult;
        my %hmFields = %{$refFields};
        my $nAdded = 0;
        foreach (keys %hmFields)
        {
            my $strColumn = $hmFields{$_}->{_column};
            # Proceed to the next field if the column name is not specified or the value is not defined.
            next if (!defined $strColumn);
            my $value = $refResult->{$strColumn};
            next if(!defined$value);    # Column value can be empty or 0, but not undef, therefore, use !defined.
            my $iType = (defined $hmFields{$_}->{_type}) ? $hmFields{$_}->{_type} : Constants::NT_TEXT;
            my $refReplaceMap = $hmFields{$_}->{_replace};
            # If replacement map is defined, replace the value. If no replacement exist, use the original value.
            if($refReplaceMap)
            {
                my $newValue = $refReplaceMap->{$value};
                $value = $newValue if defined $newValue;
            }
            my $child = undef;
            if($iType == Constants::NT_ELEMENT)
            {
                $child = $xmldoc->createElement($_);
                $child->addChild($xmldoc->createTextNode($value));
            }
            elsif($iType == Constants::NT_ATTRIBUTE)
            {
                $child = $xmldoc->createAttribute($_ => $value);
            }
            elsif($iType == Constants::NT_TEXT)
            {
                $child = $xmldoc->createTextNode($value);
            }
            else
            {
                next;
            }
            $parent->addChild($child);
            $nAdded++;
        }
        return $nAdded;
    }
    
    sub formatOutput
    {
	my ($strFormat, $doc) = @_;
	if($strFormat eq 'json')
	{
	    use JSON::Any;
	    use XML::Simple;
	    my $xml = XML::Simple::XMLin($doc->toString(), KeepRoot => 1, ForceArray => 1, KeyAttr => []);
	    my $strContent = JSON::Any->new()->objToJson($xml);
	    return "Content-type: text/html\n\n" . $strContent;
	}
	else
	{
	    return "Content-type: text/xml\n\n" . $doc->toString();
	}
    }
}

1;
