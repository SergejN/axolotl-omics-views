#!/usr/bin/env perl

#   File:
#       Documentation.pm
#
#   Description:
#       Contains the Documentation ATAPI module.
#
#   Version:
#       1.5.0
#
#   Date:
#       01.02.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna


package Documentation;
{
    sub new
    {
        my $class = shift;
        my $self = {_modules => undef};
        bless $self, $class;
        return $self;
    }
    
    sub init
    {
        my ($self, $strModules) = @_;
        $self->{_modules} = $strModules;
        return "Documentation";
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
        if($strMethod eq 'getDocumentation')
        {
            return $self->getDocumentation($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
	elsif($strMethod eq 'listModules')
        {
            return $self->listModules($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method 'Documentation.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getDocumentation
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my $strModule = $refParams->{module};
	# If the module name is not specified, return the general information on how to call the API methods.
	if(!$strModule)
        {
            my $documentation = $xmldoc->createElement('documentation');
	    # Call format.
	    my $call = $xmldoc->createElement('call');
	    $call->addChild($xmldoc->createTextNode("You can call the API functions using the following syntax:"));
	    my $syntax = $xmldoc->createElement('syntax');
	    $syntax->addChild($xmldoc->createTextNode("$refParams->{_base}/api?[PARAMETERS STRING]"));
	    $call->addChild($syntax);
	    # Parameters.
	    my $args = $xmldoc->createElement('arguments');
	    my @arrArgs =   ({_name => 'requestID',
			      _type => 'optional',
			      _description => 'Specifies a user-selected ID, which is returned to the caller, such that the caller can distinguish different API calls.'},
			     {_name => 'callbackParams',
			      _type => 'optional',
			      _description => 'Specifies a user-selected parameter string, which is returned to the caller'},
			     {_name => 'format',
			      _type => 'optional',
			      _description => 'Specifies the format of the returned data. Must be either "xml" (default) or "json".'},
			     {_name => 'method',
			      _type => 'required',
			      _description => 'Specifies the module and the method name. The format is <MODULE>.<METHOD>. The methods may require additional parameters. ' .
						    'Please, consult the module documentation for further details'});
	    foreach my $arg (@arrArgs)
	    {
		my $param = $xmldoc->createElement('argument');
		$param->addChild($xmldoc->createAttribute('name' => $arg->{_name}));
		$param->addChild($xmldoc->createAttribute('type' => $arg->{_type}));
		$param->addChild($xmldoc->createTextNode($arg->{_description}));
		$args->addChild($param);
	    }
	    $args->addChild($xmldoc->createTextNode("PARAMETERS STRING should be a sequence of '&'-separated param=value pairs"));
	    $call->addChild($args);
	    # Return values.
	    my $resultCodes = $xmldoc->createElement('resultCodes');
	    my @arrRetVals = ({_value => 'Constants::ERR_OK',
			       _numval => Constants::ERR_OK,
			       _desc => 'If succeeded'},
			      {_value => 'Constants::ERR_DB_ERROR',
			       _numval => Constants::ERR_DB_ERROR,
			       _desc => 'If the DB connection could not be established'},
			      {_value => 'Constants::ERR_MALFORMED_QUERY',
			       _numval => Constants::ERR_MALFORMED_QUERY,
			       _desc => 'If the query is malformed, e.g. is empty'},
			      {_value => 'Constants::ERR_METHOD_NOT_FOUND',
			       _numval => Constants::ERR_METHOD_NOT_FOUND,
			       _desc => 'If no method name is specified, or the method name is invalid'},
			      {_value => '-',
			       _numval => '-',
			       _desc => 'Method-specific return value'});
	    foreach my $rv (@arrRetVals)
	    {
		my $code = $xmldoc->createElement('code');
		$code->addChild($xmldoc->createAttribute('value' => $rv->{_value}));
		$code->addChild($xmldoc->createAttribute('numeric' => $rv->{_numval}));
		$code->addChild($xmldoc->createTextNode($rv->{_desc}));
		$resultCodes->addChild($code);
	    }
	    $call->addChild($resultCodes);
	    $documentation->addChild($call);
	    $xmldata->addChild($documentation);
	    return Constants::ERR_OK;
        }
	# Check if module exists and skipDocumentation returns 0.
	my $strCMD = "find $self->{_modules} -mindepth 2 -type f -name $strModule.pm";
	open(IN, "$strCMD |");
	my $strFilename = <IN>;
	close(IN);
	if(!$strFilename)
	{
	    $xmlerr->addChild($xmldoc->createTextNode("No documentation was found for the specified module."));
            return Constants::ERR_DATA_NOT_FOUND;
	}
	else
	{
	    my $strPkgName = $strFilename;
	    $strPkgName =~ s/$self->{_modules}/Axolotl::ATAPI/;
	    $strPkgName =~ s/\//::/g;
	    $strPkgName =~ s/\n//g;
	    $strPkgName =~ s/.pm$//;
	    eval("require $strPkgName");
	    my $module = eval("new $strModule()");
	    if(($module->can('skipDocumentation')) && $module->skipDocumentation())
	    {
		$xmlerr->addChild($xmldoc->createTextNode("No documentation was found for the specified module."));
		return Constants::ERR_DATA_NOT_FOUND;
	    }
	    my $entry = $xmldoc->createElement('module');
	    my $refVersion = $module->getVersion();
	    $entry->addChild($xmldoc->createAttribute('name' => $strModule));
	    $entry->addChild($xmldoc->createAttribute('version' => $refVersion->{version}));
	    $entry->addChild($xmldoc->createAttribute('releaseDate' => $refVersion->{released}));
	    $entry->addChild($xmldoc->createTextNode($module->getDescription()));
	    # Methods.
	    my @arrMethods = @{$module->getDocumentation($refParams)};
	    my $methods = $xmldoc->createElement('methods');
	    foreach my $m (@arrMethods)
	    {
		my $method = $xmldoc->createElement('method');
		$method->addChild($xmldoc->createAttribute('name' => $m->{_name}));
		# Deprecated.
		if($m->{_deprecated})
		{
		    $method->addChild($xmldoc->createAttribute('deprecated' => $m->{_deprecated}->{_since}));
		    $method->addChild($xmldoc->createAttribute('replacement' => $m->{_deprecated}->{_replacement}));
		}
		$method->addChild($xmldoc->createTextNode($m->{_description}));
		# Arguments.
		my $args = $xmldoc->createElement('args');
		if($m->{_args})
		{
		    my @arrArgs = @{$m->{_args}};
		    foreach my $arg (@arrArgs)
		    {
			my $param = $xmldoc->createElement('argument');
			$param->addChild($xmldoc->createAttribute('name' => $arg->{_name}));
			$param->addChild($xmldoc->createAttribute('type' => $arg->{_type}));
			$param->addChild($xmldoc->createAttribute('default' => $arg->{_default}));
			$param->addChild($xmldoc->createTextNode($arg->{_description}));
			$args->addChild($param);
		    }
		    $method->addChild($args);
		}
		# Result codes.
		my $resCodes = $xmldoc->createElement('resultCodes');
		my @arrCodes = @{$m->{_resultCode}};
		foreach my $c (@arrCodes)
		{
		    my $rc = $xmldoc->createElement('code');
		    $rc->addChild($xmldoc->createAttribute('value' => $c->{_value}));
		    $rc->addChild($xmldoc->createAttribute('numeric' => $c->{_numval}));
		    $rc->addChild($xmldoc->createTextNode($c->{_description}));
		    $resCodes->addChild($rc);
		}
		$method->addChild($resCodes);
		# Sample
		my $example = $xmldoc->createElement('example');
		$example->addChild($xmldoc->createTextNode($m->{_sample}));
		$method->addChild($example);
		# Remarks.
		if($m->{_remarks})
		{
		    my $remarks = $xmldoc->createElement('remarks');
		    $remarks->addChild($xmldoc->createTextNode($m->{_remarks}));
		    $method->addChild($remarks);
		}
		$methods->addChild($method);
	    }
	    $entry->addChild($methods);
	    $xmldata->addChild($entry);
	    return Constants::ERR_OK; 
	}
    }
    
    sub listModules
    {
	my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
	my $modules = $xmldoc->createElement('modules');
	my $strCMD = "find $self->{_modules} -mindepth 2 -type f -name *.pm";
	open(IN, "$strCMD |");
	while(my $strFilename = <IN>)
	{
	    chomp($strFilename);
	    my $strPkgName = $strFilename;
	    $strPkgName =~ s/$self->{_modules}/Axolotl::ATAPI/;
	    $strPkgName =~ s/\//::/g;
	    $strPkgName =~ s/\n//g;
	    $strPkgName =~ s/.pm$//;
	    if($strPkgName =~ m/([A-Za-z0-9]+)$/)
	    {
		eval("require $strPkgName");
		my $module = eval("new $1()");
		next if($module->can('skipDocumentation') && $module->skipDocumentation());
		my $entry = $xmldoc->createElement('module');
		$entry->addChild($xmldoc->createAttribute('name' => $1));
		if($module->can('getDescription'))
		{
		    $entry->addChild($xmldoc->createTextNode($module->getDescription()));
		}
		$modules->addChild($entry);
	    }
	}
	close(IN);
	$xmldata->addChild($modules);
        return Constants::ERR_OK; 
    }
}

1;