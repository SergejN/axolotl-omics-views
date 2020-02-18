#!/usr/bin/env perl

#   File:
#       Utils.pm
#
#   Description:
#       Contains the Utils module.
#
#   Version:
#       1.0.1
#
#   Date:
#       09.02.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna


use strict;
use POSIX;

package Utils;
{
    sub getTime
    {
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = @_;
        $year -= 1900 if($year>=1900);
        my $time = POSIX::mktime($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = ($time && $time>0) ? localtime($time)
                                                                                           : localtime();
        my @arrMonths = ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
        my @arrWDays = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
        return {second => $sec,
                minute => $min,
                hour => $hour,
                dayOfMonth => $mday,
                month => $mon+1,
                month_s => $arrMonths[$mon],
                year => $year+1900,
                dayOfWeek => $wday+1,
                dayOfWeek_s => $arrWDays[$wday],
                dayOfYear => $yday+1};
    }
}

1;