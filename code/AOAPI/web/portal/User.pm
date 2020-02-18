#!/usr/bin/env perl

#   File:
#       User.pm
#
#   Description:
#       Manages the users of the portal.
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
use DBI;
use JSON;

use AOAPI::core::Constants;
use AOAPI::utils::EntriesList;


package UserEntry;
{
    sub new
    {
        my ($class, $refUserData) = @_;
        my $refData = {id => $refUserData->{user_id},
                       title => $refUserData->{title},
                       lastname => $refUserData->{lastname},
                       firstname => $refUserData->{firstname},
                       affiliation => {institution => $refUserData->{affiliation},
                                       street => $refUserData->{street},
                                       zip => $refUserData->{zip},
                                       city => $refUserData->{city},
                                       country => $refUserData->{country}}};
        my $self = {data => $refData};
        bless $self, $class;
        return $self;
    }
    
    sub asBinary
    {
        my $self = shift;
        return $self->{data};
    }
    
    sub asJSON
    {
        my ($self) = shift;
        return ::encode_json($self->{data});
    }
    
    sub asText
    {
        my ($self) = shift;
        return sprintf("%d\t%s\t%s\t%s\t%s, %s, %s %s, %s\n",
                        $self->{data}->{id},
                        $self->{data}->{title},
                        $self->{data}->{lastname},
                        $self->{data}->{firstname},
                        $self->{data}->{affiliation}->{institution},
                        $self->{data}->{affiliation}->{street},
                        $self->{data}->{affiliation}->{zip}, $self->{data}->{affiliation}->{city},
                        $self->{data}->{affiliation}->{country});
    }
    
    sub asXML
    {
        my ($self) = shift;
        my $strPattern = '<user id="%d" title="%s" lastname="%s" firstname="%s">'.
                            '<affiliation street="%s" zip="%s" city="%s" country="%s">%s</affiliation>'.
                         '</user>';
        return sprintf($strPattern,
                       $self->{data}->{id},
                       $self->{data}->{title},
                       $self->{data}->{lastname},
                       $self->{data}->{firstname},
                       $self->{data}->{affiliation}->{street},
                       $self->{data}->{affiliation}->{zip}, $self->{data}->{affiliation}->{city},
                       $self->{data}->{affiliation}->{country},
                       $self->{data}->{affiliation}->{institution});
    }
}


