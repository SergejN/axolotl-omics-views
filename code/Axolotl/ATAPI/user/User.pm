#!/usr/bin/env perl

#   File:
#       Service.pm
#
#   Description:
#       Contains the User module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.1.2
#
#   Date:
#       24.06.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;
use IP::Country::Fast;
use Axolotl::Mailer;
use JSON;


package User;
{
    my $MODULE = 'User';
    my $VERSION = '1.1.2';
    my $DATE = '2015-09-18';
    my $KEY_USER_HISTORY = '{D2C9E865-979C-48F7-B2FF-9EEC07A92135}';
    my $KEY_USER_BLAST = '{74742DF4-F3FA-4773-869C-E98B2ACA03DD}';
    my $MAX_HISTORY_LENGTH = 25;
    
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
        $self->{_mailing} = $ps->getSetting('USER', 'mailing');
        $self->{_email} = $ps->getSetting('USER', 'admin');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Encapsulates several methods requited for user management";
    }
    
    sub getVersion
    {
	return {version => $VERSION, released => $DATE};
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
        if($strMethod eq 'login')
        {
            return $self->login($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'logout')
        {
            return $self->logout($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'register')
        {
            return $self->register($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'requestActionToken')
        {
            return $self->requestActionToken($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getBookmarkDetails')
        {
            return $self->getBookmarkDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'toggleBookmark')
        {
            return $self->toggleBookmark($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getDetails')
        {
            return $self->getDetails($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'changePassword')
        {
            return $self->changePassword($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getData')
        {
            return $self->getData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'setData')
        {
            return $self->setData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'deleteData')
        {
            return $self->deleteData($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'addToHistory')
        {
            return $self->addToHistory($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'addBlastQuery')
        {
            return $self->addBlastQuery($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub login
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{email})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the e-mail"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        # First, get the user ID.
        $refParams->{email} =~ s/'/\\'/g;
        $refParams->{pass} =~ s/'/\\'/g;
        my $strQuery = "SELECT u_id FROM User WHERE email='" . lc($refParams->{email}) . "' AND pass=MD5('$refParams->{pass}');";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Incorrect e-mail or password"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $u_id = $refResult->{u_id};
        # Check, if there is an active session for the specified user and his current IP address.
        $strQuery = "SELECT sid FROM UserSession WHERE u_id=$u_id AND agent='$refParams->{_userAgent}';";
        $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $strQuery = "INSERT INTO UserSession (u_id, sid, ip, agent, signed, expires) ".
                                         "VALUES ($u_id, MD5(RAND()), '$refParams->{_remoteAddress}', '$refParams->{_userAgent}', CURRENT_TIMESTAMP, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 7 DAY));";
            my $statement = $self->{_db}->prepare($strQuery);
            $statement->execute();
            $strQuery = "SELECT sid FROM UserSession WHERE u_id=$u_id AND agent='$refParams->{_userAgent}';";
            $refResult = $self->{_db}->selectrow_hashref($strQuery);
        }
        my $user = $xmldoc->createElement('user');
        $user->addChild($xmldoc->createAttribute('sid' => $refResult->{sid}));
        $xmldata->addChild($user);
        return Constants::ERR_OK;
    }
    
    sub logout
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = ($refParams->{_user}->{sid}) ? $refParams->{_user}->{sid} : $refParams->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the session ID"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strQuery = "DELETE FROM UserSession WHERE sid='$sid';";
        if(defined $refParams->{keepCurrent})
        {
            $strQuery = "DELETE FROM UserSession ".
                        "WHERE u_id=(SELECT u_id FROM (SELECT * FROM UserSession) AS tmp WHERE tmp.sid='$sid') ".
                              "AND NOT sid='$sid';";
        }
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        return Constants::ERR_OK;
    }
    
    sub register
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        if(!$refParams->{email})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the e-mail"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{email} =~ s/'/\\'/g;
        if(!$refParams->{pass})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the password"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{pass} =~ s/'/\\'/g;
        if(!$refParams->{firstname})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Please, specify your first name"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{email} =~ s/'/\\'/g;
        if(!$refParams->{lastname})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Please, specify your last name"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{lastname} =~ s/'/\\'/g;
        if(!$refParams->{institution})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Please, specify your institution"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{institution} =~ s/'/\\'/g;
        if(!$refParams->{address})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Please, specify your contact address"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if($refParams->{'gtc'} ne 'true')
        {
            $xmlerr->addChild($xmldoc->createTextNode("You must agree to the privacy policy"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{address} =~ s/'/\\'/g;
        my $strQuery = "INSERT INTO User (firstname, lastname, degree, email, pass, institution, address, privilege) VALUES " .
                            "('$refParams->{firstname}', '$refParams->{lastname}', '$refParams->{degree}', '$refParams->{email}', MD5('$refParams->{pass}'), " .
                            "'$refParams->{institution}', '$refParams->{address}', 3);";
        my $statement = $self->{_db}->prepare($strQuery);
        if(!$statement->execute())
        {
            $xmlerr->addChild($xmldoc->createTextNode("The specified e-mail already exists"));
            return Constants::ERR_DATA_EXISTS;
        }
        # Send notification to the administrator.
        my $mailer = new Mailer($self->{_mailing});
        my $strContent = "Dear administrator,<br /><br />".
                         "a new user has registered:".
                         "<div id=\"email-msg\">Name: $refParams->{degree} $refParams->{firstname} $refParams->{lastname}</div>".
                         "<br /><br /><br />Sincerely,<br />Axolotl-omics.org server";
        $mailer->sendMail($self->{_email}, 'New user', $strContent);
        return $self->login($refParams, $xmldoc, $xmldata, $xmlerr);
    }
    
    sub requestActionToken
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = ($refParams->{_user}->{sid}) ? $refParams->{_user}->{sid} : $refParams->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the session ID"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strQuery = "SELECT MD5(CONCAT(MD5(ip), MD5(agent), MD5(CURRENT_TIMESTAMP))) AS token, ".
                              "CURRENT_TIMESTAMP AS tokenexp, ".
                              "MD5(CURRENT_TIMESTAMP) AS tokenval ".
                       "FROM UserSession ".
                       "WHERE sid='$sid'";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid session ID"));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        $strQuery = "UPDATE UserSession ".
                    "SET token='$refResult->{token}', ".
                        "tokenexp='$refResult->{tokenexp}' ".
                    "WHERE sid='$sid'"; 
        my $token = $xmldoc->createElement('token');
        my $statement = $self->{_db}->prepare($strQuery);
        if(!$statement->execute())
        {
            $xmlerr->addChild($xmldoc->createTextNode("Failed to generate the action token"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        $token->addChild($xmldoc->createTextNode($refResult->{tokenval}));
        $xmldata->addChild($token);
        return Constants::ERR_OK;
    }
    
    sub getBookmarkDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strSeqID = $refParams->{itemID};
        if(!$strSeqID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the sequence ID"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strSeqID =~ s/'/\\'/g;
        my $strClass = lc($refParams->{class});
        if(!$strClass)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the bookmark class"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my %hmSources = ('transcript' => {join => 'INNER JOIN Contig ON Contig.c_id=UserBookmarks.seq_id',
                                          where => "AND Contig.name='$strSeqID'",
                                          type => 'transcript'},
                         'libseq'     => {join => 'INNER JOIN LibrarySequence ON LibrarySequence.ls_id=UserBookmarks.seq_id',
                                          where => "AND LibrarySequence.name='$strSeqID'",
                                          type => 'libseq'},
                         'probe'      => {join => 'INNER JOIN MicroarrayProbe ON MicroarrayProbe.map_id=UserBookmarks.seq_id',
                                          where => "AND MicroarrayProbe.name='$strSeqID'",
                                          type => 'probe'},
                         'gene'       => {join => 'INNER JOIN Gene ON Gene.g_id=UserBookmarks.seq_id',
                                          where => "AND Gene.name='$strSeqID'",
                                          type => 'gene'});
        my $constraint = $hmSources{$strClass} || $hmSources{'transcript'};
        my $strQuery = "SELECT comment, ".
                              "timestamp ".
                       "FROM UserBookmarks ".
                            "$constraint->{join} ".
                            "INNER JOIN SequenceType ON UserBookmarks.st_id=SequenceType.st_id ".
                       "WHERE u_id=(SELECT u_id FROM UserSession WHERE sid='$sid') ".
                             "$constraint->{where} ".
                             "AND SequenceType.name='$constraint->{type}'";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if($refResult)
        {
            my $bookmark = $xmldoc->createElement('bookmark');
            $bookmark->addChild($xmldoc->createAttribute(id => $strSeqID));
            $bookmark->addChild($xmldoc->createAttribute(comment => $refResult->{comment}));
            $bookmark->addChild($xmldoc->createAttribute(timestamp => $refResult->{timestamp}));
            $bookmark->addChild($xmldoc->createAttribute(type => $constraint->{type}));
            $xmldata->addChild($bookmark);
            return Constants::ERR_OK;
        }
        else
        {
            return Constants::ERR_DATA_NOT_FOUND;
        }
    }
    
    sub toggleBookmark
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strSeqID = $refParams->{itemID};
        if(!$strSeqID)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the sequence ID"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strSeqID =~ s/'/\\'/g;
        my $strClass = lc($refParams->{class});
        if(!$strClass)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the bookmark class"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strClass =~ s/'/\\'/g;
        my $strComment = $refParams->{comment} || '';
        $strComment =~ s/'/\\'/g;
        # Check if the SID is valid.
        my $strQuery = "SELECT u_id FROM UserSession WHERE sid='$sid';";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The session ID is invalid or has expired"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        my $u_id = $refResult->{u_id};
        my $strAction = lc($refParams->{action});
        my %hmSources = ('transcript' => {get_id => "SELECT c_id AS id FROM Contig WHERE name='$strSeqID'",
                                          err_msg => 'The contig with the specified name does not exist',
                                          type => 'transcript'},
                         'libseq'     => {get_id => "SELECT ls_id AS id FROM LibrarySequence WHERE name='$strSeqID'",
                                          err_msg => 'The library sequence with the specified name does not exist',
                                          type => 'libseq'},
                         'probe'      => {get_id => "SELECT map_id AS id FROM MicroarrayProbe WHERE name='$strSeqID'",
                                          err_msg => 'The probe with the specified name does not exist',
                                          type => 'probe'},
                         'gene'       => {get_id => "SELECT g_id AS id FROM Gene WHERE name='$strSeqID'",
                                          err_msg => 'The gene with the specified name does not exist',
                                          type => 'gene'});
        my $queries = $hmSources{$strClass} || $hmSources{'transcript'};
        $refResult = $self->{_db}->selectrow_hashref($queries->{get_id});
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode($queries->{err_msg}));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $seqID = $refResult->{id};
        if($strAction eq 'add')
        {
            # Only add favorite if it does not already exist. Otherwise, simply edit the comment.
            $strQuery = "SELECT COUNT(*) AS count ".
                        "FROM UserBookmarks ".
                             "INNER JOIN SequenceType ON UserBookmarks.st_id=SequenceType.st_id ".
                        "WHERE u_id=$u_id AND seq_id=$seqID AND SequenceType.name='$queries->{type}';";
            my $refResult = $self->{_db}->selectrow_hashref($strQuery);
            return Constants::ERR_OK if($refResult->{count}>0);
            $strQuery = "INSERT INTO UserBookmarks (u_id, seq_id, st_id, comment) ".
                        "VALUES ($u_id, $seqID, (SELECT st_id FROM SequenceType WHERE name='$queries->{type}'), '$strComment');";
        }
        elsif($strAction eq 'remove')
        {
            $strQuery = "DELETE FROM UserBookmarks ".
                        "WHERE u_id=$u_id AND seq_id=$seqID AND st_id=(SELECT st_id FROM SequenceType WHERE name='$queries->{type}')";
        }
        else
        {
            $strQuery = "UPDATE UserBookmarks ".
                        "SET comment='$strComment' ".
                        "WHERE u_id=$u_id AND seq_id=$seqID AND st_id=(SELECT st_id FROM SequenceType WHERE name='$queries->{type}')";
        }
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        return Constants::ERR_OK;
    }
    
    sub getData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strKey = $refParams->{key};
        if(!$strKey)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the key to retrieve the data for"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strKey =~ s/'/\\'/g;
        my $strQuery = "SELECT `key`, value FROM UserData INNER JOIN UserSession ON UserData.u_id=UserSession.u_id WHERE UserSession.sid='$sid';";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            $refResult->{value} =~s/\\'/'/g;
            my $item = $xmldoc->createElement('item');
            $item->addChild($xmldoc->createAttribute(key => $refResult->{key}));
            $item->addChild($xmldoc->createTextNode($refResult->{value}));
            $xmldata->addChild($item);
        }
        return Constants::ERR_OK; 
    }
    
    sub setData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strKey = $refParams->{key};
        if(!$strKey)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the key"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strKey =~ s/'/\\'/g;
        my $strValue = $refParams->{value};
        if(!$strValue)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the value"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strValue =~ s/'/\\'/g;
        # First, check if the value exists. If it does, replace the value. Otherwise, add a new row.
        my $strQuery = "SELECT COUNT(*) AS count, ".
                              "UserData.ud_id AS ud_id ".
                       "FROM UserData ".
                            "INNER JOIN UserSession ON UserData.u_id=UserSession.u_id ".
                       "WHERE UserSession.sid='$sid' AND `key`='$strKey';";
        my ($nCount, $ud_id) = $self->{_db}->selectrow_array($strQuery);
        $strQuery = ($nCount) ? "UPDATE UserData SET value = '$strValue' WHERE ud_id=$ud_id;"
                              : "INSERT INTO UserData (u_id, `key`, value) VALUES ((SELECT u_id FROM UserSession WHERE sid='$sid'), '$strKey', '$strValue');";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        return Constants::ERR_OK; 
    }
    
    sub deleteData
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_DATA_NOT_FOUND;
        }
        my $strKey = $refParams->{key};
        if(!$strKey)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the key"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strKey =~ s/'/\\'/g;
        my $strQuery = "DELETE FROM UserData WHERE `key`='$strKey' AND u_id=(SELECT u_id FROM UserSession WHERE sid='$sid');";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        return Constants::ERR_OK; 
    }
    
    sub getDetails
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strType = lc($refParams->{type});
        if(!$strType)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Specify the type of information"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_ACCESS_DENIED;
        }
        my $details = $xmldoc->createElement('details');
        $details->addChild($xmldoc->createAttribute('type' => $strType));
        my $iResult = Constants::ERR_OK;
        if($strType eq 'general')
        {
            $iResult = $self->getDetails_general($sid, $details, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strType eq 'bookmarks')
        {
            $iResult = $self->getDetails_bookmarks($sid, $details, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strType eq 'session')
        {
            $iResult = $self->getDetails_sessions($sid, $details, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strType eq 'history')
        {
            $iResult = $self->getDetails_history($sid, $details, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strType eq 'blast')
        {
            $iResult = $self->getDetails_blast($sid, $details, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid information type: '$strType'"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        if($iResult)
        {
            return $iResult;
        }
        $xmldata->addChild($details);
        return Constants::ERR_OK;
    }
    
    sub changePassword
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_ACCESS_DENIED;
        }
        if(!$refParams->{token})
        {
            $xmlerr->addChild($xmldoc->createTextNode("Token not specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!$refParams->{newpass})
        {
            $xmlerr->addChild($xmldoc->createTextNode("The new password cannot be empty"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        if(length($refParams->{newpass})<10)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The new password must be at least 10 characters long"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        my $strQuery = "SELECT IF(DATE_ADD(tokenexp, INTERVAL 15 SECOND)>CURRENT_TIMESTAMP AND ".
                                     "MD5(CONCAT(MD5('$refParams->{_remoteAddress}'), MD5('$refParams->{_userAgent}'), '$refParams->{token}'))=token,".
                                 "1,0) AS VALID, ".
                              "u_id AS u_id ".
                       "FROM UserSession WHERE sid='$sid'";
        my ($bIsValid, $u_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$bIsValid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("The token has expired"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        $strQuery = "UPDATE User SET pass=MD5('$refParams->{newpass}') WHERE pass=MD5('$refParams->{oldpass}') AND u_id=(SELECT u_id FROM UserSession WHERE sid='$sid');";
        my $statement = $self->{_db}->prepare($strQuery);
        if(!$statement->execute())
        {
            $xmlerr->addChild($xmldoc->createTextNode("The old password is incorrect"));
            return Constants::ERR_RUNTIME_ERROR;
        }
        # Terminate other sessions.
        $strQuery = "DELETE FROM UserSession WHERE u_id=$u_id AND NOT sid='$sid'";
        $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        return Constants::ERR_OK;
    }
    
    sub addToHistory
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_ACCESS_DENIED;
        }
        if(!$refParams->{type})
        {
            $xmlerr->addChild($xmldoc->createTextNode("The history item type is not specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $refParams->{type} = lc($refParams->{type});
        my @arrValidTypes = ('transcript', 'libseq', 'read', 'probe', 'gene');
        if(!(grep {$_ eq $refParams->{type}} @arrValidTypes))
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid history item type specified"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        if(!$refParams->{id})
        {
            $xmlerr->addChild($xmldoc->createTextNode("The history item ID is not specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        if(!($refParams->{id} =~ m/^[A-Za-z0-9_.]+$/))
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid history item ID specified"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        my $strQuery = "SELECT u_id FROM UserSession WHERE sid='$sid'";
        my ($u_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$u_id)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid session ID"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        my @arrItems = ();
        $strQuery = "SELECT value FROM UserData WHERE u_id=$u_id AND `key`='$KEY_USER_HISTORY'";
        my ($strValue) = $self->{_db}->selectrow_array($strQuery);
        if($strValue)
        {
            my $tmp = JSON::decode_json($strValue);
            foreach my $item (@{$tmp})
            {
                if(($item->{type} ne $refParams->{type}) || ($item->{id} ne $refParams->{id}))
                {
                    push(@arrItems, $item);
                }
            }
            if((scalar @arrItems)>=$MAX_HISTORY_LENGTH)
            {
                pop(@arrItems);
            }
        }
        my ($iSec,$iMin,$iHour,$iMDay,$iMon,$iYear,$iWDay,$iYDay,$isdst) = localtime(time);
        $iYear+=1900;
        unshift(@arrItems, {type => $refParams->{type},
                            id => $refParams->{id},
                            comment => $refParams->{comment},
                            length => int($refParams->{length}),
                            timestamp => sprintf("%d-%02d-%02d %02d:%02d:%02d", $iYear, $iMon+1, $iMDay, $iHour, $iMin, $iSec)});
        my $strBuffer = JSON::encode_json(\@arrItems);
        $strBuffer =~ s/'/\\'/g;
        $strQuery = "DELETE FROM UserData WHERE u_id=$u_id AND `key`='$KEY_USER_HISTORY'";
        my $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute();
        $strQuery = "INSERT INTO UserData (u_id, `key`, `value`) VALUES ($u_id, '$KEY_USER_HISTORY', '$strBuffer')";
        $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute();
        return Constants::ERR_OK;
    }
    
    sub addBlastQuery
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sid = $refParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Session ID is not specified. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_ACCESS_DENIED;
        }
        $refParams->{queryID} = int($refParams->{queryID});
        if(!$refParams->{queryID})
        {
            $xmlerr->addChild($xmldoc->createTextNode("The BLAST query ID is not specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my $strQuery = "SELECT u_id FROM UserSession WHERE sid='$sid'";
        my ($u_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$u_id)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid session ID"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        $strQuery = "SELECT value FROM UserData WHERE u_id=$u_id AND `key`='$KEY_USER_BLAST'";
        my ($strValue) = $self->{_db}->selectrow_array($strQuery);
        my @arrIDs = ();
        if($strValue)
        {
            foreach my $id (split(/;/, $strValue))
            {
                $id = int($id);
                if($id != $refParams->{queryID})
                {
                    push(@arrIDs, $id);
                }
            }
            if((scalar @arrIDs)>=$MAX_HISTORY_LENGTH)
            {
                pop(@arrIDs);
            }
        }
        unshift(@arrIDs, $refParams->{queryID});
        $strQuery = "DELETE FROM UserData WHERE u_id=$u_id AND `key`='$KEY_USER_BLAST'";
        my $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute();
        $strValue = join(';', @arrIDs);
        $strQuery = "INSERT INTO UserData (u_id, `key`, `value`) VALUES ($u_id, '$KEY_USER_BLAST', '$strValue')";
        $stmt = $self->{_db}->prepare($strQuery);
        $stmt->execute();
        return Constants::ERR_OK;
    }
    
    
    #################### PRIVATE METHODS ####################
    sub getDetails_general
    {
        my ($self, $sid, $details, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = "SELECT firstname, ".
                              "lastname, ".
                              "degree, ".
                              "email, ".
                              "institution, ".
                              "address, ".
                              "u_id ".
                       "FROM User ".
                       "WHERE u_id=(SELECT u_id FROM UserSession WHERE sid='$sid')";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid session ID. You must be signed-in in order to be able to call this method."));
            return Constants::ERR_ACCESS_DENIED;
        }
        my $user = $xmldoc->createElement('user');
        $user->addChild($xmldoc->createAttribute('firstname' => $refResult->{firstname}));
        $user->addChild($xmldoc->createAttribute('lastname' => $refResult->{lastname}));
        $user->addChild($xmldoc->createAttribute('degree' => $refResult->{degree}));
        $user->addChild($xmldoc->createAttribute('email' => $refResult->{email}));
        my $institution = $xmldoc->createElement('institution');
        $institution->addChild($xmldoc->createAttribute('name' => $refResult->{institution}));
        $institution->addChild($xmldoc->createAttribute('address' => $refResult->{address}));
        $user->addChild($institution);
        $details->addChild($user);
        return Constants::ERR_OK;
    }
    
    sub getDetails_bookmarks
    {
        my ($self, $sid, $details, $xmldoc, $xmldata, $xmlerr) = @_;
        my %hmSources = ('transcript' => {select_name => 'Contig.name AS name',
                                          select_details => 'an_id',
                                          join => 'INNER JOIN Contig ON Contig.c_id=UserBookmarks.seq_id'},
                         'libseq'     => {select_name => 'LibrarySequence.name AS name',
                                          select_details => 'LibrarySequence.ls_id AS ls_id',
                                          join => 'INNER JOIN LibrarySequence ON LibrarySequence.ls_id=UserBookmarks.seq_id'},
                         'probe'      => {select_name => 'MicroarrayProbe.name AS name',
                                          select_details => 'NULL',
                                          join => 'INNER JOIN MicroarrayProbe ON MicroarrayProbe.map_id=UserBookmarks.seq_id'},
                         'gene'       => {select_name => 'Gene.name AS name',
                                          select_details => 'an_id',
                                          join => 'INNER JOIN Gene ON Gene.g_id=UserBookmarks.seq_id'});
        foreach my $strClass (keys %hmSources)
        {
            my $queries = $hmSources{$strClass};
            my $bookmarks = $xmldoc->createElement('bookmarks');
            $bookmarks->addChild($xmldoc->createAttribute(type => $strClass));
            my $strQuery = "SELECT $queries->{select_name}, ".
                                  "$queries->{select_details}, ".
                                  "comment, ".
                                  "timestamp, ".
                                  "LENGTH(sequence) AS len ".
                           "FROM UserBookmarks ".
                                "$queries->{join} ".
                                "INNER JOIN SequenceType ON UserBookmarks.st_id=SequenceType.st_id ".
                           "WHERE u_id=(SELECT u_id FROM UserSession WHERE sid='$sid') ".
                                 "AND SequenceType.name='$strClass' ".
                           "ORDER BY timestamp DESC";       
            my $statement = $self->{_db}->prepare($strQuery);
            $statement->execute();
            next if($statement->rows==0);
            while(my $refResult = $statement->fetchrow_hashref())
            {
                my $bookmark = $xmldoc->createElement('bookmark');
                $bookmark->addChild($xmldoc->createAttribute('added' => $refResult->{timestamp}));
                $bookmark->addChild($xmldoc->createAttribute('id' => $refResult->{name}));
                $bookmark->addChild($xmldoc->createAttribute('length' => $refResult->{len}));
                $bookmark->addChild($xmldoc->createAttribute('comment' => $refResult->{comment}));
                if((($strClass eq 'transcript') || ($strClass eq 'gene')) && $refResult->{an_id})
                {
                    $strQuery = "SELECT symbol, definition FROM Annotation WHERE an_id=$refResult->{an_id};";
                    $refResult = $self->{_db}->selectrow_hashref($strQuery);
                    if($refResult)
                    {
                        $bookmark->addChild($xmldoc->createAttribute('symbol' => $refResult->{symbol}));
                        $bookmark->addChild($xmldoc->createAttribute('annotation' => $refResult->{definition}));
                    }
                }
                elsif($strClass eq 'libseq')
                {
                    $strQuery = "SELECT symbol, description, remarks FROM LibraryAnnotation WHERE ls_id=$refResult->{ls_id};";
                    $refResult = $self->{_db}->selectrow_hashref($strQuery);
                    if($refResult)
                    {
                        $bookmark->addChild($xmldoc->createAttribute('symbol' => $refResult->{symbol}));
                        $bookmark->addChild($xmldoc->createAttribute('annotation' => $refResult->{description}));
                        $bookmark->addChild($xmldoc->createAttribute('remarks' => $refResult->{remarks}));
                    }
                }
                $bookmarks->addChild($bookmark);
            }
            $details->addChild($bookmarks);
        }
        return Constants::ERR_OK;
    }
    
    sub getDetails_sessions
    {
        my ($self, $sid, $details, $xmldoc, $xmldata, $xmlerr) = @_;
        my $sessions = $xmldoc->createElement('sessions');
        my $strQuery = "SELECT signed AS created, ".
                              "DATE_SUB(expires, INTERVAL 7 DAY) AS active, ".
                              "ip, ".
                              "agent, ".
                              "IF(sid='$sid',1,0) AS current ".
                       "FROM UserSession ".
                       "WHERE u_id=(SELECT u_id FROM UserSession WHERE sid='$sid');";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $session = $xmldoc->createElement('session');
            $session->addChild($xmldoc->createAttribute('created' => $refResult->{created}));
            $session->addChild($xmldoc->createAttribute('active' => $refResult->{active}));
            $session->addChild($xmldoc->createAttribute('ip' => $refResult->{ip}));
            $session->addChild($xmldoc->createAttribute('country' => (IP::Country::Fast->new())->inet_atocc($refResult->{ip})));
            $session->addChild($xmldoc->createAttribute('current' => 'true')) if $refResult->{current};
            $session->addChild($xmldoc->createTextNode($refResult->{agent}));
            $sessions->addChild($session);
        }
        $details->addChild($sessions);
        return Constants::ERR_OK;
    }
    
    sub getDetails_history
    {
        my ($self, $sid, $details, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = "SELECT u_id FROM UserSession WHERE sid='$sid'";
        my ($u_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$u_id)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid session ID"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        $strQuery = "SELECT value FROM UserData WHERE u_id=$u_id AND `key`='$KEY_USER_HISTORY'";
        my ($strValue) = $self->{_db}->selectrow_array($strQuery);
        if($strValue)
        {
            my $history = $xmldoc->createElement('history');
            my $tmp = JSON::decode_json($strValue);
            foreach my $item (@{$tmp})
            {
                my $entry = $xmldoc->createElement('entry');
                $entry->addChild($xmldoc->createAttribute('type' => $item->{type}));
                $entry->addChild($xmldoc->createAttribute('id' => $item->{id}));
                $entry->addChild($xmldoc->createAttribute('visited' => $item->{timestamp}));
                $entry->addChild($xmldoc->createAttribute('length' => $item->{length})) if($item->{length});
                $entry->addChild($xmldoc->createTextNode($item->{comment}));
                $history->addChild($entry);
            }
            $details->addChild($history);
        }
        return Constants::ERR_OK;
    }
    
    sub getDetails_blast
    {
        my ($self, $sid, $details, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = "SELECT u_id FROM UserSession WHERE sid='$sid'";
        my ($u_id) = $self->{_db}->selectrow_array($strQuery);
        if(!$u_id)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid session ID"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        $strQuery = "SELECT value FROM UserData WHERE u_id=$u_id AND `key`='$KEY_USER_BLAST'";
        my ($strValue) = $self->{_db}->selectrow_array($strQuery);
        my @arrValidIDs = ();
        if($strValue)
        {
            $strQuery = "SELECT submitted, alg_name AS algorithm, dbname, BlastStatus.name AS status ".
                        "FROM BlastResult ".
                             "INNER JOIN BlastStatus ON BlastResult.bs_id=BlastStatus.bs_id ".
                        "WHERE bj_id=? AND NOT BlastStatus.name='error'";
            my $stmtFindFinished = $self->{_db}->prepare($strQuery);
            $strQuery = "SELECT submitted, Algorithm.name AS algorithm, db AS dbname, BlastStatus.name AS status ".
                        "FROM BlastJob ".
                             "INNER JOIN Algorithm ON BlastJob.al_id=Algorithm.al_id ".
                             "INNER JOIN BlastStatus ON BlastJob.bs_id=BlastStatus.bs_id ".
                        "WHERE bj_id=?";
            my $stmtFindSubmitted = $self->{_db}->prepare($strQuery);
            my $blast = $xmldoc->createElement('blast');
            foreach my $id (split(/;/, $strValue))
            {
                $stmtFindFinished->execute($id);
                my ($refResult) = $stmtFindFinished->fetchrow_hashref();
                if(!$refResult)
                {
                    $stmtFindSubmitted->execute($id);
                    ($refResult) = $stmtFindSubmitted->fetchrow_hashref();
                    next unless($refResult);
                }
                push(@arrValidIDs, $id);
                my $query = $xmldoc->createElement('query');
                $query->addChild($xmldoc->createAttribute('id' => $id));
                foreach my $strProp (keys %{$refResult})
                {
                    $query->addChild($xmldoc->createAttribute($strProp => $refResult->{$strProp}));
                }
                $blast->addChild($query);
            }
            $details->addChild($blast);
            $strQuery = "UPDATE UserData SET value=? WHERE u_id=$u_id AND `key`='$KEY_USER_BLAST'";
            my $stmtUpdate = $self->{_db}->prepare($strQuery);
            $stmtUpdate->execute(join(";", @arrValidIDs));
        }
        return Constants::ERR_OK;
    }
}

1;
