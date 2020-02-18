#!/usr/bin/env perl

#   File:
#       Service.pm
#
#   Description:
#       Contains the Administrator module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.10
#
#   Date:
#       23.05.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;

use Axolotl::ATAPI::Constants;


package Administrator;
{
    my $MODULE = 'Administrator';
    
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
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Encapsulates several methods required for website management";
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
        # If the user details are provided, use them. Otherwise, use the sid parameter to identify the user.
        my $sid = $refMethodParams->{_user}->{sid};
        if(!$sid)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Access denied! You must be signed in in order to use this module"));
            return Constants::ERR_ACCESS_DENIED;
        }
        my $privilege = $refMethodParams->{_user}->{privilege};
        if(!($privilege & Constants::UP_ADMINISTRATOR))
        {
            $xmlerr->addChild($xmldoc->createTextNode("Access denied! You cannot use this module"));
            return Constants::ERR_ACCESS_DENIED;
        }
        # Execute the method.
        if($strMethod eq 'getMessageCount')
        {
            return $self->getMessageCount($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getMessages')
        {
            return $self->getMessages($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getSystemInfo')
        {
            return $self->getSystemInfo($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'addNews')
        {
            return $self->addNews($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        elsif($strMethod eq 'getUsersList')
        {
            return $self->getUsersList($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub getMessageCount
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrMsgTypes = (undef, 'message', 'feedback', 'report');
        my @arrMsgDescr = (undef, 'General messages', 'Feedback messages', 'Bug reports');
        my $strQuery = "SELECT type, COUNT(type) AS count FROM Message GROUP BY type;";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $group = $xmldoc->createElement('message');
            $group->addChild($xmldoc->createAttribute('type' => $arrMsgTypes[$refResult->{type}]));
            $group->addChild($xmldoc->createAttribute('description' => $arrMsgDescr[$refResult->{type}]));
            $group->addChild($xmldoc->createAttribute('count' => $refResult->{count}));
            $xmldata->addChild($group);
        }
        return Constants::ERR_OK;
    }
    
    sub getMessages
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strType = lc($refParams->{type});
        if(!$strType)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Message type not specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        my %hmTypes = ('message' =>  {_value => Constants::MT_CONTACT},
                       'feedback' => {_value => Constants::MT_FEEDBACK},
                       'report' =>   {_value => Constants::MT_BUGREPORT});
        my $iType = $hmTypes{$strType}->{_value};
        if(!$iType)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Unknown message type: '$strType'"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        my $messages = $xmldoc->createElement('messages');
        $messages->addChild($xmldoc->createAttribute('type' => $strType));
        my $strQuery = "SELECT name, email, message, timestamp FROM Message WHERE type=$iType ORDER BY timestamp DESC;";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        while(my $refResult = $statement->fetchrow_hashref())
        {
            $refResult->{message} =~ s/\\\'/'/g;
            my $msg = $xmldoc->createElement('message');
            $msg->addChild($xmldoc->createAttribute('author' => $refResult->{name}));
            $msg->addChild($xmldoc->createAttribute('email' => $refResult->{email}));
            $msg->addChild($xmldoc->createAttribute('timestamp' => $refResult->{timestamp}));
            $msg->addChild($xmldoc->createTextNode($refResult->{message}));
            $messages->addChild($msg);
        }
        $xmldata->addChild($messages);
        return Constants::ERR_OK;
    }
    
    sub getSystemInfo
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my @arrValues = ($refParams->{values}) ? split(/,/, $refParams->{values}) : ('general');
        my %hmValues = map { $_ => 1 } @arrValues;
        if($hmValues{top})
        {
            my $processes = $xmldoc->createElement('processes');
            my $strCMD = 'ps ch -eo pcpu,pmem,cmd | sort -k 1 -nr | head';
            open(OUT, "$strCMD |");
            while(<OUT>)
            {
                chomp();
                $_ =~ s/^\s+//;
                $_ =~ s/\s+$//;
                my @arrChunks = split(/\s+/, $_);
                my $process = $xmldoc->createElement('process');
                $process->addChild($xmldoc->createAttribute(name => $arrChunks[2]));
                $process->addChild($xmldoc->createAttribute(cpu => $arrChunks[0]));
                $process->addChild($xmldoc->createAttribute(memory => $arrChunks[1]));
                $processes->addChild($process);
            }
            close(OUT);
            $xmldata->addChild($processes);
        }
        if($hmValues{memory})
        {
            my $memory = $xmldoc->createElement('memory');
            my $strCMD = 'free';
            open(OUT, "$strCMD |");
            while(<OUT>)
            {
                chomp();
                my @arrChunks = split(/\s+/, $_);
                my $item = undef;
                if($arrChunks[0] =~ m/Mem:/)
                {
                    $item = $xmldoc->createElement('item');
                    $item->addChild($xmldoc->createAttribute(type => 'physical'));
                }
                elsif($arrChunks[0] =~ m/Swap:/)
                {
                    $item = $xmldoc->createElement('item');
                    $item->addChild($xmldoc->createAttribute(type => 'swap'));
                }
                if($item)
                {
                    $item->addChild($xmldoc->createAttribute(total => $arrChunks[1]));
                    $item->addChild($xmldoc->createAttribute(used => $arrChunks[2]));
                    $item->addChild($xmldoc->createAttribute(free => $arrChunks[3]));
                    $memory->addChild($item);
                }
            }
            close(OUT);
            $xmldata->addChild($memory);
        }
        if($hmValues{general})
        {
            # System
            my $strCMD = 'uname -mrsn';
            open(OUT, "$strCMD |");
            my $strOutput = <OUT>;
            chomp($strOutput);
            close(OUT);
            my @arrChunks = split(/ /, $strOutput);
            my $bIs64bit = ($strOutput =~ m/x86_64/);
            my $system = $xmldoc->createElement('system');
            $system->addChild($xmldoc->createAttribute(architecture => ($bIs64bit ? 'x64' : 'x32')));
            $system->addChild($xmldoc->createAttribute(OS => $arrChunks[0]));
            $system->addChild($xmldoc->createAttribute(kernel => $arrChunks[2]));
            $system->addChild($xmldoc->createAttribute(name => $arrChunks[1]));
            $xmldata->addChild($system);
            
            # CPUs
            my $processors = $xmldoc->createElement('processors');
            $xmldata->addChild($processors);
            my $cpu = undef;
            $strCMD = 'cat /proc/cpuinfo';
            open(OUT, "$strCMD |");
            while(<OUT>)
            {
                chomp();
                $_ =~ s/^\s+//;
                $_ =~ s/\s+$//;
                if($_ =~ m/^processor/)
                {
                    $cpu = $xmldoc->createElement('cpu');
                    $processors->addChild($cpu);
                }
                elsif($_ =~ m/^vendor_id\s+:\s*(.+)\s*$/)
                {
                    $cpu->addChild($xmldoc->createAttribute(vendor => $1));
                }
                elsif($_ =~ m/^model name\s+:\s*(.+)\s*$/)
                {
                    $cpu->addChild($xmldoc->createAttribute(model => $1));
                }
                elsif($_ =~ m/^cpu MHz\s+:\s*(.+)\s*$/)
                {
                    $cpu->addChild($xmldoc->createAttribute(frequency => $1));
                }
            }
            close(OUT);
            $xmldata->addChild($processors);
            
            # Disk
            my $disk = $xmldoc->createElement('disk');
            $strCMD = 'df';
            open(OUT, "$strCMD |");
            while(<OUT>)
            {
                chomp();
                my @arrChunks = split(/\s+/, $_);
                my $partition = undef;
                if($arrChunks[5] eq '/')
                {
                    $partition = $xmldoc->createElement('partition');
                    $partition->addChild($xmldoc->createAttribute(name => 'system'));
                }
                elsif($arrChunks[5] eq '/home/website/data')
                {
                    $partition = $xmldoc->createElement('partition');
                    $partition->addChild($xmldoc->createAttribute(name => 'data'));
                }
                if($partition)
                {
                    $partition->addChild($xmldoc->createAttribute(total => $arrChunks[1]));
                    $partition->addChild($xmldoc->createAttribute(used => $arrChunks[2]));
                    $partition->addChild($xmldoc->createAttribute(free => $arrChunks[3]));
                    $disk->addChild($partition);
                }
            }
            close(OUT);
            $xmldata->addChild($disk);
        }
        return Constants::ERR_OK;
    }
    
    sub addNews
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strTitle = $refParams->{title};
        # Get the user first and last names based on SID.
        my $strQuery = "SELECT u_id FROM UserSession WHERE sid='$refParams->{_user}->{sid}';";
        my $refResult = $self->{_db}->selectrow_hashref($strQuery);
        if(!$refResult)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Access denied! You must be signed in in order to call this method."));
            return Constants::ERR_ACCESS_DENIED;
        }
        if(!$strTitle)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No news title specified"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
        $strTitle =~ s/'/\\'/g;
        my $strText = $refParams->{text};
        if(!$strText)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No news text specified"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
        $strText =~ s/'/\\'/g;
        $strQuery = "INSERT INTO News (title, text, u_id) VALUES ('$strTitle', '$strText', $refResult->{u_id});";
        my $statement = $self->{_db}->prepare($strQuery);
        if($statement->execute())
        {
            my $response = $xmldoc->createElement('response');
            $response->addChild($xmldoc->createTextNode('The news has been added!'));
            $xmldata->addChild($response);
            return Constants::ERR_OK;
        }
        {
            $xmlerr->addChild($xmldoc->createTextNode("Failed to add the news due to the following error: " . $statement->errstr));
            return Constants::ERR_RUNTIME_ERROR;
        }
    }
    
    sub getUsersList
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my $strQuery = "SELECT User.u_id, ".
                              "email, ".
                              "firstname, ".
                              "lastname, ".
                              "privilege, ".
                              "degree, ".
                              "institution, ".
                              "address, ".
                              "created, ".
                              "MAX(DATE_SUB(expires, INTERVAL 7 DAY)) AS lastVisit, ".
                              "IF(MAX(expires)>NOW(),1,0) AS active ".
                         "FROM User ".
                              "LEFT JOIN UserSession ON User.u_id=UserSession.u_id ".
                         "GROUP BY User.u_id";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute();
        my $users = $xmldoc->createElement('users');
        while(my $refResult = $statement->fetchrow_hashref())
        {
            my $user = $xmldoc->createElement('user');
            $user->addChild($xmldoc->createAttribute('id' => $refResult->{u_id}));
            $user->addChild($xmldoc->createAttribute('email' => $refResult->{email}));
            $user->addChild($xmldoc->createAttribute('firstname' => $refResult->{firstname}));
            $user->addChild($xmldoc->createAttribute('lastname' => $refResult->{lastname}));
            $user->addChild($xmldoc->createAttribute('degree' => $refResult->{degree}));
            $user->addChild($xmldoc->createAttribute('privilege' => $refResult->{privilege}));
            $user->addChild($xmldoc->createAttribute('created' => $refResult->{created}));
            # Access
            my $access = $xmldoc->createElement('access');
            $access->addChild($xmldoc->createAttribute(created => $refResult->{created}));
            $access->addChild($xmldoc->createAttribute(lastVisit => $refResult->{lastVisit}));
            $access->addChild($xmldoc->createAttribute(active => ($refResult->{active}) ? 'true' : 'false'));
            $access->addChild($xmldoc->createAttribute(privilege => $refResult->{privilege}));
            $user->addChild($access);
            # Affiliation
            my $affiliation = $xmldoc->createElement('affiliation');
            $affiliation->addChild($xmldoc->createAttribute('institution' => $refResult->{institution}));
            $affiliation->addChild($xmldoc->createTextNode($refResult->{address}));
            $user->addChild($affiliation);
            $users->addChild($user);
        }
        $xmldata->addChild($users);
        return Constants::ERR_OK;
    }
}

1;
    