package User;
{
    my $MODULE = 'User';
    my $VERSION = '3.0.1';
    my $DATE = '2016-04-26';
    
    
    sub getName
    {
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Incapsulates the user management sub system";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
    }
    
    sub new
    {
        my ($class) = @_;
        my $self = {database => undef};
        bless $self, $class;
        return $self;
    }
    
    sub init
    {
        my ($self, $hDB) = @_;
        $self->{database} = $hDB;
    }
    
    sub getDocumentation
    {
        my ($self, $refParams) = @_;
        my @arrMethods = ({_name => 'find',
                           _description => 'Returns the list of users matching the search criteria',
			   _args => [{_name => 'mask',
                                      _description => 'specifies the mask for the search. If this parameter is empty, all users are found',
                                      _type => 'optional',
                                      _default => ''},
                                     ###
                                     {_name => 'mask',
                                      _description => 'specifies the mask for the search. If this parameter is empty, all users are found',
                                      _type => 'optional',
                                      _default => ''},
                                     ###
                                     {_name => 'first',
                                      _description => 'specifies the 0-based first index to retrieve. This parameter is used to split a long resulting list into pieces',
                                      _type => 'optional',
                                      _default => '0'},
                                     ###
                                     {_name => 'count',
                                      _description => 'specifies the maximal number of entries to return',
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::AORESULT_OK',
                                            _numval => Constants::AORESULT_OK,
                                            _description => 'if succeeds'},
                                           ###
                                           {_value => 'Constants::AORESULT_DB_NOT_CONNECTED',
                                            _numval => Constants::AORESULT_DB_NOT_CONNECTED,
                                            _description => 'if the database connection could not be established'}],
                           _sample => "$refParams->{_apibase}?format=xml&method=$MODULE.find&mask=Dresden&first=5&count=7"},
                          
                          {_name => 'find',
                           _description => 'Returns the list of users matching the search criteria',
			   _args => [{_name => 'mask',
                                      _description => 'specifies the mask for the search. If this parameter is empty, all users are found',
                                      _type => 'optional',
                                      _default => ''},
                                     ###
                                     {_name => 'mask',
                                      _description => 'specifies the mask for the search. If this parameter is empty, all users are found',
                                      _type => 'optional',
                                      _default => ''},
                                     ###
                                     {_name => 'first',
                                      _description => 'specifies the 0-based first index to retrieve. This parameter is used to split a long resulting list into pieces',
                                      _type => 'optional',
                                      _default => '0'},
                                     ###
                                     {_name => 'count',
                                      _description => 'specifies the maximal number of entries to return',
                                      _type => 'optional',
                                      _default => ''}],
                           _resultCode => [{_value => 'Constants::AORESULT_OK',
                                            _numval => Constants::AORESULT_OK,
                                            _description => 'if succeeds'},
                                           ###
                                           {_value => 'Constants::AORESULT_DB_NOT_CONNECTED',
                                            _numval => Constants::AORESULT_DB_NOT_CONNECTED,
                                            _description => 'if the database connection could not be established'}],
                           _sample => "$refParams->{_base}/api?method=$MODULE.findSequencesWithDomain&domain=PF09103"});
        return \@arrMethods;
    }
    
    sub execute
    {
        my ($self, $refParams) = @_;
        my $strMethod = lc($refParams->{_method});
        my $refMethodParams = $refParams->{_parameters};
        # Execute the method.
        if($strMethod eq 'find')
        {
            return $self->find($refMethodParams);
        }
        elsif($strMethod eq lc('getList'))
        {
            $refMethodParams->{term} = undef;
            return $self->find($refMethodParams);
        }
        elsif($strMethod eq lc('getCount'))
        {
            return $self->getCount($refMethodParams);
        }
        elsif($strMethod eq lc('getDetails'))
        {
            return $self->getDetails($refMethodParams);
        }
        elsif($strMethod eq lc('addUser'))
        {
            return $self->addUser($refMethodParams);
        }
        elsif($strMethod eq lc('deleteUser'))
        {
            return $self->deleteUser($refMethodParams);
        }
        elsif($strMethod eq lc('changePassword'))
        {
            return $self->changePassword($refMethodParams);
        }
        elsif($strMethod eq lc('resetPassword'))
        {
            return $self->resetPassword($refMethodParams);
        }
        elsif($strMethod eq lc('changePrivilege'))
        {
            return $self->changePrivilege($refMethodParams);
        }
        elsif($strMethod eq lc('updateDetails'))
        {
            return $self->updateDetails($refMethodParams);
        }
        return undef;
    }
    
    sub find
    {
        my ($self, $refParams) = @_;
        my $strQuery = "SELECT user_id, ".
                              "title, ".
                              "lastname, ".
                              "firstname, ".
                              "affiliation, ".
                              "street, ".
                              "zip, ".
                              "city, ".
                              "country ".
                       "FROM User";
        if($refParams->{term})
        {
            $refParams->{term} =~ s/'/\\'/;
            $strQuery .= " WHERE title LIKE '%$refParams->{term}%' OR ".
                                "firstname LIKE '%$refParams->{term}%' OR ".
                                "lastname LIKE '%$refParams->{term}%' OR ".
                                "affiliation LIKE '%$refParams->{term}%' OR ".
                                "email LIKE '%$refParams->{term}%' OR ".
                                "street LIKE '%$refParams->{term}%' OR ".
                                "zip LIKE '%$refParams->{term}%' OR ".
                                "city LIKE '%$refParams->{term}%' OR ".
                                "country LIKE '%$refParams->{term}%'";
        }
        my $nCount = int($refParams->{count});
        if($nCount > 0)
        {
            my $iFirst = int($refParams->{first});
            if($iFirst > 0)
            {
                $strQuery .= " LIMIT $iFirst,$nCount";
            }
            else
            {
                $strQuery .= " LIMIT $nCount";
            }
        }
        my $stmt = $self->{database}->prepare($strQuery);
        $stmt->execute();
        my $usersList = new EntriesList('users');
        while(my $refResult = $stmt->fetchrow_hashref())
        {
            $usersList->addEntry(new UserEntry($refResult));
        }
        $stmt->finish();
        return {result => Constants::AORESULT_OK,
                data => $usersList};
    }
    
    sub getCount
    {
        my ($self, $refParams) = @_;
        my $strQuery = "SELECT COUNT(*) ".
                       "FROM User";
        if($refParams->{term})
        {
            $strQuery .= " WHERE title LIKE '%$refParams->{term}%' OR ".
                                "firstname LIKE '%$refParams->{term}%' OR ".
                                "lastname LIKE '%$refParams->{term}%' OR ".
                                "affiliation LIKE '%$refParams->{term}%' OR ".
                                "street LIKE '%$refParams->{term}%' OR ".
                                "zip LIKE '%$refParams->{term}%' OR ".
                                "city LIKE '%$refParams->{term}%' OR ".
                                "country LIKE '%$refParams->{term}%'";
        }
        my ($nCount) = $self->{database}->selectrow_array($strQuery);
        return {result => Constants::AORESULT_OK,
                data => $nCount};
    }
    
    sub getDetails
    {
        my ($self, $refParams) = @_;
        my $user_id = int($refParams->{id});
        if($user_id < 1)
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The user ID is either not specified or invalid"};
        }
        my $strQuery = "SELECT user_id, ".
                              "title, ".
                              "lastname, ".
                              "firstname, ".
                              "email, ".
                              "affiliation, ".
                              "street, ".
                              "zip, ".
                              "city, ".
                              "country ".
                       "FROM User ".
                       "WHERE user_id = $user_id";
        my $refResult = $self->{database}->selectrow_hashref($strQuery);
        if($refResult)
        {
            return {result => Constants::AORESULT_OK,
                    data => new UserEntry($refResult)};
        }
        return {result => Constants::AORESULT_DATA_NOT_FOUND,
                msg => "The specified user does not exist"};
    }
    
    sub addUser
    {
        my ($self, $refParams) = @_;
        if(!$refParams->{lastname})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The last name is not specified"};
        }
        if(!$refParams->{firstname})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The first name is not specified"};
        }
        if(!$refParams->{email})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The e-mail address is not specified"};
        }
        my $strUserName = qr/[A-Za-z0-9_][A-Za-z0-9_+.]*[A-Za-z0-9_+]?/;
        my $strDomain = qr/[A-Za-z0-9.-_]+\.[A-Za-z]{2,}/;
        if($refParams->{email} !~ m/^$strUserName\@$strDomain$/)
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The e-mail address is not valid"};
        }
        if(!$refParams->{password})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The password is not specified"};
        }
        if(!$refParams->{affiliation} ||
           !$refParams->{street} ||
           !$refParams->{zip} ||
           !$refParams->{city} ||
           !$refParams->{country})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The affiliation is incomplete"};
        }
        
        # Check if the user already exists.
        my $strQuery = "SELECT COUNT(*) FROM User WHERE email='$refParams->{email}'";
        my ($nCount) = $self->{database}->selectrow_array($strQuery);
        if($nCount)
        {
            return {result => Constants::AORESULT_DATA_EXISTS,
                    msg => "The user with the specified e-mail already exists"};
        }
        
        $strQuery = "INSERT INTO User ".
                               "(title, firstname, lastname, email, password, privilege, affiliation, street, zip, city, country) ".
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        my $stmt = $self->{database}->prepare($strQuery);
        my $bSucceeded = $stmt->execute($refParams->{title},
                                        $refParams->{firstname},
                                        $refParams->{lastname},
                                        $refParams->{email},
                                        "<NO_PASSWORD_SET>",
                                        "(SELECT FROM enumUserPrivilege WHERE name='Registered')",
                                        $refParams->{affiliation},
                                        $refParams->{street},
                                        $refParams->{zip},
                                        $refParams->{city},
                                        $refParams->{country});
        $stmt->finish();
        if(!$bSucceeded)
        {
            return {result => Constants::AORESULT_DB_ACCESS_DENIED,
                    msg => "You do not have the privilege to perform this action"};
        }
        $refParams->{currentpass} = '<NO_PASSWORD_SET>';
        $refParams->{newpass} = $refParams->{password};
        return $self->changePassword($refParams);
    }
    
    sub changePassword
    {
        my ($self, $refParams) = @_;
        if(!$refParams->{email})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The e-mail address is not specified"};
        }
        my $strUserName = qr/[A-Za-z0-9_][A-Za-z0-9_+.]*[A-Za-z0-9_+]?/;
        my $strDomain = qr/[A-Za-z0-9.-_]+\.[A-Za-z]{2,}/;
        if($refParams->{email} !~ m/^$strUserName\@$strDomain$/)
        {
            return {result => Constants::AORESULT_INVALID_PARAMETER,
                    msg => "The e-mail address is not valid"};
        }
        if(!$refParams->{currentpass})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The current password is not specified"};
        }
        if(!$refParams->{newpass})
        {
            return {result => Constants::AORESULT_NOT_ENOUGH_PARAMETERS,
                    msg => "The new password is not specified"};
        }
        return {result => Constants::AORESULT_OK};
    }
}

1;

