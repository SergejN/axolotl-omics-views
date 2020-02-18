#!/usr/bin/env perl

#   File:
#       Constants.pm
#
#   Description:
#       Contains the axolotl website API constants.
#
#   Version:
#       3.0.1
#
#   Date:
#       2016-04-26
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;


package Constants;
{
    use constant AORESULT_OK                     => 0;
    use constant AORESULT_FAILURE                => -1;
    
    use constant AORESULT_INVALID_PARAMETER      => 1;
    use constant AORESULT_NOT_ENOUGH_PARAMETERS  => 2;
    use constant AORESULT_MODULE_NOT_FOUND       => 3;
    
    use constant AORESULT_DB_NOT_CONNECTED       => 10;
    use constant AORESULT_DB_ACCESS_DENIED       => 11;
    
    use constant AORESULT_METHOD_NOT_FOUND       => 100;
    use constant AORESULT_DATA_NOT_FOUND         => 200;
    use constant AORESULT_DATA_EXISTS            => 201;
    
    our @EXPORT_OK = ('AORESULT_OK',
                      'AORESULT_FAILURE',
                      
                      'AORESULT_INVALID_PARAMETER',
                      'AORESULT_NOT_ENOUGH_PARAMETERS',
                      'AORESULT_MODULE_NOT_FOUND',
                      
                      'AORESULT_DB_NOT_CONNECTED',
                      'AORESULT_DB_ACCESS_DENIED',
                      
                      'AORESULT_METHOD_NOT_FOUND',
                      'AORESULT_DATA_NOT_FOUND',
                      'AORESULT_DATA_EXISTS');
}

1;