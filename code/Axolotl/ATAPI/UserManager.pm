#!/usr/bin/env perl

#   File:
#       UserManager.pm
#
#   Description:
#       Contains the UserManager module.
#	UserManager 
#
#   Version:
#       1.5.0
#
#   Date:
#       01.02.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna


package UserManager;
{
    sub new
    {
        my ($class, $strDBName, $strHost, $strDBUser, $strDBPass) = @_;
	my @arrConfig = ("DBI:mysql:database=$strDBName;host=$strHost", $strDBUser, $strDBPass);
        my $hDB = DBI->connect(@arrConfig);
	my $self = {_db => $hDB};
        bless $self, $class;
        return $self;
    }
    
    sub DESTROY
    {
        my $self = shift;
        $self->{_db}->disconnect() if defined $self->{_db};
        return Constants::ERR_OK;
    }
    
    sub getUserDetails
    {
        my ($self, $sid, $ip, $strAgent) = @_;
        my $refUser = {name => undef,
                       privilege => Constants::UP_GUEST,
                       sid => undef,
		       email => undef};
        return $refUser if(!$sid || !$ip);
        my $bLocal = ($ip eq $ENV{"SERVER_ADDR"});
        my $strQuery = "SELECT privilege, ".
			      "firstname, ".
			      "lastname, ".
			      "degree, ".
			      "email, ".
			      "IF(expires>CURRENT_TIMESTAMP,1,0) AS valid ".
		       "FROM User ".
			    "INNER JOIN UserSession ON User.u_id=UserSession.u_id ".
		       "WHERE sid='$sid' AND agent='$strAgent';";
        if($bLocal)
        {
            $strQuery = "SELECT privilege, ".
			       "firstname, ".
			       "lastname, ".
			       "degree, ".
			       "email, ".
			       "1 AS valid ".
			"FROM User ".
			"WHERE u_id=(SELECT DISTINCT u_id FROM UserSession WHERE sid='$sid');";
        }
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if($refResult)
        {
            if($refResult->{valid})
            {
		$refUser->{privilege} = $refResult->{privilege};
                $refUser->{sid} = $sid;
                $refUser->{name} = "$refResult->{firstname} $refResult->{lastname}";
		if($refResult->{degree})
		{
		    if( ($refResult->{degree} eq 'Prof. Dr.') || ($refResult->{degree} eq 'Dr.') )
		    {
			$refUser->{name} = "$refResult->{degree} $refUser->{name}" if $refResult->{degree};
		    }
		}
		$refUser->{email} = $refResult->{email};
		$strQuery = "UPDATE UserSession SET expires=DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 7 DAY) WHERE sid='$sid'";
		my $statement = $self->{_db}->prepare($strQuery);
                $statement->execute();
            }
            else
            {
                $strQuery = "DELETE FROM UserSession WHERE sid='$sid';";
                my $statement = $self->{_db}->prepare($strQuery);
                $statement->execute();
            }
        }
        return $refUser;
    }
}

1;